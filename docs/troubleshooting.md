# Troubleshooting

## Nothing appears

Start with the plugin, not the overlay:

```bash
cat /tmp/opencode-mascot.json
opencode plugin list
```

`opencode plugin list` should include:

```text
zcyrl.mascot  local  /home/you/.config/opencode/plugins/mascot
```

If the file exists but never changes, the plugin is not loaded. Restart OpenCode
or check the server log.

## The state says `sleeping` while OpenCode is working

That means `ts` is older than 60 seconds. Either the plugin stopped writing or
the session is genuinely idle. Check:

```bash
date +%s%3N
cat /tmp/opencode-mascot.json
```

The `ts` is Unix milliseconds. A healthy write is within the last few seconds
of the current time.

## The iNiR module is unavailable

```bash
inir logs --issues
inir logs -n 200
```

Usually this is a QML compile error in the module, a missing `CharacterHost.qml`,
or the `characters/` directory not being copied. Both `Claude.qml` and the
`characters/qmldir` entry are required.

On iNiR 3, check that the component is registered:

```bash
ls ~/.config/quickshell/inir/modules/mascot/plugin.json
grep -x mascot ~/.config/quickshell/inir/plugins.list
```

If either is missing, run `./install-inir.sh` and `inir restart`. iNiR updates
may remove local folders under `modules/`, so re-run the installer after an
update.

## `inir ipc mascotcode status` says "Target not found"

The component did not load. Run `inir restart`, then check the log above. On
iNiR 2 the target is `mascot`; that version loads the module directly instead of
through `plugin.json`.

## The bubble updates but the mascot is hidden

On the iNiR build, the mascot hides while the OpenCode terminal is focused. That
is intentional. Focus another window to see it.

Check:

```bash
inir ipc mascotcode status
```

Look at `coding.openCodeFocused` and `showing`.

## The wrong character appears

```bash
cat ~/.config/mascot-code/character.json
inir ipc mascotcode character claude
inir ipc mascotcode status
```

The shared picker file wins over `~/.config/mascot-code/config.json`. If the
picker changes it but the overlay still shows the old character, the running iNiR
module is older than this repo: run `./install-inir.sh` and `inir restart` once.

If the name is accepted but the old character stays after that, the installed
`CharacterHost.qml` and `characters/` are out of sync with this repo. Re-run
`./install-inir.sh` and restart iNiR.

## Focus detection is wrong

Find the focused window:

```bash
niri msg windows
niri msg focused-window
```

Run the probe directly:

```bash
~/.config/quickshell/inir/scripts/opencode-mascot-focus.sh \
  "$(niri msg focused-window | sed -n 's/^  PID: //p')"
```

Expected output: `focused`, `unfocused`, or `none`.

If the terminal is a single process with multiple OS windows (kitty does this
sometimes), the PID cannot distinguish the windows. That is a limitation of the
PID-based probe.

## `inotifywait: command not found`

```bash
sudo pacman -S inotify-tools
```

The standalone build does not need it.

## Two mascots

Mascot Code shows a second peeking mascot beside iNiR 3's own companion only if
`peek` is true in `~/.config/mascot-code/config.json`. Set it to `false` (the
installer does). If you are also running the standalone build, stop its service:

```bash
systemctl --user stop mascot-code.service
```

## The standalone service starts but nothing is visible

Run Quickshell in the foreground to see errors:

```bash
qs -p ~/.config/quickshell/mascot-code
```

Check that `pgrep -x opencode` returns a PID. If your OpenCode binary has a
different process name, edit the probe in `standalone/shell.qml` and the focus
helper in the iNiR build.

## `session.error` never appears

OpenCode V2 exposes failures as `session.execution.failed` and
`session.step.failed`; the plugin listens to those. The old V1 `session.error`
event is not used.
