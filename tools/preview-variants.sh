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

is_preview_source() {
  local file="$1"
  local ext="${file##*.}"

  ext="${ext,,}"
  [[ "$ext" == "png" || "$ext" == "jpg" || "$ext" == "jpeg" || "$ext" == "webp" || "$ext" == "gif" ]]
}

while IFS= read -r -d '' background_file; do
  name="$(basename "$background_file")"
  name="${name%.*}"

  if ! is_preview_source "$background_file"; then
    echo "skip $name: unsupported preview format" >&2
    continue
  fi

  "${magick_cmd[@]}" "$background_file" \
    -resize '1280x720^' \
    -gravity center \
    -extent 1280x720 \
    \( -size 410x720 xc:'rgba(33,34,44,0.30)' \) \
    -gravity center \
    -compose over \
    -composite \
    -fill 'rgba(0,0,0,0.24)' \
    -draw 'roundrectangle 430,252 850,468 20,20' \
    -fill '#f8f8f2' \
    -font DejaVu-Sans \
    -pointsize 30 \
    -gravity center \
    -annotate +0-36 "$name" \
    -pointsize 18 \
    -annotate +0+16 'SDDM theme preview' \
    "$preview_dir/$name.png"

  echo "$preview_dir/$name.png"
done < <(find "$repo_root/Backgrounds" -maxdepth 1 -type f -print0)
