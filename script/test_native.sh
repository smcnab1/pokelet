#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-native.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT

if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [path/to/Pokelet.app]\n' "$0" >&2
  exit 2
elif [[ $# -eq 1 ]]; then
  APP="$1"
else
  APP="$("$ROOT/script/build_and_run.sh" --build | tail -n 1)"
fi

/usr/bin/plutil -lint "$APP/Contents/Info.plist"
/usr/bin/codesign --verify --deep --strict "$APP"
cmp "$ROOT/CHANGELOG.md" "$APP/Contents/Resources/CHANGELOG.md"
cmp "$ROOT/Pokelet/Resources/Sparkle-LICENSE.txt" "$APP/Contents/Resources/Sparkle-LICENSE.txt"
FRAMEWORK="$APP/Contents/Frameworks/Sparkle.framework"
LOCK="$ROOT/Pokelet.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
[[ "$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$FRAMEWORK/Resources/Info.plist")" == \
   "$(/usr/bin/plutil -extract pins.0.state.version raw "$LOCK")" ]]
for executable in "$FRAMEWORK/Sparkle" "$FRAMEWORK/Autoupdate" "$FRAMEWORK/Updater.app/Contents/MacOS/Updater"; do
  [[ "$(xcrun lipo -archs "$executable" | tr ' ' '\n' | sort)" == $'arm64\nx86_64' ]]
done
printf 'Verified embedded Sparkle framework, helpers, licences and both architectures.\n'
cmp "$ROOT/LICENSE" "$APP/Contents/Resources/Pokelet-MIT.txt"
cmp "$ROOT/Pokelet/Resources/QuietPointer-MIT.txt" "$APP/Contents/Resources/QuietPointer-MIT.txt"
xcrun swiftc -parse-as-library -o "$TEMP/BundleSmoke" \
  "$ROOT/Tests/Native/BundleSmoke.swift" "$ROOT/Pokelet/Models/ReleaseNotes.swift"
"$TEMP/BundleSmoke" "$APP"
