#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DESIGN="$ROOT/packaging/dmg"
OUT="${1:-}"
if [[ $# -ne 1 || -e "$OUT" || -L "$OUT" ]]; then
  printf 'Usage: %s path/to/new-template.dmg\n' "$0" >&2
  exit 2
fi

# Finder bookmarks record the authoring path. Keep it outside the user's home.
STAGE="$(mktemp -d /private/tmp/pokelet-dmg-template.XXXXXX)"
MOUNT="$STAGE/mounted"
attached=false
cleanup() {
  if [[ "$attached" == true ]] && ! /usr/bin/hdiutil detach -quiet "$MOUNT"; then
    printf 'Template remains mounted at %s. Staging was retained.\n' "$MOUNT" >&2
    return
  fi
  rm -rf "$STAGE"
}
trap cleanup EXIT

xcrun swiftc -warnings-as-errors -o "$STAGE/render" \
  "$DESIGN/Background.swift" "$ROOT"/Pokelet/Cursor/{PointerArt,PointerLayer,PresenterArm}.swift \
  "$ROOT"/Pokelet/Models/{CursorGeometry,Preferences,KeyCodeNames}.swift
mkdir -p "$STAGE/layout/.background" "$STAGE/layout/Pokelet.app" "$STAGE/Volume.iconset" "$MOUNT"
"$STAGE/render" "$STAGE/layout/.background/background.tiff"
ln -s /Applications "$STAGE/layout/Applications"

# Use the project's original app artwork for the mounted volume.
ART="$ROOT/Pokelet/Assets.xcassets/AppIcon.appiconset"
for size in 16 32 128; do
  cp "$ART/Pokelet-$size.png" "$STAGE/Volume.iconset/icon_${size}x${size}.png"
  cp "$ART/Pokelet-$((size * 2)).png" "$STAGE/Volume.iconset/icon_${size}x${size}@2x.png"
done
/usr/bin/iconutil -c icns "$STAGE/Volume.iconset" -o "$STAGE/layout/.VolumeIcon.icns"

# Record the open-on-mount folder through hdiutil, then let Finder write view settings
# on that same filesystem so its background bookmark points to this disk and file.
/usr/bin/hdiutil makehybrid -quiet -hfs -hfs-volume-name 'Pokelet Installer' \
  -hfs-openfolder "$STAGE/layout" -o "$STAGE/seed.dmg" "$STAGE/layout"
/usr/bin/hdiutil convert -quiet -format UDRW -o "$STAGE/template-rw.dmg" "$STAGE/seed.dmg"
/usr/bin/hdiutil resize -size 32m "$STAGE/template-rw.dmg"
/usr/bin/hdiutil attach -quiet -noautoopen -mountpoint "$MOUNT" "$STAGE/template-rw.dmg"
attached=true
xcrun SetFile -a C "$MOUNT"
xcrun SetFile -a V "$MOUNT/.background" "$MOUNT/.VolumeIcon.icns"
/usr/bin/osascript "$DESIGN/FinderLayout.applescript" "$MOUNT"
test -s "$MOUNT/.DS_Store"
rm -rf "$MOUNT/.fseventsd"
/usr/bin/hdiutil detach -quiet "$MOUNT"
attached=false
/usr/bin/hdiutil convert -quiet -format UDZO -o "$STAGE/template.dmg" "$STAGE/template-rw.dmg"
/usr/bin/hdiutil verify -quiet "$STAGE/template.dmg"
(
  set -o noclobber
  cat "$STAGE/template.dmg" > "$OUT"
)
