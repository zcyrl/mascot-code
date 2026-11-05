#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
set -euo pipefail

state="${1:-coding}"
detail="${2:-test.py}"

python3 - "$state" "$detail" <<'PY'
import json, sys, time
state, detail = sys.argv[1], sys.argv[2]
with open("/tmp/opencode-mascot.json", "w", encoding="utf-8") as fh:
    json.dump({"state": state, "detail": detail, "ts": int(time.time() * 1000)}, fh)
    fh.write("\n")
PY

printf 'wrote %s %s\n' "$state" "$detail"
