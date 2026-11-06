#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
#
# Render the 9 expressions of both characters as transparent PNG frames for
# the /mascot TUI picker. Requires Quickshell and ImageMagick.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${ROOT}/opencode/mascot/assets"
STATES=(idle thinking reading coding running browsing happy sad sleeping)
CHARACTERS=(empo clawd)

command -v qs >/dev/null || { echo "qs (Quickshell) is required" >&2; exit 1; }
command -v magick >/dev/null || { echo "ImageMagick (magick) is required" >&2; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/mascot-frames.XXXXXX")"
trap 'rm -rf "${TMP}"' EXIT
ln -s "${ROOT}/inir/modules/mascot/characters" "${TMP}/characters"
cp "${ROOT}/scripts/tui-mascot-frame.qml" "${TMP}/shell.qml"
mkdir -p "${OUT}"

for character in "${CHARACTERS[@]}"; do
    for state in "${STATES[@]}"; do
        raw="${TMP}/${character}-${state}.png"
        final="${OUT}/${character}-${state}.png"
        MASCOT_CHARACTER="${character}" \
        MASCOT_STATE="${state}" \
        MASCOT_OUT="${raw}" \
            timeout 15 qs -p "${TMP}" >"${TMP}/${character}-${state}.log" 2>&1 || true

        if [ ! -s "${raw}" ]; then
            echo "Could not render ${character}/${state}; see ${TMP}/${character}-${state}.log" >&2
            exit 1
        fi

        magick "${raw}" -resize 340x340 \
            -fuzz 2% -trim +repage \
            -filter Lanczos -resize 280x280 \
            -gravity center -background none -extent 300x300 \
            -resize 240x240 -colors 64 -strip "PNG8:${final}"
        printf '%s\n' "${final}"
    done
done

python3 "${ROOT}/scripts/build-tui-art.py" "${OUT}" "${ROOT}/opencode/mascot/art.ts"
