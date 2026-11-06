# iNiR install

This is the Arch + niri + [iNiR](https://github.com/snowarch/iNiR) build. It
adds the coding mode to iNiR's existing mascot companion and uses niri to hide
the mascot while the OpenCode terminal is focused.

Either Empo or Clawd can be selected; the default is Empo. Type `/mascot` in OpenCode (TUI or Desktop 2.2+) for the visual picker.

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
copies the module, focus script and plugin, then adds:

```json
"mascot": {
  "codingCompanion": {
    "enable": true,
    "character": "empo"
  }
}
```

to `~/.config/inir/config.json`.

## 3. Add the config schema if needed

On a stock iNiR, `Config.qml` does not know the new keys yet. Add the block from
[`../inir/config/Config-schema.qml`](../inir/config/Config-schema.qml) inside the
`mascot` JsonObject in:

```text
~/.config/quickshell/inir/modules/common/Config.qml
```

If you skip this, the overlay will not see `codingCompanion.enable`.

## 4. Add the Settings toggle (optional)

The installer does not patch iNiR's settings pages, because they differ between
versions. Use the IPC command instead:

```bash
inir ipc mascot coding true
inir ipc mascot character clawd
# or
inir ipc mascot character empo
```

The `/mascot` picker writes `~/.config/mascot-code/character.json`. That
shared file wins over the config, so the picker switches the overlay without
opening Settings. `inir ipc mascot character` writes both.

If you want the switch in the UI, copy the "Coding companion" `SettingsSwitch`
from the reference files in `inir/modules/mascot/` context into:

- `~/.config/quickshell/inir/modules/settings/MascotConfig.qml`
- `~/.config/quickshell/inir/modules/waffle/settings/pages/WMascotPage.qml`

The snippet is in `inir/config/README.md`.

## 5. Restart and verify

```bash
inir restart
inir ipc mascot status
```

Expected fields:

```json
{
  "coding": {
    "enabled": true,
    "active": true,
    "openCodeRunning": true,
    "openCodeFocused": false
  },
  "showing": true
}
```

Focus the OpenCode terminal and `showing` should become `false`. Focus another
window and it should become `true` again.

## Requirements

- OpenCode 2.x
- iNiR with Quickshell
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
```

Restore your backup:

```bash
ls ~/mascot-code-backup/
# copy the module and config back from the timestamp you want
```

Then remove `mascot.codingCompanion` from `~/.config/inir/config.json` and
restart the shell.
