# Mascot Code v1.0.0 — Empo

The first public release of Mascot Code: a small desktop mascot for OpenCode.

## What's in it

- **Empo**, a glowing compass-star drawn entirely in QML. Nine expressions:
  idle, thinking, reading, coding, running, browsing, happy, sad and sleeping.
- **OpenCode V2 plugin** with atomic state writes to
  `/tmp/opencode-mascot.json`.
- **Per-session state**. The bubble follows the session selected in the
  OpenCode TUI; subagents and background sessions don't hijack it.
- **`thinking after reading main.py`** instead of a generic `thinking`.
  Fast reads and edits stay on screen for about 1.2 seconds.
- **iNiR companion mode** for niri:
  - bottom-right layer-shell overlay
  - existing iNiR speech bubble, size, slide and DND settings
  - hides while the OpenCode terminal is focused
  - reappears when focus moves elsewhere
  - hides when OpenCode exits
- **Standalone Quickshell overlay** for other Wayland compositors. Shows while
  an `opencode` TUI is running. No niri required.
- **CharacterHost / characters/** so more characters and animations can be
  added without touching the companion.
- Installers, systemd user service, state test helper and screenshot helper.
- GPL-3.0-only license with iNiR attribution.

## Install

Plugin first:

```bash
git clone https://github.com/zcyrl/mascot-code.git
cd mascot-code
cp opencode/mascot.ts ~/.config/opencode/plugins/mascot.ts
opencode plugin list
```

Then pick one:

```bash
./install-inir.sh
# or
./install-standalone.sh
```

Full instructions are in the README.

## Requirements

- OpenCode 2.x (tested on 2.2.5)
- Quickshell 0.3+ (tested on 0.3.2)
- Wayland compositor with layer-shell
- niri + iNiR for focus-aware hiding
- `inotify-tools` and `procps` for the iNiR build
- `procps` for the standalone build

## Release assets

- `Mascot-Code-1.0.0-inir.tar.gz` — iNiR module, plugin, focus script, installers and docs.
- `Mascot-Code-1.0.0-standalone.tar.gz` — ready-to-use standalone Quickshell config, Empo, plugin and systemd unit.

## License

GPL-3.0-only. Keep the license, keep the notices, and credit Softbrick (zcyrl)
and the iNiR authors.
