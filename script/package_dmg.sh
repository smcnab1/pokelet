#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"
APP=""
APP_SUPPLIED=false
IDENTITY="${POKELET_DEVELOPER_ID:-}"
PROFILE="${POKELET_NOTARY_PROFILE:-}"

check_developer_id() {
  if [[ -n "$IDENTITY" && ! "$IDENTITY" =~ ^[[:xdigit:]]{40}$ ]]; then
    printf 'POKELET_DEVELOPER_ID must be the local certificate fingerprint.\n' >&2
    return 2
  fi
  if ! /usr/bin/security find-identity -v -p codesigning | /usr/bin/awk -v id="$IDENTITY" '
    /^ *[0-9]+\)/ && /"Developer ID Application: / && (id == "" || toupper($2) == toupper(id)) { found = 1 }
    END { exit !found }
  '; then
    printf 'A valid Developer ID Application identity with its private key is required.\n' >&2
    return 2
  fi
}

case "$MODE" in
  --check-signing)
    [[ $# -eq 1 ]] || exit 2
    check_developer_id
    xcrun notarytool --version
    printf 'Local Developer ID Application identity and notarytool are available.\n'
    exit
    ;;
  --check-layout)
    [[ $# -eq 2 ]] || exit 2
    APP="$(cd "$2" && pwd -P)"
    ;;
  --beta|--notarise)
    if [[ "$MODE" == --beta ]]; then
      [[ $# -le 3 ]] || exit 2
      OUT="${2:-$ROOT/dist/beta}"
      if [[ $# -eq 3 ]]; then
        APP="$(cd "$3" && pwd -P)"
      fi
    else
      [[ $# -le 3 ]] || exit 2
      OUT="${2:-$ROOT/dist/notarised}"
      if [[ $# -eq 3 ]]; then
        APP="$(cd "$3" && pwd -P)"
        APP_SUPPLIED=true
      fi
    fi
    if [[ -e "$OUT" || -L "$OUT" ]]; then
      printf 'Choose a new output directory. Existing output was preserved.\n' >&2
      exit 2
    fi
    if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
      printf 'Commit all source changes before packaging a release.\n' >&2
      exit 2
    fi
    mkdir -p "$(dirname "$OUT")"
    ;;
  *)
    printf 'Usage: %s --check-signing | --check-layout path/to/Pokelet.app | --beta [output-directory [path/to/Pokelet.app]] | --notarise [output-directory [path/to/stapled/Pokelet.app]]\n' "$0" >&2
    exit 2
    ;;
esac

if [[ "$MODE" == --notarise ]]; then
  if [[ -z "$IDENTITY" || -z "$PROFILE" ]]; then
    printf 'Set POKELET_DEVELOPER_ID to the local certificate fingerprint and POKELET_NOTARY_PROFILE to a Keychain profile.\n' >&2
    exit 2
  fi
  check_developer_id
  xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null
fi

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-dmg.XXXXXX")"
MOUNT="$STAGE/mounted"
attached=false
retain_stage=false
cleanup() {
  if [[ "$attached" == true ]] && ! /usr/bin/hdiutil detach "$MOUNT" -quiet; then
    printf 'Disk image is still mounted at %s. Staging was retained.\n' "$MOUNT" >&2
    return
  fi
  if [[ "$retain_stage" == true ]]; then
    printf 'Notarisation staging retained at %s with the submission output and DMG. Check the existing submission before retrying.\n' "$STAGE" >&2
    return
  fi
  rm -rf "$STAGE"
}
trap cleanup EXIT

if [[ -z "$APP" ]]; then
  if [[ "$MODE" == --notarise ]]; then
    "$ROOT/script/package_release.sh" --developer-id "$STAGE/candidate"
  else
    "$ROOT/script/package_release.sh" "$STAGE/candidate"
  fi
  APP="$STAGE/candidate/Pokelet.app"
fi

if [[ "$MODE" == --notarise ]]; then
  if [[ "$APP_SUPPLIED" == true ]]; then
    xcrun stapler validate "$APP"
  fi
  /usr/bin/codesign --verify --deep --strict -R "=certificate leaf = H\"$IDENTITY\"" "$APP"
  for arch in arm64 x86_64; do
    /usr/bin/codesign --display --arch "$arch" --verbose=4 "$APP" 2>&1 | /usr/bin/awk '
      /^Authority=Developer ID Application: / { developer = 1 }
      /^Timestamp=/ { timestamp = 1 }
      /^CodeDirectory .*flags=.*\(runtime\)/ { runtime = 1 }
      END { exit !(developer && timestamp && runtime) }
    ' || { printf 'Release signature on %s requires Developer ID, a secure timestamp and hardened runtime.\n' "$arch" >&2; exit 1; }
  done
fi

if [[ "$MODE" == --beta ]]; then
  if [[ "$(/usr/bin/plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")" != uk.co.sammcnab.Pokelet ]]; then
    printf 'The beta DMG requires the Pokelet release bundle identifier.\n' >&2
    exit 1
  fi
  ARCHITECTURES="$(xcrun lipo -archs "$APP/Contents/MacOS/Pokelet" | tr ' ' '\n' | sort)"
  if [[ "$ARCHITECTURES" != $'arm64\nx86_64' ]]; then
    printf 'The beta DMG requires a universal arm64 and x86_64 app.\n' >&2
    exit 1
  fi
  for arch in arm64 x86_64; do
    /usr/bin/codesign --display --arch "$arch" --verbose=4 "$APP" 2>&1 | /usr/bin/awk '
      $0 == "Signature=adhoc" { adhoc = 1 }
      END { exit !adhoc }
    '
  done
fi

# Clone the Finder-authored filesystem so the background bookmark and volume icon
# stay attached to the original volume and file. Packaging needs no Finder session.
mkdir "$MOUNT"
WRITABLE="$STAGE/writable.dmg"
/usr/bin/hdiutil convert -quiet -format UDRW -o "$WRITABLE" "$ROOT/packaging/dmg/InstallerTemplate.dmg"
/usr/bin/hdiutil attach -quiet -nobrowse -noautoopen -mountpoint "$MOUNT" "$WRITABLE"
attached=true
# The empty folder supplies Finder's icon position. Replace it so its metadata
# cannot carry over into the signed bundle.
rmdir "$MOUNT/Pokelet.app"
/usr/bin/ditto "$APP" "$MOUNT/Pokelet.app"
rm -rf "$MOUNT/.fseventsd"
/usr/bin/hdiutil detach -quiet "$MOUNT"
attached=false

VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
SUFFIX=""
if [[ "$MODE" == --beta ]]; then SUFFIX="-unnotarised"; fi
DMG="$STAGE/Pokelet-$VERSION$SUFFIX.dmg"
/usr/bin/hdiutil convert -quiet -format UDZO -o "$DMG" "$WRITABLE"

if [[ "$MODE" == --notarise ]]; then
  BUNDLE_ID="$(/usr/bin/plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")"
  /usr/bin/codesign --timestamp --sign "$IDENTITY" --identifier "$BUNDLE_ID.dmg" "$DMG"
  /usr/bin/codesign --verify --strict "$DMG"
  retain_stage=true
  if ! xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" \
      --output-format plist > "$STAGE/submission.plist" 2> "$STAGE/notary.stderr"; then
    cat "$STAGE/submission.plist" >&2
    cat "$STAGE/notary.stderr" >&2
    exit 1
  fi
  SUBMISSION="$(/usr/bin/plutil -extract id raw "$STAGE/submission.plist")"
  printf 'Apple notarisation submission %s\n' "$SUBMISSION"
  if ! xcrun notarytool wait "$SUBMISSION" --keychain-profile "$PROFILE" --timeout 30m \
      --output-format plist > "$STAGE/notary.plist" 2> "$STAGE/notary.stderr"; then
    cat "$STAGE/notary.plist" "$STAGE/notary.stderr" >&2
    exit 1
  fi
  if [[ "$(/usr/bin/plutil -extract status raw "$STAGE/notary.plist")" != Accepted ]]; then
    /usr/bin/plutil -p "$STAGE/notary.plist" >&2
    exit 1
  fi
  printf 'Apple notarisation accepted, submission %s\n' "$SUBMISSION"
  xcrun notarytool log "$SUBMISSION" --keychain-profile "$PROFILE" "$STAGE/notary-log.json"
  xcrun stapler staple "$DMG"
  xcrun stapler validate "$DMG"
  /usr/bin/codesign --verify --strict "$DMG"
  /usr/sbin/spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
fi

/usr/bin/hdiutil verify -quiet "$DMG"
/usr/bin/hdiutil attach -quiet -readonly -nobrowse -noautoopen -mountpoint "$MOUNT" "$DMG"
attached=true
test "$(readlink "$MOUNT/Applications")" = /Applications
test -d "$MOUNT/Applications"
test -s "$MOUNT/.DS_Store"
test -s "$MOUNT/.VolumeIcon.icns"
test -s "$MOUNT/.background/background.tiff"
shopt -s dotglob nullglob
for item in "$MOUNT"/* "$MOUNT"/.background/*; do
  case "${item#"$MOUNT"/}" in
    Applications|Pokelet.app|.DS_Store|.VolumeIcon.icns|.background|.background/background.tiff) ;;
    *) printf 'Unexpected mounted image item: %s\n' "${item##*/}" >&2; exit 1 ;;
  esac
done
shopt -u dotglob nullglob
# Compare nested framework symlinks as links, without traversing their aliases.
bundle_diff="$(/usr/bin/rsync -nrlpci --delete "$APP/" "$MOUNT/Pokelet.app/")"
if [[ -n "$bundle_diff" ]]; then
  printf 'Mounted bundle differs from the approved app:\n%s\n' "$bundle_diff" >&2
  exit 1
fi
"$ROOT/script/test_native.sh" "$MOUNT/Pokelet.app"
if [[ "$MODE" == --notarise ]]; then
  if [[ "$APP_SUPPLIED" == true ]]; then
    xcrun stapler validate "$MOUNT/Pokelet.app"
  fi
  /usr/sbin/spctl --assess --type execute --verbose=2 "$MOUNT/Pokelet.app"
fi
/usr/bin/hdiutil detach -quiet "$MOUNT"
attached=false

if [[ "$MODE" == --check-layout ]]; then
  printf 'DMG layout and embedded bundle verified. Temporary image discarded.\n'
  exit
fi

DMG_NAME="${DMG##*/}"
(
  cd "$STAGE"
  shasum -a 256 "$DMG_NAME" > "$DMG_NAME.sha256"
  shasum -a 256 -c "$DMG_NAME.sha256"
)
mkdir "$OUT"
mv "$DMG" "$DMG.sha256" "$OUT/"
if [[ "$MODE" == --notarise ]]; then mv "$STAGE/notary-log.json" "$OUT/"; fi
retain_stage=false
printf '%s\n' "$OUT/$DMG_NAME" "$OUT/$DMG_NAME.sha256"
