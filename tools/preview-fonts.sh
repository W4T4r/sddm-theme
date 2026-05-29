#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
preview_dir="$repo_root/Previews"
mkdir -p "$preview_dir"

if command -v magick >/dev/null 2>&1; then
  magick_cmd=(magick)
elif command -v convert >/dev/null 2>&1; then
  magick_cmd=(convert)
else
  echo "ImageMagick is required: install magick or convert." >&2
  exit 1
fi

fonts=(
  "open-sans|Open Sans|Fonts/OpenSans/OpenSans-Regular.ttf"
  "arcadeclassic|ArcadeClassic|Fonts/ARCADECLASSIC.TTF"
  "espacion|ESPACION|Fonts/ESPACION.ttf"
  "electroharmonix|Electroharmonix|Fonts/Electroharmonix.otf"
  "fragile-bombers|Fragile Bombers|Fonts/Fragile Bombers.otf"
  "fragile-bombers-attack|Fragile Bombers Attack|Fonts/Fragile Bombers Attack.otf"
  "fragile-bombers-down|Fragile Bombers Down|Fonts/Fragile Bombers Down.otf"
  "kognigear|KogniGear|Fonts/KogniGear.ttf"
  "orbitron|Orbitron|Fonts/Orbitron Black.ttf"
  "pixelon|Pixelon|Fonts/pixelon.regular.ttf"
  "thunderman|Thunderman|Fonts/Thunderman.ttf"
)

for entry in "${fonts[@]}"; do
  IFS="|" read -r id family font_path <<<"$entry"
  full_path="$repo_root/$font_path"

  if [[ ! -f "$full_path" ]]; then
    echo "skip $family: font not found" >&2
    continue
  fi

  "${magick_cmd[@]}" \
    -size 900x180 xc:'#21222c' \
    -fill '#f8f8f2' \
    -font "$full_path" \
    -pointsize 46 \
    -gravity center \
    -annotate +0-18 'sddm-theme 0123456789' \
    -fill '#b7cef1' \
    -font DejaVu-Sans \
    -pointsize 22 \
    -annotate +0+58 "$family" \
    "$preview_dir/font-$id.png"

  echo "$preview_dir/font-$id.png"
done
