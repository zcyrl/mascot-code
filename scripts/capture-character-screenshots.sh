#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
#
# Render a character on a clean black stage and save every expression under
# assets/. No desktop, wallpaper, bar or grim needed.
#
# Usage:
#   ./scripts/capture-character-screenshots.sh [empo|claude]
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="${ROOT}/assets"
CHARACTER="$(printf '%s' "${1:-claude}" | tr '[:upper:]' '[:lower:]')"
# "clawd" is the spelling older docs used; keep accepting it.
case "${CHARACTER}" in
    clawd) CHARACTER="claude" ;;
esac
STATES=(idle thinking reading coding running browsing happy sad sleeping)

command -v qs >/dev/null || { echo "qs (Quickshell) is required" >&2; exit 1; }
command -v magick >/dev/null || { echo "ImageMagick (magick) is required" >&2; exit 1; }

TMP="$(mktemp -d "${TMPDIR:-/tmp}/mascot-shots.XXXXXX")"
cleanup() {
    rm -rf "${TMP}"
}
trap cleanup EXIT

ln -s "${ROOT}/inir/modules/mascot/characters" "${TMP}/characters"
cp "${ROOT}/scripts/screenshot-preview.qml" "${TMP}/shell.qml"
mkdir -p "${ASSETS}"

for state in "${STATES[@]}"; do
    raw="${TMP}/${state}.png"
    out="${ASSETS}/${CHARACTER}-${state}.png"
    MASCOT_CHARACTER="${CHARACTER}" \
    MASCOT_STATE="${state}" \
    MASCOT_OUT="${raw}" \
        timeout 15 qs -p "${TMP}" >"${TMP}/${state}.log" 2>&1 || true

    if [ ! -s "${raw}" ]; then
        echo "Could not render ${CHARACTER}/${state}; see ${TMP}/${state}.log" >&2
        exit 1
    fi

    magick "${raw}" -filter Lanczos -resize 1100x650! "${out}"
    printf '%s\n' "${out}"
done
