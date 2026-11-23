#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sign_with_developer_id=false
if [[ "${1:-}" == --developer-id ]]; then
  sign_with_developer_id=true
  shift
fi
OUT="${1:-$ROOT/dist/candidate}"
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [--developer-id] [output-directory]\n' "$0" >&2
  exit 2
fi
if [[ -e "$OUT" || -L "$OUT" ]]; then
  printf 'Choose a new output directory. Existing output was preserved: %s\n' "$OUT" >&2
  exit 2
fi
mkdir -p "$(dirname "$OUT")"
STAGE="$(mktemp -d "$(dirname "$OUT")/.pokelet-package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
UPDATE_TOOLS="${POKELET_SPARKLE_TOOLS:-}"
UPDATE_ACCOUNT="${POKELET_SPARKLE_KEYCHAIN_ACCOUNT:-}"
IDENTITY="${POKELET_DEVELOPER_ID:-}"
update_key=""
update_feed=""
update_compilation=""
if [[ "$sign_with_developer_id" == true ]]; then
  if [[ ! "$IDENTITY" =~ ^[[:xdigit:]]{40}$ ]]; then
    printf 'Set POKELET_DEVELOPER_ID to the approved local certificate fingerprint.\n' >&2
    exit 2
  fi
  /usr/bin/security find-identity -v -p codesigning | awk -v id="$IDENTITY" '
    /^ *[0-9]+\)/ && /"Developer ID Application: / && toupper($2) == toupper(id) { found = 1 }
    END { exit !found }
  ' || { printf 'No matching Developer ID Application identity.\n' >&2; exit 2; }
fi
if [[ -n "$UPDATE_TOOLS" || -n "$UPDATE_ACCOUNT" ]]; then
  if [[ "$sign_with_developer_id" != true || -z "$UPDATE_TOOLS" || -z "$UPDATE_ACCOUNT" ]]; then
    printf 'Updates require --developer-id, the pinned Sparkle tools and a Keychain account.\n' >&2
    exit 2
  fi
  update_key="$("$UPDATE_TOOLS/generate_keys" --account "$UPDATE_ACCOUNT" -p)"
  if [[ ! "$update_key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
    printf 'Sparkle did not return a valid public key.\n' >&2
    exit 2
  fi
  update_feed="https://smcnab1.github.io/pokelet/updates/appcast.xml"
  update_compilation=POKELET_SIGNED_UPDATES
fi

# Build locally. The opt-in Developer ID signing path obtains Apple's secure timestamps.
xcodebuild -quiet -onlyUsePackageVersionsFromResolvedFile -project "$ROOT/Pokelet.xcodeproj" -scheme Pokelet -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$ROOT/build/release" \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
  POKELET_UPDATE_FEED_URL="$update_feed" POKELET_UPDATE_PUBLIC_KEY="$update_key" \
  POKELET_UPDATE_COMPILATION="$update_compilation" build

mkdir "$STAGE/candidate" "$STAGE/extracted"
APP="$STAGE/candidate/Pokelet.app"
ZIP="$STAGE/candidate/Pokelet.zip"
/usr/bin/ditto "$ROOT/build/release/Build/Products/Release/Pokelet.app" "$APP"
if [[ "$sign_with_developer_id" == true ]]; then
  # Sign the versioned framework from the inside out so Hardened Runtime keeps library validation enabled.
  framework="$APP/Contents/Frameworks/Sparkle.framework"
  sparkle="$framework/Versions/Current"
  for component in "$sparkle/Autoupdate" "$sparkle/Updater.app" "$sparkle"/XPCServices/*.xpc "$framework" "$APP"; do
    /usr/bin/codesign --force --options runtime --timestamp --sign "$IDENTITY" "$component"
  done
fi
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
(
  cd "$STAGE/candidate"
  shasum -a 256 Pokelet.zip > Pokelet.zip.sha256
  shasum -a 256 -c Pokelet.zip.sha256
)
unzip -tq "$ZIP"
/usr/bin/ditto -x -k "$ZIP" "$STAGE/extracted"
EXTRACTED="$STAGE/extracted/Pokelet.app"
"$ROOT/script/test_native.sh" "$EXTRACTED"
BINARY="$EXTRACTED/Contents/MacOS/Pokelet"
if [[ -n "$update_key" ]]; then
  for arch in arm64 x86_64; do
    otool -arch "$arch" -L "$BINARY" | awk '/Sparkle[.]framework/ { found = 1 } END { exit !found }'
  done
else
  # An ad hoc hardened process cannot load the Sparkle dylib without a matching team.
  otool -arch all -L "$BINARY" | awk '/Sparkle[.]framework/ { found = 1 } END { exit found }'
fi
ARCHITECTURES="$(xcrun lipo -archs "$BINARY" | tr ' ' '\n' | sort)"
if [[ "$ARCHITECTURES" != $'arm64\nx86_64' ]]; then
  printf 'Unexpected binary architectures:\n%s\n' "$ARCHITECTURES" >&2
  exit 1
fi
printf 'Verified universal binary: arm64 and x86_64.\n'
for arch in arm64 x86_64; do
  xcrun strings -a -arch "$arch" "$BINARY" | awk '
    /--(presentation-acceptance|studio-acceptance|acceptance-profile)/ { found = 1 }
    END { exit found }
  ' || { printf 'Release binary includes a Debug acceptance launch flag on %s.\n' "$arch" >&2; exit 1; }
  xcrun vtool -arch "$arch" -show-build "$BINARY" | awk '
    $1 == "platform" && $2 == "MACOS" { macos = 1 }
    $1 == "minos" && $2 == "14.0" { target = 1 }
    END { exit !(macos && target) }
  '
  /usr/bin/codesign --display --arch "$arch" --entitlements - --xml "$EXTRACTED" > "$STAGE/entitlements.plist"
  if [[ -s "$STAGE/entitlements.plist" ]]; then
    /usr/bin/plutil -lint "$STAGE/entitlements.plist"
    DEBUGGABLE="$(/usr/bin/plutil -extract 'com\.apple\.security\.get-task-allow' raw \
      "$STAGE/entitlements.plist" 2>/dev/null || true)"
    LIBRARY_VALIDATION_DISABLED="$(/usr/bin/plutil -extract 'com\.apple\.security\.cs\.disable-library-validation' raw \
      "$STAGE/entitlements.plist" 2>/dev/null || true)"
    if [[ "$LIBRARY_VALIDATION_DISABLED" == true ]]; then
      printf 'Release build disables library validation on %s.\n' "$arch" >&2
      exit 1
    fi
    if [[ "$DEBUGGABLE" == true ]]; then
      printf 'Release build has the get-task-allow entitlement on %s.\n' "$arch" >&2
      exit 1
    fi
  fi
done

# mkdir reserves the output name atomically so concurrent builds cannot overwrite it.
mkdir "$OUT"
mv "$APP" "$ZIP" "$ZIP.sha256" "$OUT/"
printf '%s\n' "$OUT/Pokelet.app" "$OUT/Pokelet.zip" "$OUT/Pokelet.zip.sha256"
