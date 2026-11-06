# Characters

Empo lives here, and now Clawd does too.

`CharacterHost.qml` picks the component. The companion only knows about the
state string; a character owns the art and the animation.

Built-ins:

- `Empo.qml` — the glowing compass-star, Canvas body + QML face.
- `Clawd.qml` — the blocky orange Claude Code crab, 300x300 pixel-art stage of
  plain rectangles. `clawd` and `claude` both select it.

## Contract

A character is a QML component with at least these properties:

```qml
Item {
    property string expression: "idle"
    property bool active: true
    property bool reducedMotion: false
}
```

`expression` is one of:

```text
idle | thinking | reading | coding | running | browsing | happy | sad | sleeping
```

`active` is false when the companion is hidden or the window is not on stage.
Stop every loop when it is false.

`reducedMotion` follows the shell's animation setting. Do not animate when it is
true.

The inir build also passes the wallpaper palette:

```qml
property color accent
property color accentAlt
property color ink
property color errorColor
property color successColor
property color surfaceColor
property color mutedColor
property string fontFamily
```

Characters can ignore those and ship their own palette. Clawd does: a
wallpaper-tinted crab stops looking like Clawd. The standalone build sets the
Empo palette explicitly and lets Clawd keep his fixed Claude orange.

## Add a character

1. Copy `Empo.qml` or `Clawd.qml` to `YourCharacter.qml`.
2. Change the drawing and expressions.
3. Add the type to `qmldir`:
   ```text
   YourCharacter 1.0 YourCharacter.qml
   ```
4. Add a component and a case to `../CharacterHost.qml`:
   ```qml
   Component {
       id: yourCharacterComponent
       YourCharacter {
           expression: root.expression
           detail: root.detail
           active: root.active
           reducedMotion: root.reducedMotion
           accent: root.accent
           accentAlt: root.accentAlt
           ink: root.ink
           errorColor: root.errorColor
           successColor: root.successColor
           surfaceColor: root.surfaceColor
           mutedColor: root.mutedColor
           fontFamily: root.fontFamily
       }
   }
   ```
5. Add it to `_componentFor()`.
6. Select it:
   ```bash
   inir ipc mascot character yourcharacter
   ```

For a standalone preview, set `MASCOT_CHARACTER=yourcharacter` after adding the
component to `standalone/shell.qml` too. `scripts/capture-character-screenshots.sh`
renders the built-ins on a clean black stage.

## Animation guidance

Empo uses a static `Canvas` for the star body and glow, then QML items for the
eyes, mouth, keyboard, book, globe, tears, sparkles and `zZ`. Only transforms and
opacities animate. That keeps the CPU low and means the character can stop
completely when it sleeps.

A character does not have to use Canvas. `Shape`, `Image`, SVG-in-QML, or plain
rectangles are all fine. Keep the per-frame work small: prefer QML animations
over repainting a Canvas at 60fps.

## Naming

Keep the file name and the qmldir entry identical. Use lower-case config names
(`empo`, `yourcharacter`) and match them in `_componentFor()`.

## License

Everything in this directory is GPL-3.0-only. If you add a character, you can
put your own copyright line in the file, but the project stays GPL-3.0.
