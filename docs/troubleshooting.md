# Troubleshooting

## Nothing appears

Start with the plugin, not the overlay:

```bash
cat /tmp/opencode-mascot.json
opencode plugin list
```

`opencode plugin list` should include:

```text
opencode.mascot  local  /home/you/.config/opencode/plugins/mascot.ts
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
or the `characters/` directory not being copied.

## The bubble updates but the star is hidden

On the iNiR build, the star hides while the OpenCode terminal is focused. That
is intentional. Focus another window to see it.

Check:

```bash
inir ipc mascot status
```

Look at `coding.openCodeFocused` and `showing`.

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

## Two Empos

You are running both builds. Stop the standalone service:

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
