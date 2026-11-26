#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sign_with_developer_id=false
ad_hoc_updates=false
case "${1:-}" in
  --developer-id) sign_with_developer_id=true; shift ;;
  --ad-hoc-updates) ad_hoc_updates=true; shift ;;
esac
channel=stable
if [[ "${1:-}" == --channel ]]; then
  channel="${2:-}"
  if [[ "$channel" != beta && "$channel" != stable ]]; then
    printf 'Choose --channel beta or --channel stable.\n' >&2
    exit 2
  fi
  shift 2
fi
OUT="${1:-$ROOT/dist/candidate}"
if [[ $# -gt 1 || "$OUT" == --* ]]; then
  printf 'Usage: %s [--developer-id | --ad-hoc-updates] [--channel stable|beta] [output-directory]\n' "$0" >&2
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
entitlements=""
analytics_app_id=""
analytics_namespace=""
if [[ -z "${CI:-}" ]]; then
  analytics_app_id="${POKELET_TELEMETRYDECK_APP_ID:-}"
  analytics_namespace="${POKELET_TELEMETRYDECK_NAMESPACE:-}"
fi
if [[ ( -n "$analytics_app_id" && ! "$analytics_app_id" =~ ^[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}$ ) ||
      ( -n "$analytics_namespace" && ( -z "$analytics_app_id" || ! "$analytics_namespace" =~ ^[A-Za-z0-9_-]+([.][A-Za-z0-9_-]+)*$ ) ) ]]; then
  printf 'Use a TelemetryDeck app UUID and, if assigned, its organisation namespace.\n' >&2
  exit 2
fi
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
if [[ "$ad_hoc_updates" == true || "$channel" == beta || -n "$UPDATE_TOOLS" || -n "$UPDATE_ACCOUNT" ]]; then
  if [[ ( "$sign_with_developer_id" != true && "$ad_hoc_updates" != true ) || -z "$UPDATE_TOOLS" ||
        "$UPDATE_ACCOUNT" != "pokelet-$channel" ]]; then
    printf 'Updates require an explicit signing mode, pinned Sparkle tools and the pokelet-%s Keychain account.\n' "$channel" >&2
    exit 2
  fi
  if [[ "${POKELET_SPARKLE_BACKUP_CONFIRMED:-}" != "$UPDATE_ACCOUNT" ]]; then
    printf 'Confirm the secure offline backup by setting POKELET_SPARKLE_BACKUP_CONFIRMED to %s.\n' "$UPDATE_ACCOUNT" >&2
    exit 2
  fi
  update_key="$("$UPDATE_TOOLS/generate_keys" --account "$UPDATE_ACCOUNT" -p)"
  if [[ ! "$update_key" =~ ^[A-Za-z0-9+/]{43}=$ ]]; then
    printf 'Sparkle did not return a valid public key.\n' >&2
    exit 2
  fi
  update_feed="https://smcnab1.github.io/pokelet/updates"
  if [[ "$channel" == beta ]]; then update_feed+=/beta; fi
  update_feed+=/appcast.xml
  update_compilation=POKELET_SIGNED_UPDATES
  if [[ "$ad_hoc_updates" == true ]]; then
    entitlements="$ROOT/packaging/AdHocUpdates.entitlements"
  fi
fi

# Build locally. The opt-in Developer ID signing path obtains Apple's secure timestamps.
xcodebuild -quiet -onlyUsePackageVersionsFromResolvedFile -project "$ROOT/Pokelet.xcodeproj" -scheme Pokelet -configuration Release \
  -destination 'generic/platform=macOS' -derivedDataPath "$STAGE/derived" \
  -clonedSourcePackagesDirPath "$ROOT/build/release/SourcePackages" \
  'ARCHS=arm64 x86_64' ONLY_ACTIVE_ARCH=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO CODE_SIGN_ENTITLEMENTS="$entitlements" \
  POKELET_UPDATE_FEED_URL="$update_feed" POKELET_UPDATE_PUBLIC_KEY="$update_key" \
  POKELET_UPDATE_COMPILATION="$update_compilation" \
  POKELET_TELEMETRYDECK_APP_ID="$analytics_app_id" POKELET_TELEMETRYDECK_NAMESPACE="$analytics_namespace" build

mkdir "$STAGE/candidate" "$STAGE/extracted"
APP="$STAGE/candidate/Pokelet.app"
ZIP="$STAGE/candidate/Pokelet.zip"
/usr/bin/ditto "$STAGE/derived/Build/Products/Release/Pokelet.app" "$APP"
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
  # Manual-download builds must not load Sparkle.
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
    /--(presentation-acceptance|studio-acceptance|acceptance-profile)|Pokelet[.]UpdateAcceptance/ { found = 1 }
    END { exit found }
  ' || { printf 'Release binary includes an acceptance test marker on %s.\n' "$arch" >&2; exit 1; }
  xcrun vtool -arch "$arch" -show-build "$BINARY" | awk '
    $1 == "platform" && $2 == "MACOS" { macos = 1 }
    $1 == "minos" && $2 == "14.0" { target = 1 }
    END { exit !(macos && target) }
  '
  signing="$(/usr/bin/codesign --display --verbose=4 --arch "$arch" --entitlements - --xml "$EXTRACTED" \
    2>&1 > "$STAGE/entitlements.plist")"
  if ! awk '/^CodeDirectory .*flags=.*[(,]runtime[,)]/ { found = 1 } END { exit !found }' <<< "$signing"; then
    printf 'Expected Hardened Runtime on %s.\n' "$arch" >&2
    exit 1
  fi
  LIBRARY_VALIDATION_DISABLED=""
  if [[ -s "$STAGE/entitlements.plist" ]]; then
    /usr/bin/plutil -lint "$STAGE/entitlements.plist"
    DEBUGGABLE="$(/usr/bin/plutil -extract 'com\.apple\.security\.get-task-allow' raw \
      "$STAGE/entitlements.plist" 2>/dev/null || true)"
    LIBRARY_VALIDATION_DISABLED="$(/usr/bin/plutil -extract 'com\.apple\.security\.cs\.disable-library-validation' raw \
      "$STAGE/entitlements.plist" 2>/dev/null || true)"
    if [[ "$DEBUGGABLE" == true ]]; then
      printf 'Release build has the get-task-allow entitlement on %s.\n' "$arch" >&2
      exit 1
    fi
  fi
  if [[ "$ad_hoc_updates" == true ]]; then
    if [[ "$LIBRARY_VALIDATION_DISABLED" != true || "$signing" != *Signature=adhoc* ]]; then
      printf 'Expected the ad hoc updater entitlement and signature on %s.\n' "$arch" >&2
      exit 1
    fi
  elif [[ "$LIBRARY_VALIDATION_DISABLED" == true ]]; then
    printf 'Unexpected library validation exception on %s.\n' "$arch" >&2
    exit 1
  fi
done

# mkdir reserves the output name atomically so concurrent builds cannot overwrite it.
mkdir "$OUT"
mv "$APP" "$ZIP" "$ZIP.sha256" "$OUT/"
printf '%s\n' "$OUT/Pokelet.app" "$OUT/Pokelet.zip" "$OUT/Pokelet.zip.sha256"
