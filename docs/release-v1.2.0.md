# Mascot Code v1.2.0 — Choose your mascot

Mascot Code now has a picker. Type `/mascot` in OpenCode and choose between
**Empo** and **Claude** without editing config by hand.

## What's in it

- **`/mascot` in the TUI**: a floating card with Empo and Claude. Hover either
  mascot to cycle all nine expressions every 1.4 seconds, then click or press
  Enter to choose.
- **`/mascot` in OpenCode Desktop 2.2+**: the same picker as a native desktop
  dialog, with the same hover previews.
- **One shared choice**: both pickers write
  `~/.config/mascot-code/character.json`. The iNiR and standalone overlays
  read that file first, so the desktop mascot switches immediately.
- **`inir ipc mascot character` also updates the shared file**, so all three
  ways to switch stay in sync.
- **One plugin package with three parts**:
  - `index.ts` — the OpenCode state plugin
  - `tui.tsx` — the terminal picker
  - `gui-experimental.cjs` — the desktop picker
- **Generated picker artwork** from the real QML characters, with an
  `inir restart` applying the new overlay module.

## Install

The plugin is now a directory package:

```bash
mkdir -p ~/.config/opencode/plugins
cp -a opencode/mascot ~/.config/opencode/plugins/mascot
opencode plugin list
```

`opencode plugin list` should show `zcyrl.mascot`.

Then install the overlay:

```bash
./install-inir.sh
# or
./install-standalone.sh
```

After an iNiR install, run:

```bash
inir restart
```

The old single-file `~/.config/opencode/plugins/mascot.ts` is backed up and
removed by the installer.

## Requirements

- OpenCode 2.x (tested on 2.2.5)
- OpenCode Desktop 2.2+ for the desktop picker (the GUI plugin API is
  experimental and not available in 2.1.x)
- Quickshell 0.3+ (tested on 0.3.2)
- Wayland compositor with layer-shell
- niri + iNiR for focus-aware hiding
- `inotify-tools` and `procps` for the iNiR build
- `procps` for the standalone build

## Release assets

- `Mascot-Code-1.2.0-inir.tar.gz` — iNiR module, the three-part OpenCode
  plugin, both characters, installers and docs.
- `Mascot-Code-1.2.0-standalone.tar.gz` — standalone Quickshell config, both
  characters and the same OpenCode plugin package.

## Notes

- The desktop `/mascot` card uses the experimental GUI plugin API introduced in
  OpenCode Desktop 2.2. The TUI picker works on OpenCode 2.x regardless.
- Claude is Anthropic's mascot. This is an unofficial fan interpretation; the
  code is GPL-3.0-only and the character marks remain Anthropic's.
- If the iNiR choice does not change after picking, run `inir restart` once to
  load the updated module, then select again.
