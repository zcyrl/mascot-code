#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
# Report whether OpenCode is running and whether the focused Niri window is
# OpenCode itself.
#
# Output: none | focused | unfocused
#
# OpenCode can run as a terminal TUI, as the desktop app, or both. The desktop
# app keeps an `opencode serve --service` process alive, so that process must
# not be mistaken for a TUI.
set -u

focused_pid="${1:-}"
focused_app="${2:-}"

# The desktop app runs Electron with app.asar on Arch, and an
# `opencode-desktop` binary in other packages. Renderer processes match too,
# which is enough to know the app is running.
desktop_pids="$(pgrep -f 'opencode-desktop|ai\.opencode\.desktop' 2>/dev/null || true)"

# Only a terminal-hosted `opencode` is a TUI. Skip the desktop backend.
tui_pids=""
for pid in $(pgrep -x opencode 2>/dev/null || true); do
    cmdline="$(tr '\0' ' ' 2>/dev/null < "/proc/$pid/cmdline" || true)"
    case " $cmdline " in
        *" serve "*) continue ;;
    esac
    tui_pids="$tui_pids $pid"
done

if [ -z "${tui_pids// /}" ] && [ -z "$desktop_pids" ]; then
    printf 'none\n'
    exit 0
fi

# niri reports ai.opencode.desktop. A focused Electron main process can also
# be identified by the app path in its command line.
focused_lower="$(printf '%s' "$focused_app" | tr '[:upper:]' '[:lower:]')"
case "$focused_lower" in
    *opencode*desktop*|*desktop*opencode*)
        printf 'focused\n'
        exit 0
        ;;
esac
if [ -n "$focused_pid" ] && [ "$focused_pid" -gt 0 ] 2>/dev/null; then
    focused_cmd="$(tr '\0' ' ' 2>/dev/null < "/proc/$focused_pid/cmdline" || true)"
    case "$focused_cmd" in
        *opencode-desktop*|*"/opencode-desktop/"*)
            printf 'focused\n'
            exit 0
            ;;
    esac
fi

# A TUI is focused when the focused window's PID is an ancestor of the
# `opencode` process, i.e. the terminal that owns the TUI is focused.
if [ -n "$focused_pid" ] && [ "$focused_pid" -gt 0 ] 2>/dev/null; then
    for pid in $tui_pids; do
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
