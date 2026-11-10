# iNiR install

This is the Arch + niri + [iNiR](https://github.com/snowarch/iNiR) build. It
draws the coding companion on top of iNiR, and uses niri to hide the mascot
while an OpenCode window is focused. It also hides the mascot once no OpenCode
window is open, even if a background server or terminal pane is still running.

Either Empo or Claude can be selected; the default is Empo. Type `/mascot` in OpenCode (TUI or Desktop 2.2+) for the visual picker.

## 1. Install the plugin

```bash
mkdir -p ~/.config/opencode/plugins
cp -a opencode/mascot ~/.config/opencode/plugins/mascot
opencode plugin list
```

Confirm `zcyrl.mascot` is listed before continuing.

## 2. Run the installer

```bash
./install-inir.sh
```

The installer creates a timestamped backup under `~/mascot-code-backup/`. It
copies the module, focus script and plugin, then creates
`~/.config/mascot-code/config.json`:

```json
{
  "enable": true,
  "character": "empo",
  "peek": false
}
```

`peek` is for iNiR 2's edge-peeking behaviour. iNiR 3 has its own companion, so
the installer leaves this off there and Mascot Code only draws while OpenCode is
running.

## 3. Restart

```bash
inir restart
inir ipc mascotcode status
```

Expected fields:

```json
{
  "enabled": true,
  "showing": true,
  "coding": {
    "enabled": true,
    "active": true,
    "openCodeRunning": true,
    "openCodeFocused": false
  }
}
```

Focus the OpenCode terminal and `showing` should become `false`. Focus another
window and it should become `true` again.

## iNiR 3: a component plugin

iNiR 3 loads families from plugins and lets a local plugin add its own surface
through `plugin.json`:

```json
{
  "id": "mascot",
  "kind": "component",
  "parts": { "panel": "MascotCompanion.qml" }
}
```

The installer copies that file to
`~/.config/quickshell/inir/modules/mascot/` and adds `mascot` to
`~/.config/quickshell/inir/plugins.list`. Nothing in iNiR's own modules is
patched, and the coding companion sits beside iNiR's mascot instead of replacing
it. Its IPC target is `mascotcode`, so iNiR keeps `mascot` for its own character.

An iNiR update may remove local folders under `modules/`. Re-run
`./install-inir.sh` and `inir restart` after a shell update.

## iNiR 2: patch the config schema

On iNiR 2, `Config.qml` does not know the coding keys. Add the block from
[`../inir/config/Config-schema.qml`](../inir/config/Config-schema.qml) inside the
`mascot` JsonObject in:

```text
~/.config/quickshell/inir/modules/common/Config.qml
```

The installer also adds `mascot.codingCompanion` to
`~/.config/inir/config.json`.

## Settings and IPC

The settings file is the source of truth on iNiR 3:

```json
{
  "enable": true,
  "character": "empo",
  "peek": false
}
```

The `/mascot` picker writes `~/.config/mascot-code/character.json`. That shared
file wins over the settings file, so the picker switches the overlay without
opening Settings. The IPC commands write both:

```bash
inir ipc mascotcode coding true
inir ipc mascotcode character claude
# or
inir ipc mascotcode character empo
inir ipc mascotcode status
```

`peek: true` restores iNiR 2's original edge-peeking companion. On iNiR 3 leave
it `false`; iNiR's own mascot already does that job.

The optional Settings switch (iNiR 2) is described in
[`../inir/config/README.md`](../inir/config/README.md).

## Requirements

- OpenCode 2.x
- iNiR with Quickshell (3.x, or 2.x)
- niri (for focus detection)
- `inotify-tools`
- `procps`

Arch:

```bash
sudo pacman -S quickshell inotify-tools procps
```

## Uninstall

Stop the plugin and remove the files:

```bash
rm -rf ~/.config/opencode/plugins/mascot
rm ~/.config/quickshell/inir/scripts/opencode-mascot-focus.sh
rm -rf ~/.config/quickshell/inir/modules/mascot
rm -f ~/.config/mascot-code/config.json
```

On iNiR 2, remove `mascot.codingCompanion` from
`~/.config/inir/config.json`. On iNiR 3, remove the `mascot` line from
`~/.config/quickshell/inir/plugins.list`. Restore your backup from
`~/mascot-code-backup/` if you want the old files back, then restart the shell.
