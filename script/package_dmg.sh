#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-}"
case "$MODE" in
  --check-layout)
    [[ $# -eq 2 ]] || exit 2
    APP="$(cd "$2" && pwd -P)"
    ;;
  --notarise)
    [[ $# -le 2 ]] || exit 2
    OUT="${2:-$ROOT/dist/notarised}"
    if [[ -e "$OUT" || -L "$OUT" ]]; then
      printf 'Choose a new output directory. Existing output was preserved.\n' >&2
      exit 2
    fi
    if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
      printf 'Commit all source changes before packaging a release.\n' >&2
      exit 2
    fi
    IDENTITY="${POKELET_DEVELOPER_ID:-}"
    PROFILE="${POKELET_NOTARY_PROFILE:-}"
    if [[ ! "$IDENTITY" =~ ^[[:xdigit:]]{40}$ || -z "$PROFILE" ]]; then
      printf 'Set POKELET_DEVELOPER_ID to the local certificate fingerprint and POKELET_NOTARY_PROFILE to a Keychain profile.\n' >&2
      exit 2
    fi
    if ! /usr/bin/security find-identity -v -p codesigning | /usr/bin/awk -v id="$IDENTITY" '
      toupper($2) == toupper(id) && $0 ~ /"Developer ID Application: / { found = 1 }
      END { exit !found }
    '; then
      printf 'A valid Developer ID Application identity with its private key is required.\n' >&2
      exit 2
    fi
    xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null
    mkdir -p "$(dirname "$OUT")"
    ;;
  *)
    printf 'Usage: %s --check-layout path/to/Pokelet.app | --notarise [output-directory]\n' "$0" >&2
    exit 2
    ;;
esac

STAGE="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-dmg.XXXXXX")"
MOUNT="$STAGE/mounted"
attached=false
cleanup() {
  if [[ "$attached" == true ]] && ! /usr/bin/hdiutil detach "$MOUNT" -quiet; then
    printf 'Disk image is still mounted at %s. Staging was retained.\n' "$MOUNT" >&2
    return
  fi
  rm -rf "$STAGE"
}
trap cleanup EXIT

if [[ "$MODE" == --notarise ]]; then
  "$ROOT/script/package_release.sh" "$STAGE/candidate"
  APP="$STAGE/candidate/Pokelet.app"
  /usr/bin/codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
  /usr/bin/codesign --verify --deep --strict "$APP"
fi

mkdir "$STAGE/layout" "$MOUNT"
/usr/bin/ditto "$APP" "$STAGE/layout/Pokelet.app"
ln -s /Applications "$STAGE/layout/Applications"
VERSION="$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$APP/Contents/Info.plist")"
DMG="$STAGE/Pokelet-$VERSION.dmg"
/usr/bin/hdiutil create -quiet -volname Pokelet -fs HFS+ -format UDZO -srcfolder "$STAGE/layout" "$DMG"

if [[ "$MODE" == --notarise ]]; then
  /usr/bin/codesign --timestamp --sign "$IDENTITY" "$DMG"
  if ! xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait --timeout 30m \
      --output-format plist > "$STAGE/notary.plist"; then
    cat "$STAGE/notary.plist" >&2
    exit 1
  fi
  if [[ "$(/usr/bin/plutil -extract status raw "$STAGE/notary.plist")" != Accepted ]]; then
    /usr/bin/plutil -p "$STAGE/notary.plist" >&2
    exit 1
  fi
  printf 'Apple notarisation accepted, submission %s\n' "$(/usr/bin/plutil -extract id raw "$STAGE/notary.plist")"
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
printf '%s\n' "$OUT/$DMG_NAME" "$OUT/$DMG_NAME.sha256"
