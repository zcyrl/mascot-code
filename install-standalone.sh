#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${HOME}/.config/quickshell/mascot-code"
OC_PLUGIN_DIR="${HOME}/.config/opencode/plugins"
SERVICE_DIR="${HOME}/.config/systemd/user"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${HOME}/mascot-code-backup/${STAMP}"

mkdir -p "${TARGET}/characters" "${OC_PLUGIN_DIR}" "${SERVICE_DIR}" "${BACKUP}"
[ -d "${TARGET}" ] && cp -a "${TARGET}" "${BACKUP}/standalone"
[ -f "${OC_PLUGIN_DIR}/mascot.ts" ] && cp -a "${OC_PLUGIN_DIR}/mascot.ts" "${BACKUP}/mascot.ts"

cp "${ROOT}/standalone/shell.qml" "${TARGET}/shell.qml"
cp "${ROOT}/inir/modules/mascot/characters/Empo.qml" "${TARGET}/characters/Empo.qml"
cp "${ROOT}/opencode/mascot.ts" "${OC_PLUGIN_DIR}/mascot.ts"
cp "${ROOT}/packaging/systemd/mascot-code.service" "${SERVICE_DIR}/mascot-code.service"

echo "Installed the standalone Mascot Code overlay."
echo "Config: ${TARGET}/shell.qml"
echo "Backup: ${BACKUP}"
echo
echo "Start it for this session:"
echo "  qs -p ${TARGET}"
echo
echo "Or run it as a user service:"
echo "  systemctl --user daemon-reload"
echo "  systemctl --user enable --now mascot-code.service"
echo
echo "The standalone build works on any Wayland compositor with layer-shell"
echo "(niri, Hyprland, Sway, river, ...) and Quickshell. It shows while an"
echo "opencode TUI is running; focus-aware hiding is only in the iNiR build."
