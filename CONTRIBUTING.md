# Contributing

Small project, simple rules.

1. Fork it, make a branch, test the states you touched.
2. Keep the plugin and both overlays in sync. A new state should have a mapping
   in `opencode/mascot/index.ts`, `opencode/mascot/tui.tsx`, `gui/src/gui.tsx`,
   `inir/modules/mascot/MascotCompanion.qml`,
   `standalone/shell.qml`, and a visual in each character.
3. If you add a character, follow
   [`inir/modules/mascot/characters/README.md`](inir/modules/mascot/characters/README.md)
   and add it to `CharacterHost.qml`, `standalone/shell.qml` and the release
   package script.
4. Run `scripts/test-states.sh <state> "<detail>"` and check the iNiR log:
   ```bash
   inir restart
   inir logs --issues
   ```
   Regenerate the docs shots with:
   ```bash
   ./scripts/capture-character-screenshots.sh claude
   ```
5. Keep the license. New files get:
   ```text
   SPDX-License-Identifier: GPL-3.0-only
   ```
   and your own copyright line if you want one.

No npm build, no generated lockfile, no framework of the week. Keep it small.
