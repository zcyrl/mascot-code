# Architecture

Mascot Code is deliberately three small layers instead of one big app.

```text
OpenCode
  │  tool / session events
  ▼
opencode/mascot.ts
  │  atomic JSON writes
  ▼
/tmp/opencode-mascot.json
  │  inotifywait + cat (iNiR)  /  cat every 1s (standalone)
  ▼
Quickshell overlay
  │  expression + detail
  ▼
CharacterHost → Empo / Clawd
```

## The plugin

`opencode/mascot.ts` runs inside the OpenCode server. It registers:

- `tool.execute.before` for reading, coding, running and browsing
- `tool.execute.after` for the thinking state
- `session.created`, `session.idle`, `session.deleted`
- `session.viewed` and `tui.session.select` to follow the active TUI session
- `session.execution.failed` and `session.step.failed` for the sad state

It keeps a `Map<sessionID, state>`, so a subagent or another session cannot
overwrite the session you are looking at. The active session is discovered from
the TUI events, and on plugin reload from the most recently updated top-level
session returned by `ctx.session.list()`.

Events are written with a temporary file and `rename()`. A reader never sees
half a document.

After 60 seconds without an event the active session becomes `sleeping`. The
timer checks the timestamp it wrote, so a second OpenCode instance cannot be
clobbered by an older timer.

## The state file

```json
{
  "state": "thinking",
  "detail": "after reading main.py",
  "ts": 1793869420662,
  "sessionID": "ses_e584..."
}
```

`state` is one of the nine expression names. `detail` is the filename, pattern,
URL or command, truncated to about 30 characters. `ts` is Unix milliseconds.
`sessionID` is diagnostic and used by the overlay to avoid carrying a held
action across a session switch.

## The iNiR integration

The module lives in `~/.config/quickshell/inir/modules/mascot/`.

- `MascotCompanion.qml` already existed in iNiR. Mascot Code adds the coding
  mode, the session watcher and the focus rules.
- `CharacterHost.qml` picks the character component.
- `characters/Empo.qml` draws Empo.
- `characters/Clawd.qml` draws the Claude Code crab.
- `scripts/opencode-mascot-focus.sh` answers `none`, `focused` or `unfocused`
  by walking the process tree from `opencode` up to the focused niri window PID.

A long-lived `inotifywait` process watches `/tmp` for the atomic rename. A short
`cat` reads the new inode. There is no per-second polling in the iNiR build.

Focus changes trigger the probe immediately. A 3-second timer catches OpenCode
starting or exiting while the focus stays on the same window.

The coding mode is enabled with `mascot.codingCompanion.enable`. The character is
selected with `mascot.codingCompanion.character` (`empo` or `clawd`).

## The standalone build

`standalone/shell.qml` is a complete Quickshell config. It does not import iNiR
and does not use the niri focus script. It:

- checks `pgrep -x opencode` every 2.5 seconds
- reads the state file once a second with `cat`
- shows the character selected by `MASCOT_CHARACTER` while OpenCode is running
- uses the same state-to-expression mapping

That is the version for Hyprland, Sway, river, and any other Wayland compositor
with layer-shell. Focus-aware hiding is intentionally not promised there.

## Sleep and staleness

Both builds mark the state as sleeping when `ts` is older than 60 seconds. This
is the crash fallback: if OpenCode dies without writing a final state, the
mascot does not sit on `coding` forever.

## Performance

- No per-frame JavaScript.
- Static Canvas layers for the star and glow.
- QML transforms/opacity for animation.
- Animation loops stop when `active` is false and when the character sleeps.
- The iNiR build has no state polling.
- The standalone build reads a tiny file once a second.
