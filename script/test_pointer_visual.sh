#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ $# -lt 1 || $# -gt 2 ]]; then
  printf 'Usage: %s output-directory [7dc810c-source-directory]\n' "$0" >&2
  exit 2
fi
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-visual.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
SOURCE="${2:-$ROOT}"
flags=()
if [[ $# -eq 2 ]]; then flags+=(-D BASELINE); fi

xcrun swiftc -warnings-as-errors -parse-as-library ${flags[@]+"${flags[@]}"} \
  "$SOURCE"/Pokelet/Models/*.swift "$SOURCE"/Pokelet/Cursor/{PointerArt,PresenterArm,PointerLayer}.swift \
  "$ROOT/Tests/Native/PointerVisualSmoke.swift" -o "$TEMP/PointerVisualSmoke"
"$TEMP/PointerVisualSmoke" "$1"
