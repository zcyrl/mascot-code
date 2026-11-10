# iNiR 2 config patches

These are the pieces the installer cannot safely patch for every iNiR version.
**iNiR 3 does not need any of this**: it loads Mascot Code as a component plugin
and keeps its settings in `~/.config/mascot-code/config.json`.

## 1. Schema

Inside the `mascot` JsonObject in
`~/.config/quickshell/inir/modules/common/Config.qml`:

```qml
property JsonObject codingCompanion: JsonObject {
    property bool enable: false
    property string character: "empo"
}
```

## 2. Defaults

In `~/.config/quickshell/inir/defaults/config.json`, inside `"mascot"`:

```json
"codingCompanion": {
    "enable": false,
    "character": "empo"
}
```

`character` is `"empo"` or `"claude"`. Existing user configs do not need a
migration: the code falls back to `false` and `"empo"`. The installer adds the
keys to your live config.

The `/mascot` picker in OpenCode writes
`~/.config/mascot-code/character.json`; this file wins over the config while it
exists, so the TUI and desktop pickers can switch the overlay without opening
iNiR Settings. The `inir ipc mascot character` command updates both.

## 3. ii settings switch

In `modules/settings/MascotConfig.qml`, inside the first `SettingsGroup` after
the "Playful companion" switch:

```qml
SettingsSwitch {
    buttonIcon: "code"
    text: Translation.tr("Coding companion")
    checked: Config.options?.mascot?.codingCompanion?.enable ?? false
    onCheckedChanged: Config.setNestedValue("mascot.codingCompanion.enable", checked)
    StyledToolTip {
        text: Translation.tr("Appears while OpenCode is running in a terminal, steps out of the way while that terminal is focused, and follows OpenCode's state file with a themed compass-star. No random visits while this mode is on.")
    }
}
```

## 4. Waffle settings switch

In `modules/waffle/settings/pages/WMascotPage.qml`, after the "Playful
companion" row:

```qml
WSettingsSwitch {
    label: Translation.tr("Coding companion")
    icon: "code"
    description: Translation.tr("Appears while OpenCode is running in a terminal, steps out of the way while that terminal is focused, and follows OpenCode's state file with a themed compass-star. No random visits while this mode is on.")
    checked: Config.options?.mascot?.codingCompanion?.enable ?? false
    onCheckedChanged: Config.setNestedValue("mascot.codingCompanion.enable", checked)
}
```

## 5. IPC without Settings

```bash
inir ipc mascot coding true
inir ipc mascot coding false
inir ipc mascot character claude
inir ipc mascot character empo
inir ipc mascot status
```
