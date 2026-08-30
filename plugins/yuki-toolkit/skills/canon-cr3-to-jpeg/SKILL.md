---
name: canon-cr3-to-jpeg
description: |
  Use when the user wants to batch-convert Canon raw files (CR3, also CR2) to
  JPEG while keeping the in-camera Canon rendering — Picture Style, white
  balance, lens correction — and the full EXIF / MakerNotes. The method is to
  extract the camera's own embedded full-size JPEG from each raw and copy the
  metadata back onto it, NOT to re-develop the raw. Triggers: "把 CR3 轉 jpg",
  "Canon raw 轉檔", "相機 raw 轉 jpg", "CR3 to JPEG", "convert CR3", "把單眼的
  照片轉成 jpg".
---

# Canon CR3 → JPEG (camera-matched)

Turns a folder of Canon `.CR3` files into `.jpg` that look exactly like what
the camera produced, with shooting parameters intact.

## Why this method

Every Canon CR3 embeds the camera's own full-resolution JPEG (`JpgFromRaw`),
rendered in-camera with the exact Picture Style, white balance, Auto Lighting
Optimizer, noise reduction, sharpening, and lens corrections that were active
at capture. Pulling that out is pixel-identical to having shot RAW+JPEG, and
it is the only scriptable way to match the camera.

The alternatives were tried and rejected:

- **`sips` / generic raw decoders** do a neutral demosaic — flat, wrong
  colour, no Canon look, and they drop all EXIF.
- **RawTherapee / darktable (CLI)** use their own colour science and will not
  reproduce a Canon Picture Style. RawTherapee 5.13's CLI also auto-applied a
  broken lens/distortion correction on the RF24-50mm F4.5-6.3 that left dark
  vignetted corners on every frame.
- **Canon DPP** is the only tool that both matches the camera and lets you
  re-develop (exposure, style, output size/quality). It is GUI-only, not
  scriptable. Point the user to it when they need *adjustable* output rather
  than the fixed camera JPEG.

## Prerequisites

`exiftool` must be installed:

```bash
exiftool -ver || brew install exiftool
```

## Steps

### 1. Sanity-check one raw file

```bash
exiftool -s -JpgFromRaw -PreviewImage -Model path/to/ONE.CR3
```

Confirm `JpgFromRaw` exists. Extract it once and check the resolution is the
full sensor size (e.g. 6000×4000 on an EOS R8):

```bash
exiftool -b -JpgFromRaw ONE.CR3 > /tmp/probe.jpg && sips -g pixelWidth -g pixelHeight /tmp/probe.jpg
```

`PreviewImage` is only ~1620×1080 — never use it for final output, only for
quick contact-sheet / culling needs.

### 2. Extract to a LOCAL staging folder

Never write straight to an SD card (see step 5). For each CR3:

```bash
exiftool -b -JpgFromRaw "$src" > "$stage/$base.jpg"
```

Reject any output whose width is below the expected sensor width — that means
the extract was truncated or the body doesn't embed a full-size JPEG.

### 3. Restore EXIF / MakerNotes

The extracted stream is a bare JPEG with no metadata block. Copy everything
from the raw back onto it:

```bash
exiftool -q -q -tagsFromFile "$src" -all:all -icc_profile \
  --IFD1:all -ThumbnailImage= -PreviewImage= \
  -overwrite_original "$stage/$base.jpg"
```

Do **not** exclude `Orientation` here — `JpgFromRaw` is stored the same way
the sensor read out and relies on the Orientation tag for portrait shots,
just like the raw. (This differs from a `sips` pipeline, where you rotate the
pixels yourself and must keep the JPEG's own Orientation.)

### 4. Verify the staging set

- File count equals the number of `.CR3` inputs.
- Every basename matches a source CR3.
- Every JPEG decodes: `sips -g pixelWidth "$f"` exits 0.
- Flag any file under ~200 KB — usually a truncated extract, though a
  genuinely dark frame can legitimately be ~1 MB.
- Spot-check EXIF on one: `exiftool -s -Model -LensModel -FNumber -ExposureTime -ISO -DateTimeOriginal "$f"`.

### 5. Copy to the destination

If the destination is a normal disk, `cp`/`rsync` then reconcile by name and
size.

**If the destination is an SD card / exFAT volume mounted by macOS `fskit`**
(macOS 15+; check `mount | grep <vol>` for `fskit`), be careful:

- Copy **sequentially**, `sync` every ~50 files.
- After copying, reconcile **every** file by byte size against staging and
  re-copy mismatches; repeat up to ~4 passes.
- Observed failure: 4-way parallel small-file writes to an `fskit` exFAT card
  silently dropped ~40% of files. `sips` and `cp` returned success, then the
  files vanished from the directory a few seconds later. Sequential + verify
  + retry held at zero loss.
- Afterwards remove macOS `._` AppleDouble sidecars:
  `find "$dst" -name '._*' -delete; dot_clean "$dst"`. They regenerate while
  the card stays mounted (Spotlight indexing) — harmless, the camera and
  photo apps ignore them.

Never overwrite the destination folder's contents until the local staging set
is fully verified.

### 6. Report

State: how many JPEGs landed, that names/sizes reconcile against the source
count, that samples decode at full resolution, and that EXIF is present on
the card copy (read it back from the destination, not from staging).

## Provided script

`scripts/cr3-to-jpeg.sh SRC_DIR DST_DIR [STAGE_DIR]` runs the whole flow:
parallel extract + EXIF onto a local staging dir, verification, then a
sequential verified copy to `DST_DIR` with size reconciliation and retries.
It is resumable — re-running skips staged files that already match.

```bash
plugins/yuki-toolkit/skills/canon-cr3-to-jpeg/scripts/cr3-to-jpeg.sh \
  /Volumes/EOS_DIGITAL/DCIM/100CANON \
  /Volumes/EOS_DIGITAL/2026-trip
```

## Notes

- Camera JPEG file size is fixed (the body's Fine-JPEG compression, ~2–7 MB
  for 24 MP). You cannot raise its quality — it is already a JPEG. If the
  user wants larger / higher-quality / adjustable output, that is a Canon DPP
  job, done by hand.
- Older `.CR2` files: many bodies also embed a `JpgFromRaw`; the same two
  steps work. Verify the embedded resolution first — some older bodies only
  embed a smaller preview.
