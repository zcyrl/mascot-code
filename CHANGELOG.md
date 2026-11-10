# Changelog

All notable changes to Mascot Code are documented here.

## Unreleased

### Added

- iNiR 3 support. The overlay now installs as a local **component plugin**
  (`modules/mascot/plugin.json`) instead of replacing iNiR's mascot module, and
  iNiR's own companion keeps working beside it.
- `~/.config/mascot-code/config.json` holds the overlay's own `enable`,
  `character` and `peek` settings. iNiR 3 component plugins cannot add keys to
  iNiR's config schema, so the overlay no longer depends on one.
- The coding companion's IPC target is now `mascotcode`, leaving `mascot` to
  iNiR's own character.

### Fixed

- The mascot disappeared after an iNiR 3 update because the old
  `modules/mascot` module was removed. The installer detects iNiR 3, installs
  the component plugin, and registers it in `plugins.list`.
- The module no longer requires iNiR's `MascotRomp.qml`; desktop chaos belongs
  to iNiR's mascot, and the old peeking mode is opt-in (`peek`).
- The `/mascot` picker labels the Claude card correctly, fits the desktop
  dialog without clipping, and moves between cards with the arrow keys.
- The companion hides while OpenCode Desktop is focused, and its background
  server is no longer mistaken for a running TUI.
- The mascot disappears when the last OpenCode window closes, even if the
  desktop server or a terminal multiplexer pane outlives the window.

## v1.2.0 — 2026-11-06

The mascot picker.

### Added

- `/mascot` in the OpenCode TUI: a floating card with Empo and Claude. Hover a
  card to cycle its nine expressions every 1.4 seconds; click to choose.
- `/mascot` in OpenCode Desktop 2.2+ with the same cards and a native dialog.
- A shared selection file at `~/.config/mascot-code/character.json`. Both
  pickers write it, and the iNiR and standalone overlays read it first.
- `opencode/mascot/tui.tsx` and `opencode/mascot/gui-experimental.cjs`, plus
  generated data-URL artwork in `opencode/mascot/art.ts`.
- `scripts/generate-tui-assets.sh` and `scripts/build-tui-art.py` to rebuild
  the picker frames from the QML characters.

### Changed

- The OpenCode plugin is now a directory package:
  `~/.config/opencode/plugins/mascot/`. The old `mascot.ts` file is backed up
  and removed by the installers.
- Plugin id is now `zcyrl.mascot`.
- The iNiR `mascot character` IPC also updates the shared selection file.
- Installers create `~/.config/mascot-code/` and ship the TUI and CLI parts.

### Notes

- The desktop card requires OpenCode Desktop 2.2 or newer, which has the
  experimental GUI plugin API. OpenCode Desktop 2.1.x cannot load it; the TUI
  picker still works there.

## v1.1.0 — 2026-11-06

Claude joins the companion.

### Added

- **Claude**, a pixel-art QML interpretation of Anthropic's Claude Code crab:
  flat Claude-orange body, black eyes, claws and four legs, drawn on a fixed
  300x300 stage so the blocks stay crisp.
- Nine Claude expressions: idle, thinking, reading, coding, running, browsing,
  happy, sad and sleeping, with a page, keyboard, browser card, speed lines,
  sparkles, tear and `zZ`.
- Select a character at runtime with `inir ipc mascot character claude` (or
  `empo`). The older `clawd` spelling is still accepted.
- Standalone character selection with `MASCOT_CHARACTER=claude`. The systemd
  unit defaults to Empo.
- `scripts/capture-character-screenshots.sh`, which renders a character on a
  clean 1100x650 black stage for documentation and does not need niri or grim.
- Fresh black-background Claude screenshots in `assets/`.

### Changed

- `CharacterHost.qml` now has both built-in components.
- The standalone installer and release package ship both characters and the
  character `qmldir`.
- Documentation describes both characters and how to switch.

### Notes

- Claude is Anthropic's character. This is an unofficial fan interpretation, not
  affiliated with or endorsed by Anthropic. The GPL-3.0 license covers the QML
  code; the character and marks remain Anthropic's.

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
