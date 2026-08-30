#!/bin/bash
# Canon CR3 -> JPEG, camera-matched.
#
# Extracts each raw's embedded full-size camera JPEG (JpgFromRaw) so the
# output keeps the in-camera Picture Style / white balance / lens correction,
# then copies the EXIF + MakerNotes from the raw back onto it. Stages on a
# local disk first, verifies, then does a sequential verified copy to the
# destination (safe for macOS fskit exFAT SD cards, which drop files under
# parallel small-file writes).
#
# Usage:  cr3-to-jpeg.sh SRC_DIR DST_DIR [STAGE_DIR]
#   SRC_DIR    folder containing .CR3 (or .CR2) files
#   DST_DIR    where the .jpg files should end up (created if missing)
#   STAGE_DIR  local scratch dir (default: a mktemp dir); kept on failure
#
# Requires: exiftool, sips (macOS).

set -u

SRC="${1:?usage: cr3-to-jpeg.sh SRC_DIR DST_DIR [STAGE_DIR]}"
DST="${2:?usage: cr3-to-jpeg.sh SRC_DIR DST_DIR [STAGE_DIR]}"
STAGE="${3:-$(mktemp -d "${TMPDIR:-/tmp}/cr3jpg.XXXXXX")}"
PARALLEL="${CR3_PARALLEL:-4}"
MIN_WIDTH="${CR3_MIN_WIDTH:-4000}"   # reject extracts narrower than this

command -v exiftool >/dev/null || { echo "exiftool not found (brew install exiftool)"; exit 1; }
command -v sips     >/dev/null || { echo "sips not found (macOS only)"; exit 1; }
[ -d "$SRC" ] || { echo "SRC_DIR not a directory: $SRC"; exit 1; }
mkdir -p "$DST" "$STAGE"

echo "SRC   : $SRC"
echo "DST   : $DST"
echo "STAGE : $STAGE"

# ---------------------------------------------------------------------------
# 1 + 2. extract JpgFromRaw + restore metadata, onto the local staging dir
# ---------------------------------------------------------------------------
one() {
  src="$1"
  base="$(basename "${src%.*}")"
  out="$STAGE/$base.jpg"

  if [ ! -s "$out" ]; then
    exiftool -b -JpgFromRaw "$src" > "$out" 2>/dev/null
  fi
  w=$(sips -g pixelWidth "$out" 2>/dev/null | awk '/pixelWidth/{print $2}')
  if [ "${w:-0}" -lt "$MIN_WIDTH" ]; then
    echo "FAIL extract $base (width=${w:-none})"
    rm -f "$out"
    return
  fi
  # Keep Orientation: JpgFromRaw relies on it for portrait shots, same as the raw.
  if exiftool -q -q -tagsFromFile "$src" -all:all -icc_profile \
       --IFD1:all -ThumbnailImage= -PreviewImage= \
       -overwrite_original "$out" >/dev/null 2>&1; then
    echo "OK $base"
  else
    echo "EXIF-FAIL $base"
  fi
}
export -f one
export STAGE MIN_WIDTH

mapfile -t raws < <(find "$SRC" -maxdepth 1 -type f \( -iname '*.CR3' -o -iname '*.CR2' \) | sort)
total=${#raws[@]}
[ "$total" -gt 0 ] || { echo "no .CR3/.CR2 files in $SRC"; exit 1; }
echo "found $total raw files; extracting with -P $PARALLEL ..."

printf '%s\0' "${raws[@]}" \
  | xargs -0 -P "$PARALLEL" -I {} bash -c 'one "$@"' _ {}

# ---------------------------------------------------------------------------
# 3. verify the staging set
# ---------------------------------------------------------------------------
staged=$(find "$STAGE" -maxdepth 1 -type f -iname '*.jpg' | wc -l | tr -d ' ')
echo "staged $staged / $total"
if [ "$staged" -ne "$total" ]; then
  echo "ABORT: staging incomplete. STAGE kept at: $STAGE"
  exit 1
fi
bad=0
while IFS= read -r f; do
  sz=$(stat -f '%z' "$f" 2>/dev/null || stat -c '%s' "$f")
  if ! sips -g pixelWidth "$f" >/dev/null 2>&1; then
    echo "BAD (no decode): $(basename "$f")"; bad=$((bad+1))
  elif [ "$sz" -lt 204800 ]; then
    echo "WARN (small, ${sz}B, check it): $(basename "$f")"
  fi
done < <(find "$STAGE" -maxdepth 1 -type f -iname '*.jpg')
[ "$bad" -eq 0 ] || { echo "ABORT: $bad undecodable files. STAGE kept at: $STAGE"; exit 1; }
echo "staging verified."

# ---------------------------------------------------------------------------
# 4. sequential verified copy to the destination, with retries
#    (safe for macOS fskit exFAT cards)
# ---------------------------------------------------------------------------
is_fskit=$(mount | grep -F " $DST " 2>/dev/null | grep -c fskit || true)
[ "$is_fskit" != "0" ] && echo "note: destination looks like an fskit volume; using sequential + retry."

rm -f "$DST"/*.jpg "$DST"/._*.jpg 2>/dev/null
mkdir -p "$DST"; sync

pass=0
while [ "$pass" -lt 4 ]; do
  pass=$((pass+1))
  copied=0
  for f in "$STAGE"/*.jpg; do
    b=$(basename "$f")
    s1=$(stat -f '%z' "$f" 2>/dev/null || stat -c '%s' "$f")
    if [ -f "$DST/$b" ]; then
      s2=$(stat -f '%z' "$DST/$b" 2>/dev/null || stat -c '%s' "$DST/$b" 2>/dev/null || echo 0)
      [ "$s1" = "$s2" ] && continue
    fi
    cp -f "$f" "$DST/$b"
    copied=$((copied+1))
    [ $((copied % 50)) -eq 0 ] && sync
  done
  sync; sleep 2
  miss=0
  for f in "$STAGE"/*.jpg; do
    b=$(basename "$f")
    s1=$(stat -f '%z' "$f" 2>/dev/null || stat -c '%s' "$f")
    s2=$(stat -f '%z' "$DST/$b" 2>/dev/null || stat -c '%s' "$DST/$b" 2>/dev/null || echo 0)
    [ "$s1" != "$s2" ] && miss=$((miss+1))
  done
  echo "pass $pass: copied $copied, still mismatched $miss"
  [ "$miss" -eq 0 ] && break
done

# strip macOS AppleDouble sidecars the copy created on exFAT
find "$DST" -maxdepth 1 -name '._*' -delete 2>/dev/null
command -v dot_clean >/dev/null && dot_clean "$DST" 2>/dev/null
sync

# ---------------------------------------------------------------------------
# 5. final reconcile
# ---------------------------------------------------------------------------
oncard=$(find "$DST" -maxdepth 1 -type f -iname '*.jpg' ! -name '._*' | wc -l | tr -d ' ')
final_bad=0
for f in "$STAGE"/*.jpg; do
  b=$(basename "$f")
  s1=$(stat -f '%z' "$f" 2>/dev/null || stat -c '%s' "$f")
  s2=$(stat -f '%z' "$DST/$b" 2>/dev/null || stat -c '%s' "$DST/$b" 2>/dev/null || echo MISSING)
  [ "$s1" != "$s2" ] && { echo "MISMATCH: $b staged=$s1 dst=$s2"; final_bad=$((final_bad+1)); }
done

echo "=== DONE: $oncard / $total jpg in $DST, $final_bad mismatched ==="
if [ "$final_bad" -eq 0 ]; then
  echo "staging dir can be removed: rm -rf \"$STAGE\""
  exit 0
else
  echo "staging kept for retry: $STAGE"
  exit 1
fi
