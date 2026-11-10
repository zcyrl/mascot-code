// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
import QtQuick
import qs.modules.common
import qs.modules.mascot.characters

/**
 * Character switchboard for the coding companion.
 *
 * Adding a character:
 *   1. Drop `characters/YourCharacter.qml` in this directory.
 *   2. Add `YourCharacter 1.0 YourCharacter.qml` to characters/qmldir.
 *   3. Add a Component below and a case in _componentFor().
 *   4. Set `character` in ~/.config/mascot-code/config.json to its name.
 *
 * Built-in characters: "empo" (default) and "claude" (Claude Code crab).
 *
 * A character must expose:
 *   expression: idle | thinking | reading | coding | running | browsing | happy | sad | sleeping
 *   active: stop all loops when false
 *   reducedMotion: honor Appearance.animationsEnabled
 */
Item {
    id: root

    property string character: "empo"
    property string expression: "idle"
    property string detail: ""
    property bool active: true
    property bool reducedMotion: !Appearance.animationsEnabled
    property color accent: Appearance.colors.colPrimary
    property color accentAlt: Appearance.colors.colSecondary
    property color ink: Appearance.colors.colOnPrimary
    property color errorColor: Appearance.colors.colError
    property color successColor: Appearance.colors.colSuccess
    property color surfaceColor: Appearance.colors.colLayer3
    property color mutedColor: Appearance.colors.colOnLayer1Inactive
    property string fontFamily: Appearance.font.family.main

    function _componentFor(name) {
        switch (String(name ?? "").toLowerCase()) {
        case "clawd": // spelling from older pickers
        case "claude":
            return claudeComponent
        case "empo":
        default:
            return empoComponent
        }
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root._componentFor(root.character)
    }

    Component {
        id: empoComponent
        Empo {
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

    Component {
        id: claudeComponent
        Claude {
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
}
