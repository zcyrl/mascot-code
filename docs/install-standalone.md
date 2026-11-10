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
- `characters/Empo.qml` and `characters/Claude.qml` →
  `~/.config/quickshell/mascot-code/characters/`
- `opencode/mascot/` → `~/.config/opencode/plugins/mascot/`
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

Select Claude with an environment override:

```bash
MASCOT_CHARACTER=claude qs -p ~/.config/quickshell/mascot-code
```

For the systemd service, put `Environment=MASCOT_CHARACTER=claude` in a drop-in
or edit the unit. The default is Empo.

The same choice is available visually: type `/mascot` in OpenCode. The picker
writes `~/.config/mascot-code/character.json`, which takes precedence over
`MASCOT_CHARACTER`. The standalone overlay watches that file and switches live.
The desktop card needs OpenCode Desktop 2.2+; the TUI card works on 2.x.

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
| theme | iNiR wallpaper palette | built-in Empo palette; Claude keeps Claude orange |
| character selection | `character` in `~/.config/mascot-code/config.json` (picker file wins) | `MASCOT_CHARACTER=empo` or `claude` |
| settings UI | iNiR Settings | none; env/file only |

The standalone is intentionally smaller. Focus-aware hiding would require a
different focus probe for every compositor, and that is not worth pretending to
support yet.

## Stop / uninstall

```bash
systemctl --user disable --now mascot-code.service
rm -rf ~/.config/quickshell/mascot-code
rm ~/.config/systemd/user/mascot-code.service
rm -rf ~/.config/opencode/plugins/mascot
systemctl --user daemon-reload
```
