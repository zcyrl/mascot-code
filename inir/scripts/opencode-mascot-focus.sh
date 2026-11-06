#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Softbrick (zcyrl)
# Report whether OpenCode is open and whether the focused Niri window is
# OpenCode itself.
#
# Output: none | focused | unfocused
#
# OpenCode can be a terminal TUI or the desktop app. "Open" means an OpenCode
# window exists, not just a process: the desktop app leaves its server behind,
# and terminal multiplexers keep panes alive after their windows close. A
# mascot for a session with no window is noise.
set -u

focused_pid="${1:-}"
focused_app="${2:-}"

# Only a terminal-hosted `opencode` is a TUI. Skip `opencode serve --service`,
# the desktop backend that stays alive after the app window closes.
tui_pids=""
for pid in $(pgrep -x opencode 2>/dev/null || true); do
    cmdline="$(tr '\0' ' ' 2>/dev/null < "/proc/$pid/cmdline" || true)"
    case " $cmdline " in
        *" serve "*) continue ;;
    esac
    tui_pids="$tui_pids $pid"
done

# Prefer Niri's window list over raw processes. A TUI counts only when its
# terminal window still exists (walking the process ancestry is enough for
# ordinary terminals), and the desktop app counts only when its window exists.
if command -v jq >/dev/null 2>&1 &&
   windows_json="$(niri msg --json windows 2>/dev/null)" &&
   windows="$(printf '%s' "$windows_json" |
       jq -r '.[] | [.pid, (.app_id // ""), ((.is_focused // false) | tostring)] | @tsv' 2>/dev/null)"; then

    running=false
    focused=false
    window_pids=""

    while IFS=$'\t' read -r pid app is_focused; do
        [ -n "${pid:-}" ] || continue
        window_pids="$window_pids $pid"
        app_lower="$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]')"
        case "$app_lower" in
            *opencode*desktop*|*desktop*opencode*)
                running=true
                [ "$is_focused" = "true" ] && focused=true
                ;;
        esac
    done <<< "$windows"

    # A terminal-hosted TUI is open when one of its ancestors is a window.
    # The same walk tells us whether the focused window is that terminal.
    for tui_pid in $tui_pids; do
        current="$tui_pid"
        has_window=false
        tui_focused=false
        while [ -n "$current" ] && [ "$current" -gt 1 ] 2>/dev/null; do
            if [ -n "$focused_pid" ] && [ "$current" = "$focused_pid" ]; then
                tui_focused=true
            fi
            case " $window_pids " in
                *" $current "*)
                    has_window=true
                    break
                    ;;
            esac
            current="$(ps -o ppid= -p "$current" 2>/dev/null | tr -d '[:space:]')"
        done
        if [ "$has_window" = "true" ]; then
            running=true
            [ "$tui_focused" = "true" ] && focused=true
        fi
    done

    if [ "$running" = "false" ]; then
        printf 'none\n'
    elif [ "$focused" = "true" ]; then
        printf 'focused\n'
    else
        printf 'unfocused\n'
    fi
    exit 0
fi

# No Niri (or no jq): fall back to process detection.
desktop_pids="$(pgrep -f 'opencode-desktop|ai\.opencode\.desktop' 2>/dev/null || true)"
if [ -z "${tui_pids// /}" ] && [ -z "$desktop_pids" ]; then
    printf 'none\n'
    exit 0
fi

# Niri reports ai.opencode.desktop. A focused Electron main process can also
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
