# Mascot Code v1.1.0 — Clawd

Empo gets a neighbour: **Clawd**, the blocky orange crab from Claude Code, now
lives in Mascot Code too.

## What's in it

- **Clawd**, drawn entirely in QML on a 300x300 pixel-art stage: flat Claude
  orange body, short black eyes, blocky claws and four little legs.
- **All nine expressions**: idle, thinking, reading, coding, running, browsing,
  happy, sad and sleeping. He holds a page, types on a pixel keyboard, opens a
  browser card, scuttles with speed lines, sparkles when a session finishes,
  tears up when something fails, and sleeps with `zZ`.
- **Runtime character switch**:
  ```bash
  inir ipc mascot character clawd
  inir ipc mascot character empo
  ```
  `claude` is accepted as an alias.
- **Standalone support**: `MASCOT_CHARACTER=clawd qs -p ~/.config/quickshell/mascot-code`.
  The systemd unit still defaults to Empo.
- **Clean screenshots**: the new capture helper renders each state on a
  1100x650 black stage, no desktop, bar or wallpaper in frame.
- The same state file, plugin, per-session tracking, focus hiding and 60-second
  sleep fallback from v1.0.0.

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

- `Mascot-Code-1.1.0-inir.tar.gz` — iNiR module, plugin, focus script, Empo,
  Clawd, installers and docs.
- `Mascot-Code-1.1.0-standalone.tar.gz` — ready-to-use standalone Quickshell
  config with both characters, plugin and systemd unit.

## Thanks

Clawd is Anthropic's character for Claude Code. This release is an unofficial
fan interpretation and is not affiliated with or endorsed by Anthropic. The
code stays GPL-3.0-only; the character and marks remain Anthropic's.

## License

GPL-3.0-only. Keep the license, keep the notices, and credit Softbrick (zcyrl)
and the iNiR authors.
