# Architecture

Mascot Code is deliberately three small layers instead of one big app.

```text
OpenCode
  │  tool / session events
  ▼
opencode/mascot/index.ts
  │  atomic JSON writes
  ▼
/tmp/opencode-mascot.json
  │  inotifywait + cat (iNiR)  /  cat every 1s (standalone)
  ▼
Quickshell overlay
  │  expression + detail
  ▼
CharacterHost → Empo / Claude
```

The same plugin package also has `tui.tsx` (the terminal `/mascot` card) and
`gui-experimental.cjs` (the OpenCode Desktop card). Both pickers write
`~/.config/mascot-code/character.json`; the overlays read that before their
configured character.

## The plugin

`opencode/mascot/index.ts` runs inside the OpenCode server. It registers:

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

## The `/mascot` picker

The plugin package has three parts:

- `opencode/mascot/index.ts` — the server part above.
- `opencode/mascot/tui.tsx` — the OpenTUI card. `/mascot` opens a focusable
  dialog; hovering a card starts a 1.4-second expression timer.
- `opencode/mascot/gui-experimental.cjs` — the OpenCode Desktop 2.2+ card,
  built from `gui/src/`. It uses the app's `Dialog` and a main-process IPC to
  read/write the selection.

The picker frames live in `opencode/mascot/art.ts` as PNG data URLs, generated
from the QML characters by `scripts/generate-tui-assets.sh`. Both parts write
the same selection file:

```json
{
  "character": "claude",
  "updated": 1793969137623
}
```

`~/.config/mascot-code/character.json` wins over the iNiR config and
`MASCOT_CHARACTER`. The overlay's `mascot character` IPC writes the same file,
so the three ways to switch cannot disagree.

OpenCode Desktop 2.1.x predates the GUI plugin API; it can still use the TUI
picker but has no desktop card. OpenCode Desktop 2.2+ loads
`gui-experimental.cjs` from the local plugin package.

## The iNiR integration

The module lives in `~/.config/quickshell/inir/modules/mascot/`.

On iNiR 3 it is a **component plugin**: `plugin.json` tells the shell to load
`MascotCompanion.qml` as a surface of its own, beside iNiR's mascot. The
installer also lists `mascot` in `~/.config/quickshell/inir/plugins.list`. On
iNiR 2 the shell loaded the module directly.

- `MascotCompanion.qml` is derived from iNiR's companion. Mascot Code adds the
  coding mode, the session watcher and the focus rules; iNiR's own chaos romp is
  not shipped.
- `CharacterHost.qml` picks the character component.
- `characters/Empo.qml` draws Empo.
- `characters/Claude.qml` draws the Claude Code crab.
- `scripts/opencode-mascot-focus.sh` answers `none`, `focused` or `unfocused`
  by walking the process tree from `opencode` up to the focused niri window PID.

A long-lived `inotifywait` process watches `/tmp` for the atomic rename. A short
`cat` reads the new inode. There is no per-second polling in the iNiR build.

Focus changes trigger the probe immediately. A 3-second timer catches OpenCode
starting or exiting while the focus stays on the same window.

The coding mode is enabled with `enable` in
`~/.config/mascot-code/config.json`. The character is selected with `character`
there (`empo` or `claude`), unless the shared picker file
`~/.config/mascot-code/character.json` exists; that file wins. On iNiR 2 the
same keys live under `mascot.codingCompanion` and are read as a fallback.

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
