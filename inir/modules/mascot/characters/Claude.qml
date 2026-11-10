// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
import QtQuick

/**
 * Claude — the blocky orange Claude Code crab.
 *
 * Claude is Anthropic's pixel mascot: a flat terracotta body, two black
 * rectangular eyes, two claws and four little legs. This version keeps the
 * silhouette and adds the same nine expressions the companion already uses:
 *   idle | thinking | reading | coding | running | browsing | happy | sad | sleeping
 *
 * The whole character is drawn on a fixed 300x300 pixel-art stage and scaled
 * to the host size, so the blocks stay square and crisp at any sprite size.
 * Only transforms and opacities animate; there is no Canvas repaint and no
 * glow, so the flat pixel look survives every expression.
 *
 * The theme properties from CharacterHost are accepted for the contract but
 * Claude keeps his own Claude palette on purpose. A wallpaper-tinted crab stops
 * looking like Claude.
 */
Item {
    id: root

    property string expression: "idle"
    property string detail: ""
    property bool active: true
    property bool reducedMotion: false

    // CharacterHost contract inputs. Kept so the host can pass them without
    // breaking; Claude deliberately uses his own fixed palette below.
    property color accent: "#d77856"
    property color accentAlt: "#f0eee6"
    property color ink: "#191512"
    property color errorColor: "#b8503a"
    property color successColor: "#8fbf8f"
    property color surfaceColor: "#241d1a"
    property color mutedColor: "#9b8b80"
    property string fontFamily: "sans-serif"

    // Claude palette, sampled from the official Claude art.
    readonly property color shell: "#d77856"
    readonly property color shellLight: "#e99677"
    readonly property color shellDark: "#a94f38"
    readonly property color eyeColor: "#191512"
    readonly property color cream: "#f0eee6"
    readonly property color creamDim: "#d8d1c3"
    readonly property color screenColor: "#120f0d"
    readonly property color panelColor: "#241d1a"
    readonly property color borderColor: "#5c4438"
    readonly property color gold: "#f4c95d"
    readonly property color tearColor: "#8fc8e8"
    readonly property color sleepColor: "#a9c7d9"

    readonly property real unit: Math.min(width, height)
    readonly property real artScale: unit / 300
    readonly property bool sleeping: expression === "sleeping"
    readonly property bool happy: expression === "happy"
    readonly property bool sad: expression === "sad"
    readonly property bool reading: expression === "reading"
    readonly property bool coding: expression === "coding"
    readonly property bool browsing: expression === "browsing"
    readonly property bool thinking: expression === "thinking"
    readonly property bool running: expression === "running"

    implicitWidth: 150
    implicitHeight: 150

    // Animated state.
    property real blink: 1
    property real bodyBob: 0
    property real legSwing: 0
    property real typingTap: 0
    property real scanProgress: 0
    property real speedShift: 0
    property real tearY: 0
    property real sleepFloat: 0
    property real questionFloat: 0
    property real propFloat: 0
    property real sparklePulse: 0.9

    readonly property real eyeShiftX: browsing ? 6 : thinking ? 4 : reading ? scanProgress * 5 : 0
    readonly property real eyeShiftY: thinking ? -6 : browsing ? -5 : reading ? 4
        : coding ? 7 : sad ? 7 : running ? 2 : 0

    function _postureY(): real {
        if (sad) return 9
        if (sleeping) return 5
        return 0
    }

    function _bodyRotation(): real {
        if (running) return -7
        if (sad) return -3
        return 0
    }

    function _bodyScale(): real {
        if (happy) return 1.04
        if (sad) return 0.97
        if (running) return 1.01
        return 1
    }

    function _leftArmAngle(): real {
        if (happy) return 62
        if (thinking) return 0
        if (reading) return 20
        if (coding) return 26 + typingTap * 5
        if (running) return 20 + legSwing * 8
        if (sad) return -12
        if (sleeping) return 6
        return 0
    }

    function _rightArmAngle(): real {
        if (happy) return -62
        if (thinking) return -48
        if (reading) return -20
        if (coding) return -26 - typingTap * 5
        if (running) return -20 - legSwing * 8
        if (sad) return 12
        if (sleeping) return -6
        return 0
    }

    function _legAngle(index): real {
        if (running) return legSwing * (index % 2 === 0 ? 13 : -13)
        return 0
    }

    function _bobAmplitude(): real {
        if (happy) return 24
        if (running) return 10
        if (thinking) return 7
        if (browsing) return 6
        if (reading) return 4
        if (coding) return 3
        if (sleeping || sad) return 0
        return 4
    }

    function _bobDuration(): int {
        if (happy) return 280
        if (running) return 190
        if (thinking) return 2200
        return 2400
    }

    function _eyeMap() {
        if (happy)
            return [ "...", ".X.", "X.X", "X.X", "..." ]
        if (sleeping)
            return [ "...", "...", "XXX", "XXX", "..." ]
        return [ "XXX", "XXX", "XXX", "XXX", "XXX" ]
    }

    function _blocks(rows) {
        const blocks = []
        for (let r = 0; r < rows.length; ++r) {
            const row = rows[r]
            for (let c = 0; c < row.length; ++c)
                if (row[c] !== ".")
                    blocks.push({ col: c, row: r })
        }
        return blocks
    }

    readonly property var eyeBlocks: _blocks(_eyeMap())
    readonly property var questionBlocks: _blocks([
        ".XXX.",
        "X...X",
        "....X",
        "...X.",
        "..X..",
        ".....",
        "..X..",
        "..X.."
    ])
    readonly property var sleepBlocks: _blocks([
        "XXXX",
        "...X",
        "..X.",
        ".X..",
        "XXXX"
    ])
    readonly property var globeBlocks: {
        const rows = [
            "...XXXX....",
            "..X....X...",
            ".X..OO..X..",
            "X..OOOO..X.",
            "X.OOOOOO.X.",
            "X.OOOOOO.X.",
            "X..OOOO..X.",
            ".X..OO..X..",
            "..X....X...",
            "...XXXX...."
        ]
        const blocks = []
        for (let r = 0; r < rows.length; ++r)
            for (let c = 0; c < rows[r].length; ++c)
                if (rows[r][c] !== ".")
                    blocks.push({ col: c, row: r, land: rows[r][c] === "O" })
        return blocks
    }

    onExpressionChanged: {
        blink = 1
        typingTap = 0
        scanProgress = 0
        tearY = 0
        sparklePulse = 0.9
    }

    // ── 300x300 pixel-art stage ─────────────────────────────────────────────
    Item {
        id: stage
        width: 300
        height: 300
        x: (root.width - width * root.artScale) / 2
        y: (root.height - height * root.artScale) / 2
        scale: root.artScale
        transformOrigin: Item.TopLeft

        Item {
            id: posture
            width: 300
            height: 300
            y: root._postureY()

            Behavior on y {
                NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
            }

            Item {
                id: bob
                width: 300
                height: 300
                y: root.bodyBob
                rotation: root._bodyRotation()
                scale: root._bodyScale()
                transformOrigin: Item.Center

                Behavior on rotation {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                // ── Speed lines and dust ────────────────────────────────────
                Item {
                    id: speedLines
                    anchors.fill: parent
                    opacity: root.running ? 0.95 : 0
                    z: 1

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }

                    Rectangle {
                        x: 20 + root.speedShift
                        y: 118
                        width: 30
                        height: 6
                        color: root.cream
                        opacity: 0.55
                    }
                    Rectangle {
                        x: 8 + root.speedShift
                        y: 146
                        width: 42
                        height: 6
                        color: root.shellLight
                        opacity: 0.8
                    }
                    Rectangle {
                        x: 24 + root.speedShift
                        y: 174
                        width: 26
                        height: 6
                        color: root.cream
                        opacity: 0.45
                    }
                    Rectangle {
                        x: 4 + root.speedShift
                        y: 202
                        width: 34
                        height: 6
                        color: root.shellLight
                        opacity: 0.65
                    }
                    Rectangle {
                        x: 42 + root.speedShift
                        y: 248
                        width: 12
                        height: 12
                        color: root.shellLight
                        opacity: 0.5
                    }
                    Rectangle {
                        x: 22 + root.speedShift
                        y: 262
                        width: 8
                        height: 8
                        color: root.cream
                        opacity: 0.35
                    }
                }

                // ── Legs ────────────────────────────────────────────────────
                Item {
                    id: legsGroup
                    width: 300
                    height: 300
                    z: 1

                    Repeater {
                        model: [72, 104, 182, 214]

                        Item {
                            required property int modelData
                            required property int index
                            x: modelData
                            y: 226
                            width: 14
                            height: 30
                            transformOrigin: Item.Top
                            rotation: root._legAngle(index)

                            Rectangle {
                                width: 14
                                height: 30
                                color: root.shell
                            }
                        }
                    }
                }

                // ── Arms ────────────────────────────────────────────────────
                // The claws sit in front of props so Claude reads as holding
                // the page, keyboard or globe instead of standing behind it.
                Item {
                    id: leftArm
                    x: 28
                    y: 160 + (root.coding ? 28 : root.reading ? 16 : 0)
                    width: 30
                    height: 30
                    z: 4
                    transformOrigin: Item.Right
                    rotation: root._leftArmAngle()

                    Behavior on y {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.shell
                    }
                }

                Item {
                    id: rightArm
                    x: 242
                    y: 160 + (root.coding ? 28 : root.reading ? 16 : 0)
                    width: 30
                    height: 30
                    z: 4
                    transformOrigin: Item.Left
                    rotation: root._rightArmAngle()

                    Behavior on y {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                    Behavior on rotation {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.shell
                    }
                }

                // ── Body ────────────────────────────────────────────────────
                Item {
                    id: bodyGroup
                    width: 300
                    height: 300
                    z: 2

                    Rectangle {
                        id: body
                        x: 58
                        y: 88
                        width: 184
                        height: 138
                        color: root.shell
                    }
                }

                // ── Eyes ────────────────────────────────────────────────────
                Item {
                    id: eyes
                    x: 86 + root.eyeShiftX
                    y: 124 + root.eyeShiftY
                    width: 111
                    height: 30
                    z: 4

                    Behavior on x {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }
                    Behavior on y {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        model: [0, 110]

                        Item {
                            required property int modelData
                            x: modelData
                            width: 18
                            height: 30
                            transform: Scale {
                                origin.x: 9
                                origin.y: 15
                                yScale: root.blink * (root.sad ? 0.72 : 1)
                            }

                            Repeater {
                                model: root.eyeBlocks

                                Rectangle {
                                    required property var modelData
                                    x: modelData.col * 6
                                    y: modelData.row * 6
                                    width: 6
                                    height: 6
                                    color: root.eyeColor
                                }
                            }
                        }
                    }
                }

                // ── Reading page ────────────────────────────────────────────
                Item {
                    id: page
                    x: 54
                    y: 172
                    width: 192
                    height: 86
                    z: 3
                    opacity: root.reading ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Rectangle {
                        x: 5
                        y: 5
                        width: 192
                        height: 86
                        color: "#000000"
                        opacity: 0.35
                    }
                    Rectangle {
                        width: 192
                        height: 86
                        color: root.cream
                    }
                    Rectangle {
                        x: 12
                        y: 12
                        width: 58
                        height: 7
                        color: root.shell
                    }
                    Repeater {
                        model: [0, 1, 2, 3]
                        Rectangle {
                            required property int index
                            x: 12
                            y: 29 + index * 12
                            width: 166 - index * 18
                            height: 4
                            color: "#6f5c50"
                            opacity: 0.85
                        }
                    }
                    Rectangle {
                        id: scanLine
                        width: 3
                        height: 62
                        y: 12
                        x: 12 + (root.scanProgress + 1) * 0.5 * 168
                        color: root.shell
                        opacity: 0.9
                    }
                }

                // ── Coding keyboard ─────────────────────────────────────────
                Item {
                    id: keyboard
                    x: 56
                    y: 218
                    width: 188
                    height: 52
                    z: 3
                    opacity: root.coding ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Rectangle {
                        x: 4
                        y: 4
                        width: 188
                        height: 52
                        color: "#000000"
                        opacity: 0.4
                    }
                    Rectangle {
                        width: 188
                        height: 52
                        color: root.panelColor
                        border.width: 2
                        border.color: root.borderColor
                    }
                    Repeater {
                        model: 3
                        Row {
                            id: keyRow
                            required property int index
                            x: 16
                            y: 9 + index * 13
                            spacing: 4
                            Repeater {
                                model: 10
                                Rectangle {
                                    required property int index
                                    width: 12
                                    height: 8
                                    color: (index + keyRow.index) % 3 === 0 ? root.shell : root.cream
                                    opacity: (index + keyRow.index) % 3 === 0 ? 0.9 : 0.72
                                }
                            }
                        }
                    }
                    Rectangle {
                        x: 20
                        y: 48
                        width: 148
                        height: 2
                        color: root.shell
                        opacity: 0.7
                    }
                }

                // ── Browsing window ─────────────────────────────────────────
                Item {
                    id: browserCard
                    x: 168
                    y: 4 + root.propFloat
                    width: 120
                    height: 102
                    z: 3
                    opacity: root.browsing ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Rectangle {
                        x: 5
                        y: 5
                        width: 120
                        height: 102
                        color: "#000000"
                        opacity: 0.4
                    }
                    Rectangle {
                        width: 120
                        height: 102
                        color: root.panelColor
                        border.width: 2
                        border.color: root.borderColor
                    }
                    Rectangle {
                        width: 116
                        height: 16
                        x: 2
                        y: 2
                        color: "#2b211d"
                    }
                    Repeater {
                        model: [0, 1, 2]
                        Rectangle {
                            required property int index
                            x: 8 + index * 8
                            y: 7
                            width: 5
                            height: 5
                            color: index === 0 ? root.shell : index === 1 ? root.gold : root.creamDim
                        }
                    }
                    Rectangle {
                        x: 6
                        y: 22
                        width: 108
                        height: 74
                        color: root.screenColor
                    }
                    Item {
                        x: 33
                        y: 34
                        width: 55
                        height: 50

                        Repeater {
                            model: root.globeBlocks

                            Rectangle {
                                required property var modelData
                                x: modelData.col * 5
                                y: modelData.row * 5
                                width: 5
                                height: 5
                                color: modelData.land ? root.shell : root.cream
                                opacity: modelData.land ? 1 : 0.9
                            }
                        }
                    }
                }

                // ── Thinking "?" ────────────────────────────────────────────
                Item {
                    id: question
                    x: 210
                    y: 30 + root.questionFloat
                    width: 35
                    height: 56
                    z: 5
                    opacity: root.thinking ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Repeater {
                        model: root.questionBlocks

                        Rectangle {
                            required property var modelData
                            x: modelData.col * 7
                            y: modelData.row * 7
                            width: 7
                            height: 7
                            color: root.cream
                        }
                    }
                }

                // ── Happy sparkles ──────────────────────────────────────────
                Repeater {
                    model: [
                        { x: 42, y: 76, size: 6 },
                        { x: 236, y: 62, size: 7 },
                        { x: 222, y: 214, size: 5 }
                    ]

                    Item {
                        id: sparkle
                        required property var modelData
                        x: modelData.x
                        y: modelData.y
                        width: modelData.size * 3
                        height: modelData.size * 3
                        z: 5
                        opacity: root.happy ? 0.95 : 0
                        scale: root.sparklePulse
                        transformOrigin: Item.Center

                        Behavior on opacity {
                            NumberAnimation { duration: 160 }
                        }

                        Repeater {
                            model: [ { c: 1, r: 0 }, { c: 0, r: 1 }, { c: 1, r: 1 }, { c: 2, r: 1 }, { c: 1, r: 2 } ]
                            Rectangle {
                                required property var modelData
                                x: modelData.c * sparkle.modelData.size
                                y: modelData.r * sparkle.modelData.size
                                width: sparkle.modelData.size
                                height: sparkle.modelData.size
                                color: root.gold
                            }
                        }
                    }
                }

                // ── Sad tear ────────────────────────────────────────────────
                Item {
                    id: tear
                    x: 96
                    y: 150 + root.tearY
                    width: 9
                    height: 18
                    z: 5
                    opacity: root.sad ? 0.95 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 160 }
                    }

                    Rectangle {
                        width: 8
                        height: 10
                        color: root.tearColor
                    }
                    Rectangle {
                        x: 1
                        y: 10
                        width: 6
                        height: 7
                        color: root.tearColor
                        opacity: 0.8
                    }
                }

                // ── Sleeping zZ ─────────────────────────────────────────────
                Item {
                    id: sleepMarks
                    anchors.fill: parent
                    z: 5
                    opacity: root.sleeping ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 240 }
                    }

                    Item {
                        x: 206
                        y: 52 - root.sleepFloat
                        width: 28
                        height: 35

                        Repeater {
                            model: root.sleepBlocks

                            Rectangle {
                                required property var modelData
                                x: modelData.col * 7
                                y: modelData.row * 7
                                width: 7
                                height: 7
                                color: root.sleepColor
                            }
                        }
                    }

                    Item {
                        x: 236
                        y: 30 - root.sleepFloat * 0.75
                        width: 20
                        height: 25
                        opacity: 0.75

                        Repeater {
                            model: root.sleepBlocks

                            Rectangle {
                                required property var modelData
                                x: modelData.col * 5
                                y: modelData.row * 5
                                width: 5
                                height: 5
                                color: root.sleepColor
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Animations ──────────────────────────────────────────────────────────
    SequentialAnimation {
        running: root.active && !root.reducedMotion && !root.sleeping && !root.sad
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "bodyBob"
            from: 0
            to: root._bobAmplitude()
            duration: root._bobDuration()
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "bodyBob"
            from: root._bobAmplitude()
            to: 0
            duration: root._bobDuration()
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion
            && !root.sleeping && !root.sad && !root.happy
        loops: Animation.Infinite
        PauseAnimation { duration: 3400 }
        NumberAnimation {
            target: root
            property: "blink"
            from: 1
            to: 0.08
            duration: 85
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blink"
            from: 0.08
            to: 1
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.coding
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "typingTap"
            from: 0
            to: 1
            duration: 85
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "typingTap"
            from: 1
            to: 0
            duration: 105
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 70 }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.running
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "legSwing"
            from: -1
            to: 1
            duration: 145
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "legSwing"
            from: 1
            to: -1
            duration: 145
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.running
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "speedShift"
            from: 0
            to: -12
            duration: 260
            easing.type: Easing.Linear
        }
        NumberAnimation {
            target: root
            property: "speedShift"
            from: -12
            to: 0
            duration: 1
        }
        PauseAnimation { duration: 40 }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.reading
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "scanProgress"
            from: -1
            to: 1
            duration: 900
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "scanProgress"
            from: 1
            to: -1
            duration: 900
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.thinking
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "questionFloat"
            from: 0
            to: -7
            duration: 900
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "questionFloat"
            from: -7
            to: 0
            duration: 900
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.browsing
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "propFloat"
            from: 0
            to: -5
            duration: 1300
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "propFloat"
            from: -5
            to: 0
            duration: 1300
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.happy
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "sparklePulse"
            from: 0.78
            to: 1.18
            duration: 420
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "sparklePulse"
            from: 1.18
            to: 0.78
            duration: 420
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.sad
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "tearY"
            from: 0
            to: 15
            duration: 1000
            easing.type: Easing.InQuad
        }
        PauseAnimation { duration: 380 }
        NumberAnimation {
            target: root
            property: "tearY"
            from: 15
            to: 0
            duration: 1
        }
        PauseAnimation { duration: 520 }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.sleeping
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "sleepFloat"
            from: 0
            to: 5
            duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "sleepFloat"
            from: 5
            to: 0
            duration: 2200
            easing.type: Easing.InOutSine
        }
    }
}
