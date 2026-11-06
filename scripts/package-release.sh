#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-1.2.0}"
DIST="${ROOT}/dist"
STAGE="${DIST}/stage"

rm -rf "${DIST}"
mkdir -p "${DIST}" "${STAGE}"

# ── iNiR package ────────────────────────────────────────────────────────────
INIR="${STAGE}/Mascot-Code-${VERSION}-inir"
mkdir -p "${INIR}"
cp -a "${ROOT}/opencode" "${INIR}/"
cp -a "${ROOT}/inir" "${INIR}/"
cp "${ROOT}/install-inir.sh" "${INIR}/"
cp "${ROOT}/README.md" "${ROOT}/LICENSE" "${ROOT}/NOTICE" "${INIR}/"
mkdir -p "${INIR}/docs"
cp "${ROOT}/docs/install-inir.md" "${ROOT}/docs/architecture.md" \
   "${ROOT}/docs/states.md" "${ROOT}/docs/troubleshooting.md" "${INIR}/docs/"
tar -C "${STAGE}" -czf "${DIST}/Mascot-Code-${VERSION}-inir.tar.gz" "Mascot-Code-${VERSION}-inir"

# ── Standalone package ──────────────────────────────────────────────────────
STANDALONE="${STAGE}/Mascot-Code-${VERSION}-standalone"
mkdir -p "${STANDALONE}/characters" "${STANDALONE}/mascot"
cp "${ROOT}/standalone/shell.qml" "${STANDALONE}/shell.qml"
cp "${ROOT}/inir/modules/mascot/characters/Empo.qml" "${STANDALONE}/characters/Empo.qml"
cp "${ROOT}/inir/modules/mascot/characters/Clawd.qml" "${STANDALONE}/characters/Clawd.qml"
cp "${ROOT}/inir/modules/mascot/characters/qmldir" "${STANDALONE}/characters/qmldir"
cp -a "${ROOT}/opencode/mascot/." "${STANDALONE}/mascot/"
cp "${ROOT}/packaging/systemd/mascot-code.service" "${STANDALONE}/"
cp "${ROOT}/LICENSE" "${ROOT}/NOTICE" "${STANDALONE}/"
cat > "${STANDALONE}/README.md" <<'EOF'
# Mascot Code — standalone

1. Copy this directory to `~/.config/quickshell/mascot-code`.
2. Copy `mascot/` to `~/.config/opencode/plugins/mascot/`.
3. Copy `mascot-code.service` to `~/.config/systemd/user/`.
4. Run:

   systemctl --user daemon-reload
   systemctl --user enable --now mascot-code.service

Or run it directly:

   qs -p ~/.config/quickshell/mascot-code

This build shows Empo or Clawd while an `opencode` TUI is running. Pick one
with MASCOT_CHARACTER=empo (default) or MASCOT_CHARACTER=clawd. Focus-aware
hiding is only in the iNiR build. See the main README for the state file and
test commands.
EOF
tar -C "${STAGE}" -czf "${DIST}/Mascot-Code-${VERSION}-standalone.tar.gz" "Mascot-Code-${VERSION}-standalone"

rm -rf "${STAGE}"
ls -lh "${DIST}"
