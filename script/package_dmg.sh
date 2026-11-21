#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"
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
    [[ $# -le 2 ]] || exit 2
    if [[ "$MODE" == --beta ]]; then
      OUT="${2:-$ROOT/dist/beta}"
    else
      OUT="${2:-$ROOT/dist/notarised}"
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
    printf 'Usage: %s --check-signing | --check-layout path/to/Pokelet.app | --beta [output-directory] | --notarise [output-directory]\n' "$0" >&2
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

if [[ "$MODE" != --check-layout ]]; then
  "$ROOT/script/package_release.sh" "$STAGE/candidate"
  APP="$STAGE/candidate/Pokelet.app"
fi

if [[ "$MODE" == --notarise ]]; then
  /usr/bin/codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
  /usr/bin/codesign --verify --deep --strict "$APP"
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
  for arch in arm64 x86_64; do
    /usr/bin/codesign --display --arch "$arch" --verbose=4 "$APP" 2>&1 | /usr/bin/awk '
      $0 == "Signature=adhoc" { adhoc = 1 }
      END { exit !adhoc }
    '
  done
fi

mkdir "$STAGE/layout" "$MOUNT"
/usr/bin/ditto "$APP" "$STAGE/layout/Pokelet.app"
ln -s /Applications "$STAGE/layout/Applications"
VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
SUFFIX=""
if [[ "$MODE" == --beta ]]; then SUFFIX="-unnotarised"; fi
DMG="$STAGE/Pokelet-$VERSION$SUFFIX.dmg"
/usr/bin/hdiutil create -quiet -volname Pokelet -fs HFS+ -format UDZO -srcfolder "$STAGE/layout" "$DMG"

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
cmp "$APP/Contents/MacOS/Pokelet" "$MOUNT/Pokelet.app/Contents/MacOS/Pokelet"
"$ROOT/script/test_native.sh" "$MOUNT/Pokelet.app"
if [[ "$MODE" == --notarise ]]; then
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
