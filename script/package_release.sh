#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/dist/candidate}"
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [output-directory]\n' "$0" >&2
  exit 2
fi
if [[ -e "$OUT" || -L "$OUT" ]]; then
  printf 'Choose a new output directory. Existing output was preserved: %s\n' "$OUT" >&2
  exit 2
fi
mkdir -p "$(dirname "$OUT")"
STAGE="$(mktemp -d "$(dirname "$OUT")/.pokelet-package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
# All build and signing operations are local. No app is launched.
xcodebuild -quiet -project "$ROOT/Pokelet.xcodeproj" -scheme Pokelet -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$ROOT/build/release" \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO build

mkdir "$STAGE/candidate" "$STAGE/extracted"
APP="$STAGE/candidate/Pokelet.app"
ZIP="$STAGE/candidate/Pokelet.zip"
/usr/bin/ditto "$ROOT/build/release/Build/Products/Release/Pokelet.app" "$APP"
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
ARCHITECTURES="$(xcrun lipo -archs "$BINARY" | tr ' ' '\n' | sort)"
if [[ "$ARCHITECTURES" != $'arm64\nx86_64' ]]; then
  printf 'Unexpected binary architectures:\n%s\n' "$ARCHITECTURES" >&2
  exit 1
fi
printf 'Verified universal binary: arm64 and x86_64.\n'
for arch in arm64 x86_64; do
  xcrun strings -a -arch "$arch" "$BINARY" | awk '
    /--presentation-acceptance/ { found = 1 }
    END { exit found }
  ' || { printf 'Release binary still includes the Presentation Mode launch flag on %s.\n' "$arch" >&2; exit 1; }
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
