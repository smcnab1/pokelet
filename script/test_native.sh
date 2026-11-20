#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d /tmp/pokelet-native.XXXXXX)"
trap 'rm -rf "$TEMP"' EXIT

APP="$("$ROOT/script/build_and_run.sh" --build | tail -n 1)"
xcrun swiftc -O -o "$TEMP/PokeletOverlaySmoke" \
  "$ROOT"/Pokelet/Models/*.swift "$ROOT"/Pokelet/Cursor/*.swift \
  "$ROOT/Pokelet/Services/CursorController.swift" "$ROOT/Pokelet/Services/PresentationTap.swift" \
  "$ROOT/Tests/Native/OverlaySmoke.swift"
"$TEMP/PokeletOverlaySmoke" "$APP/Contents/Resources"
