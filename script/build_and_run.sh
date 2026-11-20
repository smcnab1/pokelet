#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-run}"
APP="$ROOT/build/Build/Products/Release/Pokelet.app"

case "$MODE" in
  run|--build|--package|--settings|--verify|--debug|--logs|--telemetry) ;;
  *) printf 'Usage: %s [--build|--package|--settings|--verify|--debug|--logs|--telemetry]\n' "$0" >&2; exit 2 ;;
esac

if [[ "$MODE" == --package ]]; then
  exec "$ROOT/script/package_release.sh"
fi

if [[ "$MODE" != --build ]]; then
  # Only quit the copy this script manages.
  POKELET_PIDS="$(pgrep -f "^$APP/Contents/MacOS/Pokelet([[:space:]]|$)" || true)"
  if [[ -n "$POKELET_PIDS" ]]; then
    while IFS= read -r pid; do kill -TERM "$pid" 2>/dev/null || true; done <<< "$POKELET_PIDS"
    for _ in {1..30}; do
      if ! pgrep -f "^$APP/Contents/MacOS/Pokelet([[:space:]]|$)" >/dev/null; then break; fi
      sleep 0.1
    done
  fi
fi

xcodebuild -quiet -project "$ROOT/Pokelet.xcodeproj" -scheme Pokelet -configuration Release \
  -destination "platform=macOS,arch=$(uname -m)" -derivedDataPath "$ROOT/build" SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
codesign --verify --deep --strict "$APP"

case "$MODE" in
  --build) printf '%s\n' "$APP" ;;
  --settings) open -n "$APP" --args --settings ;;
  --verify)
    open -n "$APP"
    for _ in {1..30}; do
      if pgrep -lf "^$APP/Contents/MacOS/Pokelet([[:space:]]|$)"; then exit 0; fi
      sleep 0.2
    done
    exit 1
    ;;
  --debug) exec lldb -- "$APP/Contents/MacOS/Pokelet" ;;
  --logs) open -n "$APP"; exec log stream --info --predicate 'process == "Pokelet"' ;;
  --telemetry) open -n "$APP"; exec log stream --info --predicate 'subsystem == "uk.co.sammcnab.Pokelet"' ;;
  *) open -n "$APP" ;;
esac
