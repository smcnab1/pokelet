#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf '%s\n' "$*" >&2
  exit 1
}

if [[ $# -ne 3 ]]; then
  printf 'Usage: %s <approved.dmg> <approved SHA-256> <Minisign private-key path>\n' "$0" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLIC_KEY="$ROOT/security/pokelet-minisign.pub"
EXPECTED="$2"
PRIVATE_KEY="$3"
[[ "$EXPECTED" =~ ^[0-9a-f]{64}$ ]] || fail 'Expected a lowercase, 64-character SHA-256.'
command -v minisign >/dev/null || fail 'Install Minisign before signing or verifying a release.'
cd -- "$(dirname -- "$1")"
DMG="$(basename -- "$1")"
SIGNATURE="$DMG.minisig"

check_release_bytes() {
  [[ -f "$DMG" ]] || fail 'The approved DMG is missing.'
  local checksum
  checksum="$(shasum -a 256 -- "$DMG")"
  [[ "${checksum%% *}" == "$EXPECTED" ]] || fail 'DMG SHA-256 differs from the approved value.'
  if [[ ! -f "$DMG.sha256" ]] || ! cmp -s "$DMG.sha256" <(printf '%s\n' "$checksum"); then
    fail 'The checksum sidecar must match the output of shasum for the approved DMG.'
  fi
}

check_release_bytes
WORK="$(mktemp -d './.pokelet-sign.XXXXXX')"
trap 'rm -rf -- "$WORK"' EXIT
CANDIDATE="$WORK/$SIGNATURE"

if [[ -e "$SIGNATURE" || -L "$SIGNATURE" ]]; then
  CANDIDATE="$SIGNATURE"
else
  [[ -t 0 ]] || fail 'Run this command in Terminal to use the secure Minisign passphrase prompt.'
  minisign -S -s "$PRIVATE_KEY" -m "$DMG" -x "$CANDIDATE" -t "Pokelet release: $DMG"
fi

minisign -Vm "$DMG" -p "$PUBLIC_KEY" -x "$CANDIDATE"
cp -- "$DMG" "$WORK/tampered.dmg"
printf '\001' >> "$WORK/tampered.dmg"
if minisign -Vm "$WORK/tampered.dmg" -p "$PUBLIC_KEY" -x "$CANDIDATE" >/dev/null 2>&1; then
  fail 'Minisign unexpectedly accepted a modified copy.'
fi
printf 'Minisign rejected the modified copy as expected.\n'

check_release_bytes
if [[ "$CANDIDATE" != "$SIGNATURE" ]]; then
  ln -- "$CANDIDATE" "$SIGNATURE"
fi
printf 'Verified signature: %s/%s\n' "$PWD" "$SIGNATURE"
printf 'Approved SHA-256: %s\n' "$EXPECTED"
