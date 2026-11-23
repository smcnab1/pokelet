#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-layout.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
if [[ $# -gt 1 ]]; then
  printf 'Usage: %s [Xcode Debug products directory]\n' "$0" >&2
  exit 2
fi
if [[ $# -eq 0 ]]; then
  xcodebuild -quiet -onlyUsePackageVersionsFromResolvedFile -project "$ROOT/Pokelet.xcodeproj" -scheme Pokelet \
    -configuration Debug -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath "$ROOT/build/debug" \
    SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
fi
FRAMEWORKS="$(cd "${1:-$ROOT/build/debug/Build/Products/Debug}" && pwd -P)"
sources=()
for path in "$ROOT"/Pokelet/{App,Cursor,Models,Services,Views}/*.swift; do
  [[ "$path" == */main.swift ]] || sources+=("$path")
done
xcrun swiftc -warnings-as-errors -parse-as-library -F "$FRAMEWORKS" \
  -Xlinker -rpath -Xlinker "$FRAMEWORKS" "${sources[@]}" \
  "$ROOT/Tests/Native/StudioLayoutSmoke.swift" -o "$TEMP/StudioLayoutSmoke"
"$TEMP/StudioLayoutSmoke" --acceptance-profile --presentation-acceptance --studio-acceptance
