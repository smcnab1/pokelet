#!/usr/bin/env python3
"""Stage a signed Sparkle update from an approved Pokelet.app. No network or publishing."""

import argparse
import base64
from datetime import date
from email.utils import parsedate_to_datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BUNDLE_ID = "uk.co.sammcnab.Pokelet"
FEED = "https://smcnab1.github.io/pokelet/updates/"
RELEASES = "https://github.com/smcnab1/pokelet/releases/download/"
SPARKLE = "{http://www.andymatuschak.org/xml-namespaces/sparkle}"


def run(*args):
    return subprocess.check_output(args, text=True).strip()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def plist(path):
    return plistlib.loads(path.read_bytes())


def architectures(binary):
    return set(run("xcrun", "lipo", "-archs", binary).split())


def verify_app(app, tag, feed_url, channel, bin_dir, key_args):
    version_pattern = r"v([0-9]+\.[0-9]+\.[0-9]+)"
    if channel == "beta":
        version_pattern += r"-beta\.[1-9][0-9]*"
    version = re.fullmatch(version_pattern, tag)
    require(version, f"Expected an exact {channel} release tag.")
    metadata = plist(app / "Contents/Info.plist")
    require(metadata.get("CFBundleIdentifier") == BUNDLE_ID, "Unexpected app bundle identifier.")
    require(metadata.get("CFBundleShortVersionString") == version[1], "Bundle version does not match the tag.")
    build = metadata.get("CFBundleVersion", "")
    require(re.fullmatch(r"[1-9][0-9]*", build), "A positive, monotonically increasing build is required.")
    require(metadata.get("LSMinimumSystemVersion") == "14.0", "Unexpected minimum macOS version.")
    require(metadata.get("SUFeedURL") == feed_url + "appcast.xml", f"The app must use the {channel} HTTPS feed.")
    require(metadata.get("SUVerifyUpdateBeforeExtraction") is True
            and metadata.get("SURequireSignedFeed") is True
            and type(metadata.get("SUSignedFeedFailureExpirationInterval")) is int
            and metadata["SUSignedFeedFailureExpirationInterval"] == 0,
            "The app must require verified archives and signed feeds without a signature fallback.")
    require(metadata.get("SUAllowsAutomaticUpdates") is False
            and metadata.get("SUEnableSystemProfiling") is False
            and metadata.get("SUEnableAutomaticChecks") is False,
            "Unexpected background update defaults.")
    require(metadata.get("SUPublicEDKey") == run(bin_dir / "generate_keys", *key_args, "-p"),
            "The keychain signing key does not match the app’s public key.")

    verify_signing(app)
    require("Sparkle.framework" in run("otool", "-L", app / "Contents/MacOS/Pokelet"),
            "This app was built without the updater.")

    # Use the same structural check as the normal candidate packaging path.
    run(ROOT / "script/test_native.sh", app)
    require(architectures(app / "Contents/MacOS/Pokelet") == {"arm64", "x86_64"}, "The app must be universal.")
    return version[1], build


def verify_signing(app):
    modes = set()
    for arch in ("arm64", "x86_64"):
        result = subprocess.run(
            ["/usr/bin/codesign", "--display", "--verbose=4", "--arch", arch, "--entitlements", "-", "--xml", app],
            capture_output=True, check=True)
        signing = result.stderr.decode()
        entitlements = plistlib.loads(result.stdout) if result.stdout else {}
        require(re.search(r"^CodeDirectory .*flags=.*[(,]runtime[,)]", signing, re.MULTILINE),
                f"The update app must use Hardened Runtime on {arch}.")
        require(not entitlements.get("com.apple.security.get-task-allow"), "Release must not be debuggable.")
        exception = entitlements.get("com.apple.security.cs.disable-library-validation")
        if "Signature=adhoc" in signing:
            modes.add("ad hoc")
            require(exception is True and len(entitlements) == 1,
                    f"Expected only the ad hoc updater entitlement on {arch}.")
        else:
            modes.add("Developer ID")
            team = re.search(r"^TeamIdentifier=([A-Z0-9]+)$", signing, re.MULTILINE)
            require(team and "Authority=Developer ID Application:" in signing and not exception,
                    f"Expected Developer ID and library validation on {arch}.")
            framework = app / "Contents/Frameworks/Sparkle.framework"
            framework_signing = subprocess.check_output(
                ["/usr/bin/codesign", "--display", "--verbose=4", "--arch", arch, framework],
                stderr=subprocess.STDOUT, text=True)
            require(f"TeamIdentifier={team[1]}\n" in framework_signing, "App and Sparkle signing teams must match.")
    require(len(modes) == 1, "Both architectures must use the same signing mode.")
    if "Developer ID" in modes:
        run("xcrun", "stapler", "validate", app)


def verify_appcast(stage, archive, notes, tag, version, build, publication_date, update_channel, feed_url,
                   bin_dir, key_args):
    feed = stage / "appcast.xml"
    run(bin_dir / "sign_update", *key_args, "--verify", feed)
    channel = ET.parse(feed).find("channel")
    require(channel is not None and channel.findtext(SPARKLE + "bundleIdentifier") == BUNDLE_ID,
            "Generated feed has the wrong bundle identifier.")
    items = channel.findall("item")
    require(len(items) == 1, "Expected one current release.")
    item = items[0]
    expected_channel = "beta" if update_channel == "beta" else None
    require(item.findtext(SPARKLE + "channel") == expected_channel, "Generated feed has the wrong update channel.")
    require(item.findtext(SPARKLE + "version") == build
            and item.findtext(SPARKLE + "shortVersionString") == version
            and item.findtext(SPARKLE + "minimumSystemVersion") == "14.0",
            "Generated feed has unexpected version or platform metadata.")
    require(parsedate_to_datetime(item.findtext("pubDate", "")).date() == publication_date,
            "Generated feed date differs from the changelog.")
    enclosure = item.find("enclosure")
    release_notes = item.find(SPARKLE + "releaseNotesLink")
    require(enclosure is not None and enclosure.get("url") == RELEASES + tag + "/" + archive.name,
            "Unexpected download URL.")
    require(release_notes is not None and (release_notes.text or "").strip() == feed_url + notes.name,
            "Unexpected release notes URL.")

    for file, element, length_key in ((archive, enclosure, "length"),
                                      (notes, release_notes, SPARKLE + "length")):
        signature = element.get(SPARKLE + "edSignature", "")
        require(len(base64.b64decode(signature, validate=True)) == 64, f"Invalid signature for {file.name}.")
        require(element.get(length_key) == str(file.stat().st_size), f"Incorrect signed length for {file.name}.")
        run(bin_dir / "sign_update", *key_args, "--verify", file, signature)


def prepare(args):
    app = args.app.resolve(strict=True)
    output = args.output.absolute()
    require(not output.exists() and not output.is_symlink(), "Choose a new output directory.")
    bin_dir = args.sparkle_tools.resolve(strict=True)
    require(args.keychain_account == f"pokelet-{args.channel}", "Use the dedicated Keychain account for this channel.")
    require(os.environ.get("POKELET_SPARKLE_BACKUP_CONFIRMED") == args.keychain_account,
            "Confirm the secure offline backup before staging signed release files.")
    feed_url = FEED + ("beta/" if args.channel == "beta" else "")
    key_args = ("--account", args.keychain_account)
    changelog = ROOT / "CHANGELOG.md"

    with tempfile.TemporaryDirectory(prefix="pokelet-sparkle-release-") as work:
        stage = Path(work) / "release"
        stage.mkdir()
        # Snapshot the approved bundle before validating and archiving the same bytes.
        candidate = Path(work) / "Pokelet.app"
        run("/usr/bin/ditto", app, candidate)
        version, build = verify_app(candidate, args.tag, feed_url, args.channel, bin_dir, key_args)
        require(changelog.read_bytes() == (candidate / "Contents/Resources/CHANGELOG.md").read_bytes(),
                "The bundled changelog differs from the release source.")

        exporter = Path(work) / "export_release_notes"
        run("xcrun", "swiftc", "-warnings-as-errors", ROOT / "Pokelet/Models/ReleaseNotes.swift",
            ROOT / "script/export_release_notes.swift", "-o", exporter)
        basename = f"Pokelet-{args.tag[1:]}-build-{build}"
        archive = stage / (basename + ".zip")
        notes = stage / (basename + ".md")
        release = json.loads(run(exporter, changelog, args.tag, build))
        publication_date = date.fromisoformat(release["date"])
        notes.write_text(release["markdown"], encoding="utf-8")
        run("/usr/bin/ditto", "-c", "-k", "--sequesterRsrc", "--keepParent", candidate, archive)
        run("/usr/bin/unzip", "-tq", archive)
        # generate_appcast uses the archive creation date for pubDate.
        run("env", "TZ=UTC", "xcrun", "SetFile", "-d", publication_date.strftime("%m/%d/%Y 00:00:00"), archive)

        # Seed the channel metadata. Sparkle generates the item and signs the resulting XML.
        (stage / "appcast.xml").write_text(
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">'
            f'<channel><title>Pokelet</title><link>{feed_url}appcast.xml</link>'
            f'<sparkle:bundleIdentifier>{BUNDLE_ID}</sparkle:bundleIdentifier></channel></rss>\n',
            encoding="utf-8")
        channel_args = ("--channel", "beta") if args.channel == "beta" else ()
        run("env", "TZ=UTC", bin_dir / "generate_appcast", *key_args, *channel_args, "--maximum-deltas", "0",
            "--download-url-prefix", RELEASES + args.tag + "/", "--release-notes-url-prefix", feed_url, stage)
        verify_appcast(stage, archive, notes, args.tag, version, build, publication_date, args.channel, feed_url,
                       bin_dir, key_args)
        files = (archive, notes, stage / "appcast.xml")
        manifest = stage / "SHA256SUMS"
        manifest.write_text("".join(f"{hashlib.sha256(file.read_bytes()).hexdigest()}  {file.name}\n" for file in files))

        output.mkdir()
        for file in (*files, manifest):
            shutil.copyfile(file, output / file.name)
    print(f"Verified {args.channel} release files staged locally in {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path, help="approved universal Pokelet.app")
    parser.add_argument("--tag", required=True, help="proposed release tag")
    parser.add_argument("--channel", choices=("stable", "beta"), default="stable")
    parser.add_argument("--sparkle-tools", required=True, type=Path, help="bin directory from the pinned Sparkle release")
    parser.add_argument("--keychain-account", required=True, help="owner-approved Sparkle keychain account")
    parser.add_argument("--output", required=True, type=Path, help="new directory for verified publication inputs")
    try:
        prepare(parser.parse_args())
    except (OSError, ValueError, ET.ParseError, subprocess.CalledProcessError) as error:
        if isinstance(error, subprocess.CalledProcessError) and error.output:
            print(error.output, file=sys.stderr)
        sys.exit(f"Sparkle staging failed: {error}")


if __name__ == "__main__":
    main()
