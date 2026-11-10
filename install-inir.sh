#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INIR="${HOME}/.config/quickshell/inir"
OC_PLUGIN_DIR="${HOME}/.config/opencode/plugins"
MASCOT_CONFIG_DIR="${HOME}/.config/mascot-code"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="${HOME}/mascot-code-backup/${STAMP}"

if [ ! -d "${INIR}/modules/common" ]; then
    echo "iNiR was not found at ${INIR}" >&2
    echo "This installer is for the iNiR integration. Use install-standalone.sh for other Wayland setups." >&2
    exit 1
fi

# iNiR 3 moved the mascot to modules/shared and loads local additions as
# component plugins. iNiR 2 loaded modules/mascot directly.
MODERN_INIR=0
if [ -d "${INIR}/modules/shared/mascot" ] || [ ! -d "${INIR}/modules/mascot" ]; then
    MODERN_INIR=1
fi

mkdir -p "${BACKUP}" "${OC_PLUGIN_DIR}" "${INIR}/scripts" "${MASCOT_CONFIG_DIR}"
[ -d "${INIR}/modules/mascot" ] && cp -a "${INIR}/modules/mascot" "${BACKUP}/mascot" 2>/dev/null || true
cp -a "${INIR}/scripts/opencode-mascot-focus.sh" "${BACKUP}/opencode-mascot-focus.sh" 2>/dev/null || true
[ -f "${HOME}/.config/inir/config.json" ] && cp -a "${HOME}/.config/inir/config.json" "${BACKUP}/config.json"
[ -f "${OC_PLUGIN_DIR}/mascot.ts" ] && cp -a "${OC_PLUGIN_DIR}/mascot.ts" "${BACKUP}/mascot.ts"
[ -d "${OC_PLUGIN_DIR}/mascot" ] && cp -a "${OC_PLUGIN_DIR}/mascot" "${BACKUP}/mascot-plugin"

rm -f "${OC_PLUGIN_DIR}/mascot.ts"
rm -rf "${OC_PLUGIN_DIR}/mascot"

mkdir -p "${INIR}/modules/mascot"
cp -a "${ROOT}/opencode/mascot" "${OC_PLUGIN_DIR}/mascot"
cp -a "${ROOT}/inir/modules/mascot/." "${INIR}/modules/mascot/"
# The character was renamed from Clawd.qml. Leave no stale component behind.
rm -f "${INIR}/modules/mascot/characters/Clawd.qml"
cp "${ROOT}/inir/scripts/opencode-mascot-focus.sh" "${INIR}/scripts/opencode-mascot-focus.sh"
chmod +x "${INIR}/scripts/opencode-mascot-focus.sh"

# Mascot Code's own settings. character.json still wins for the drawing.
python3 - "${MASCOT_CONFIG_DIR}/config.json" "${MODERN_INIR}" <<'PY'
import json, os, sys
path, modern = sys.argv[1], sys.argv[2] == "1"
data = {}
if os.path.exists(path):
    try:
        with open(path, encoding="utf-8") as fh:
            loaded = json.load(fh)
        if isinstance(loaded, dict):
            data = loaded
    except (OSError, ValueError):
        data = {}
data.setdefault("enable", True)
data.setdefault("character", "empo")
# iNiR 3 ships its own companion; don't draw a second peeking mascot.
data.setdefault("peek", not modern)
with open(path, "w", encoding="utf-8") as fh:
    json.dump(data, fh, indent=2, ensure_ascii=False)
    fh.write("\n")
PY

if [ "${MODERN_INIR}" = "1" ]; then
    PLUGINS="${INIR}/plugins.list"
    grep -qxF "mascot" "${PLUGINS}" 2>/dev/null || echo "mascot" >> "${PLUGINS}"
else
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
fi

echo "Installed Mascot Code into iNiR."
echo "Backup: ${BACKUP}"
echo
if [ "${MODERN_INIR}" = "0" ]; then
    if grep -q "codingCompanion" "${INIR}/modules/common/Config.qml" 2>/dev/null; then
        echo "Config schema already contains codingCompanion."
    else
        echo "ACTION REQUIRED: add the schema block from inir/config/Config-schema.qml"
        echo "to the mascot JsonObject in ${INIR}/modules/common/Config.qml."
        echo "Without it, the Config adapter will not expose the new keys."
    fi
    echo
fi
echo "Then run:"
echo "  inir restart"
echo "  inir ipc mascotcode status"
