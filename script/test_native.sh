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
cmp "$ROOT/LICENSE" "$APP/Contents/Resources/Pokelet-MIT.txt"
cmp "$ROOT/Pokelet/Resources/QuietPointer-MIT.txt" "$APP/Contents/Resources/QuietPointer-MIT.txt"
xcrun swiftc -parse-as-library -o "$TEMP/BundleSmoke" "$ROOT/Tests/Native/BundleSmoke.swift"
"$TEMP/BundleSmoke" "$APP"
