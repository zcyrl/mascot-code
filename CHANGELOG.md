# Changelog

All notable changes to Mascot Code are documented here.

## v1.0.0 — 2026-11-05

First public release.

### Added

- **Empo**, a glowing compass-star character drawn entirely in QML.
- Nine expressions: idle, thinking, reading, coding, running, browsing, happy,
  sad and sleeping.
- OpenCode V2 plugin that writes `/tmp/opencode-mascot.json` atomically.
- Per-session state tracking. The bubble follows the session selected in the
  OpenCode TUI; subagents and background sessions cannot hijack it.
- `thinking` now carries the previous action (`thinking after reading main.py`).
- 1.2-second hold on fast actions so reads and edits are visible.
- iNiR companion mode with:
  - bottom-right panel-sitter placement
  - existing speech bubble, size, slide and DND settings
  - hide while the OpenCode terminal is focused
  - show again when focus moves elsewhere
  - hide when OpenCode exits
- Standalone Quickshell overlay for other Wayland compositors.
- `CharacterHost.qml` switchboard and `characters/` contract for adding more
  characters.
- `install-inir.sh`, `install-standalone.sh`, systemd user service, state test
  helper, screenshot capture helper.
- GPL-3.0-only license with iNiR attribution.

### Changed

- Coding mode no longer depends on the optional iNiR anime art pack.
- Coding mode no longer uses random idle visits; it is driven by OpenCode.
- The stale-state fallback sleeps after 60 seconds even if OpenCode crashes.
- Malformed state JSON is ignored; the last good expression stays on screen.

### Notes

- Focus-aware hiding is niri + iNiR only. The standalone build shows while an
  `opencode` TUI is running.
- Tested on Arch Linux, niri 26.04, Quickshell 0.3.2 and OpenCode 2.2.5.
