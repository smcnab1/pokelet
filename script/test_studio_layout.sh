#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-layout.XXXXXX")"
trap 'rm -rf "$TEMP"' EXIT
sources=()
for path in "$ROOT"/Pokelet/{App,Cursor,Models,Services,Views}/*.swift; do
  [[ "$path" == */main.swift ]] || sources+=("$path")
done
xcrun swiftc -warnings-as-errors -parse-as-library "${sources[@]}" \
  "$ROOT/Tests/Native/StudioLayoutSmoke.swift" -o "$TEMP/StudioLayoutSmoke"
"$TEMP/StudioLayoutSmoke" --acceptance-profile --presentation-acceptance --studio-acceptance
