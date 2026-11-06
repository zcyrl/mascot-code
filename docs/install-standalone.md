# Standalone install

This build is for any Wayland compositor with layer-shell support: Hyprland,
Sway, river, niri without iNiR, and anything else Quickshell can talk to.

It does not use niri and it does not hide while the OpenCode terminal is
focused. It shows while an `opencode` TUI process is running.

## Install

```bash
./install-standalone.sh
```

That copies:

- `standalone/shell.qml` → `~/.config/quickshell/mascot-code/shell.qml`
- `characters/Empo.qml` and `characters/Clawd.qml` →
  `~/.config/quickshell/mascot-code/characters/`
- `opencode/mascot.ts` → `~/.config/opencode/plugins/mascot.ts`
- the user service → `~/.config/systemd/user/mascot-code.service`

Start it:

```bash
systemctl --user daemon-reload
systemctl --user enable --now mascot-code.service
```

Or run it directly:

```bash
qs -p ~/.config/quickshell/mascot-code
```

Select Clawd with an environment override:

```bash
MASCOT_CHARACTER=clawd qs -p ~/.config/quickshell/mascot-code
```

For the systemd service, put `Environment=MASCOT_CHARACTER=clawd` in a drop-in
or edit the unit. The default is Empo.

## Requirements

- OpenCode 2.x
- Quickshell 0.3+
- a Wayland compositor with layer-shell
- `pgrep` from `procps`

No `inotifywait` required. The standalone build re-reads the small state file
once a second.

## What is different from iNiR

| | iNiR build | standalone |
| --- | --- | --- |
| transparent overlay | yes | yes |
| per-session state | yes | yes (latest active session) |
| hide while OpenCode focused | yes, via niri | no |
| hide when OpenCode exits | yes | yes |
| inotify state updates | yes | 1 Hz `cat` |
| theme | iNiR wallpaper palette | built-in Empo palette; Clawd keeps Claude orange |
| character selection | `mascot.codingCompanion.character` | `MASCOT_CHARACTER=empo` or `clawd` |
| settings UI | iNiR Settings | none; env/file only |

The standalone is intentionally smaller. Focus-aware hiding would require a
different focus probe for every compositor, and that is not worth pretending to
support yet.

## Stop / uninstall

```bash
systemctl --user disable --now mascot-code.service
rm -rf ~/.config/quickshell/mascot-code
rm ~/.config/systemd/user/mascot-code.service
rm ~/.config/opencode/plugins/mascot.ts
systemctl --user daemon-reload
```
