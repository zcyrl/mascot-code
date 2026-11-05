#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
# Report whether a terminal-hosted OpenCode TUI is running and whether the
# currently focused Niri window is its terminal.
#
# Output: none | focused | unfocused
#
# "focused" means the focused window's PID is an ancestor of an `opencode`
# process, i.e. the terminal that owns the TUI is the focused window.
set -u

focused_pid="${1:-}"

opencode_pids="$(pgrep -x opencode 2>/dev/null || true)"
if [ -z "$opencode_pids" ]; then
    printf 'none\n'
    exit 0
fi

if [ -n "$focused_pid" ] && [ "$focused_pid" -gt 0 ] 2>/dev/null; then
    for pid in $opencode_pids; do
        current="$pid"
        while [ -n "$current" ] && [ "$current" -gt 1 ] 2>/dev/null; do
            if [ "$current" = "$focused_pid" ]; then
                printf 'focused\n'
                exit 0
            fi
            current="$(ps -o ppid= -p "$current" 2>/dev/null | tr -d '[:space:]')"
        done
    done
fi

printf 'unfocused\n'
