#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="${ROOT}/assets"

OPENCODE_ID="$(niri msg --json windows | python3 -c 'import sys,json; print(next((str(w["id"]) for w in json.load(sys.stdin) if w.get("app_id")=="kitty" and "OC |" in (w.get("title") or "")), ""))')"
ZEN_ID="$(niri msg --json windows | python3 -c 'import sys,json; print(next((str(w["id"]) for w in json.load(sys.stdin) if w.get("app_id")=="zen"), ""))')"

if [ -z "$OPENCODE_ID" ] || [ -z "$ZEN_ID" ]; then
    echo "Could not find the OpenCode kitty window and a Zen window." >&2
    exit 1
fi

sleep 1
niri msg action focus-window --id "$ZEN_ID" >/dev/null

shot() {
    local state="$1" detail="$2"
    python3 - "$state" "$detail" <<'PY'
import json, sys, time
state, detail = sys.argv[1], sys.argv[2]
with open("/tmp/opencode-mascot.json", "w", encoding="utf-8") as fh:
    json.dump({"state": state, "detail": detail, "ts": int(time.time() * 1000)}, fh)
    fh.write("\n")
PY
    sleep 1.6
    grim -o eDP-1 /tmp/mascot-shot.png
    magick /tmp/mascot-shot.png -crop 560x420+1360+660 +repage "${ASSETS}/empo-${state}.png"
    echo "${ASSETS}/empo-${state}.png"
}

shot thinking "after reading main.py"
shot reading "main.py"
shot coding "test.py"
shot browsing "docs.opencode.ai"
shot happy "done!"
shot sad "tool failed"
shot sleeping ""

niri msg action focus-window --id "$OPENCODE_ID" >/dev/null
