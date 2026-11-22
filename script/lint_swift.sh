#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=0.65.1
SHA256=c1e429b0599cf1b516f369a2d9ec04eaf0e436f3c12b637df8851fa52ff694d0
WORK="$(mktemp -d "${TMPDIR:-/tmp}/pokelet-swiftlint.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
ARCHIVE="$WORK/portable_swiftlint.zip"

curl -q --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
  --max-time 120 --retry 2 \
  "https://github.com/realm/SwiftLint/releases/download/$VERSION/portable_swiftlint.zip" -o "$ARCHIVE"
printf '%s  %s\n' "$SHA256" "$ARCHIVE" | shasum -a 256 -c -
/usr/bin/ditto -x -k "$ARCHIVE" "$WORK"

cd "$ROOT"
"$WORK/swiftlint" lint --strict --no-cache
