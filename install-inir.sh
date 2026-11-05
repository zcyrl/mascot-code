#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INIR="${HOME}/.config/quickshell/inir"
OC_PLUGIN_DIR="${HOME}/.config/opencode/plugins"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${HOME}/mascot-code-backup/${STAMP}"

if [ ! -d "${INIR}/modules/mascot" ]; then
    echo "iNiR was not found at ${INIR}" >&2
    echo "This installer is for the iNiR integration. Use install-standalone.sh for other Wayland setups." >&2
    exit 1
fi

mkdir -p "${BACKUP}" "${OC_PLUGIN_DIR}" "${INIR}/scripts"
cp -a "${INIR}/modules/mascot" "${BACKUP}/mascot"
cp -a "${INIR}/scripts/opencode-mascot-focus.sh" "${BACKUP}/opencode-mascot-focus.sh" 2>/dev/null || true
[ -f "${HOME}/.config/inir/config.json" ] && cp -a "${HOME}/.config/inir/config.json" "${BACKUP}/config.json"

cp "${ROOT}/opencode/mascot.ts" "${OC_PLUGIN_DIR}/mascot.ts"
cp -a "${ROOT}/inir/modules/mascot/." "${INIR}/modules/mascot/"
cp "${ROOT}/inir/scripts/opencode-mascot-focus.sh" "${INIR}/scripts/opencode-mascot-focus.sh"
chmod +x "${INIR}/scripts/opencode-mascot-focus.sh"

CONFIG="${HOME}/.config/inir/config.json"
if [ -f "${CONFIG}" ]; then
    python3 - "${CONFIG}" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
mascot = data.setdefault("mascot", {})
coding = mascot.setdefault("codingCompanion", {})
coding.setdefault("enable", True)
coding.setdefault("character", "empo")
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=4, ensure_ascii=False)
    fh.write("\n")
PY
fi

echo "Installed Mascot Code into iNiR."
echo "Backup: ${BACKUP}"
echo
if grep -q "codingCompanion" "${INIR}/modules/common/Config.qml" 2>/dev/null; then
    echo "Config schema already contains codingCompanion."
else
    echo "ACTION REQUIRED: add the schema block from inir/config/Config-schema.qml"
    echo "to the mascot JsonObject in ${INIR}/modules/common/Config.qml."
    echo "Without it, the Config adapter will not expose the new keys."
fi
echo
echo "Then run:"
echo "  inir restart"
echo "  inir ipc mascot coding true"
echo "  inir ipc mascot status"
