// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
import QtQuick

/**
 * Empo — the glowing compass-star coding companion.
 *
 * Drawn entirely in QML, no external assets. Expressions are driven by the
 * `expression` property:
 *   idle | thinking | reading | coding | running | browsing | happy | sad | sleeping
 *
 * The star body and glow are static Canvas layers. All motion (blink, bob,
 * scan, typing, jump, tears, zZ) is done with QML item transforms/opacity,
 * so there is no per-frame JavaScript or Canvas repaint while the mascot
 * sleeps.
 *
 * The colors and font are plain properties so the same component works in
 * inir (where CharacterHost feeds it the wallpaper palette) and in the
 * standalone Quickshell config.
 */
Item {
    id: root

    property string expression: "idle"
    property string detail: ""
    property bool active: true
    property bool reducedMotion: false

    property color accent: "#ff9ecf"
    property color accentAlt: "#8fb8ff"
    property color ink: "#1a1a1f"
    property color errorColor: "#ff6b8a"
    property color successColor: "#8ee6b0"
    property color surfaceColor: "#1b1f2a"
    property color mutedColor: "#8b93a7"
    property string fontFamily: "sans-serif"

    readonly property real unit: Math.min(width, height)
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

    // Animated face/body state.
    property real blink: 1
    property real scanOffset: 0
    property real eyeLookX: root.thinking ? root.unit * 0.026
        : root.running ? root.unit * 0.018
        : root.coding ? root.unit * 0.004
        : 0
    property real eyeLookY: root.thinking ? -root.unit * 0.022
        : root.coding ? root.unit * 0.020
        : root.sad ? root.unit * 0.012
        : 0
    property real bodyOffsetY: 0
    property real typingOffset: 0
    property real questionOffset: 0
    property real sparkleScale: 0.8
    property real tearY: 0
    property real zOffset: 0

    function _bobAmplitude(): real {
        if (happy) return root.unit * 0.13
        if (running) return root.unit * 0.05
        if (sleeping || sad) return 0
        return root.unit * 0.018
    }

    function _bobDuration(): int {
        if (happy) return 270
        if (running) return 220
        if (thinking) return 2400
        return 2100
    }

    function _eyeHeight(): real {
        if (reading || browsing) return root.unit * 0.075
        if (happy) return root.unit * 0.018
        if (sleeping) return root.unit * 0.012
        if (sad) return root.unit * 0.050
        if (running) return root.unit * 0.040
        if (coding) return root.unit * 0.046
        return root.unit * 0.058
    }

    function _bodyRotation(): real {
        if (running) return -9
        if (sad) return -5
        if (thinking) return 3
        if (coding) return 2
        return 0
    }

    function _bodyScale(): real {
        if (happy) return 1.05
        if (sad) return 0.96
        if (running) return 1.02
        return 1
    }

    function _glowBase(): real {
        if (sleeping) return 0.28
        if (sad) return 0.40
        if (happy) return 0.88
        return 0.66
    }

    function _starPath(ctx, cx, cy, outer, inner, points, rotation) {
        ctx.beginPath()
        for (let i = 0; i < points * 2; ++i) {
            const radius = (i % 2 === 0) ? outer : inner
            const angle = rotation - Math.PI / 2 + i * Math.PI / points
            const x = cx + Math.cos(angle) * radius
            const y = cy + Math.sin(angle) * radius
            if (i === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.closePath()
    }

    onExpressionChanged: {
        mouth.requestPaint()
        if (expression !== "reading") scanOffset = 0
        if (expression === "sleeping" || expression === "sad") {
            bodyOffsetY = 0
            glowWrap.opacity = _glowBase()
        }
    }
    onAccentChanged: {
        glowCanvas.requestPaint()
        bodyCanvas.requestPaint()
        globeCanvas.requestPaint()
    }
    onInkChanged: mouth.requestPaint()
    onAccentAltChanged: globeCanvas.requestPaint()

    // ── Glow ────────────────────────────────────────────────────────────────
    Item {
        id: glowWrap
        anchors.centerIn: parent
        width: root.unit * 1.22
        height: width
        opacity: root._glowBase()
        z: 0

        Canvas {
            id: glowCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                const cx = width / 2
                const cy = height / 2
                const r = Math.min(width, height) * 0.5
                ctx.clearRect(0, 0, width, height)

                const halo = ctx.createRadialGradient(cx, cy, r * 0.08, cx, cy, r)
                halo.addColorStop(0, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.42))
                halo.addColorStop(0.42, Qt.rgba(root.accentAlt.r, root.accentAlt.g, root.accentAlt.b, 0.18))
                halo.addColorStop(1, Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0))
                ctx.fillStyle = halo
                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.fill()
            }
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && !root.sleeping && !root.sad
        loops: Animation.Infinite
        NumberAnimation {
            target: glowWrap
            property: "opacity"
            from: root._glowBase()
            to: Math.min(1, root._glowBase() + 0.18)
            duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: glowWrap
            property: "opacity"
            from: Math.min(1, root._glowBase() + 0.18)
            to: root._glowBase()
            duration: 2200
            easing.type: Easing.InOutSine
        }
    }

    // ── Star body ───────────────────────────────────────────────────────────
    Item {
        id: body
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + root.bodyOffsetY
        width: root.unit * 0.76
        height: width
        rotation: root._bodyRotation()
        scale: root._bodyScale()
        z: 2

        Behavior on rotation {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }

        Canvas {
            id: bodyCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                const w = width
                const h = height
                const cx = w / 2
                const cy = h / 2
                const outer = Math.min(w, h) * 0.47
                const inner = outer * 0.30

                ctx.clearRect(0, 0, w, h)

                const shade = Qt.lighter(root.accent, 1.35)
                const rim = Qt.lighter(root.accent, 1.9)
                const gradient = ctx.createLinearGradient(0, 0, w, h)
                gradient.addColorStop(0, shade)
                gradient.addColorStop(1, root.accent)

                ctx.save()
                ctx.fillStyle = gradient
                ctx.strokeStyle = rim
                ctx.lineWidth = Math.max(1, w * 0.012)
                root._starPath(ctx, cx, cy, outer, inner, 4, 0)
                ctx.fill()
                ctx.stroke()

                // Secondary four points, rotated 45°, make the compass read as
                // an eight-point star without turning into a snowflake.
                ctx.globalAlpha = 0.72
                ctx.fillStyle = Qt.lighter(root.accent, 1.55)
                root._starPath(ctx, cx, cy, outer * 0.70, inner * 0.48, 4, Math.PI / 4)
                ctx.fill()
                ctx.globalAlpha = 1

                const core = ctx.createRadialGradient(cx, cy, 0, cx, cy, outer * 0.34)
                core.addColorStop(0, Qt.lighter(root.accent, 2.35))
                core.addColorStop(1, Qt.lighter(root.accent, 1.10))
                ctx.fillStyle = core
                ctx.beginPath()
                ctx.arc(cx, cy, outer * 0.29, 0, Math.PI * 2)
                ctx.fill()

                // Compass needle
                ctx.fillStyle = root.accentAlt
                ctx.beginPath()
                ctx.moveTo(cx, cy - outer * 0.21)
                ctx.lineTo(cx + outer * 0.07, cy)
                ctx.lineTo(cx, cy + outer * 0.21)
                ctx.lineTo(cx - outer * 0.07, cy)
                ctx.closePath()
                ctx.fill()
                ctx.restore()
            }
        }

        // Eyes
        Item {
            id: eyes
            x: (parent.width - width) / 2 + root.eyeLookX
            y: parent.height * 0.43 + root.eyeLookY
            width: parent.width * 0.36 + root.scanOffset
            height: root._eyeHeight()

            Rectangle {
                id: leftEye
                width: parent.width * 0.39
                height: Math.max(2, parent.height * root.blink)
                radius: width / 2
                color: root.ink
                rotation: root.happy ? -18 : root.sad ? -12 : 0
                y: (parent.height - height) / 2

                Rectangle {
                    width: Math.max(1.5, parent.width * 0.32)
                    height: width
                    radius: width / 2
                    color: Qt.lighter(root.accent, 2.5)
                    opacity: root.sleeping ? 0 : 0.9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Math.max(1, parent.height * 0.16)
                    anchors.rightMargin: Math.max(1, parent.width * 0.14)
                }
            }

            Rectangle {
                id: rightEye
                x: parent.width - width
                width: parent.width * 0.39
                height: Math.max(2, parent.height * root.blink)
                radius: width / 2
                color: root.ink
                rotation: root.happy ? 18 : root.sad ? 12 : 0
                y: (parent.height - height) / 2

                Rectangle {
                    width: Math.max(1.5, parent.width * 0.32)
                    height: width
                    radius: width / 2
                    color: Qt.lighter(root.accent, 2.5)
                    opacity: root.sleeping ? 0 : 0.9
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: Math.max(1, parent.height * 0.16)
                    anchors.rightMargin: Math.max(1, parent.width * 0.14)
                }
            }
        }

        // Mouth
        Canvas {
            id: mouth
            x: (parent.width - width) / 2
            y: parent.height * 0.64
            width: parent.width * 0.28
            height: parent.height * 0.16
            onPaint: {
                const ctx = getContext("2d")
                const w = width
                const h = height
                const cx = w / 2
                const cy = h / 2
                ctx.clearRect(0, 0, w, h)
                ctx.strokeStyle = root.ink
                ctx.fillStyle = root.ink
                ctx.lineWidth = Math.max(1.2, root.unit * 0.012)
                ctx.lineCap = "round"

                if (root.happy) {
                    ctx.beginPath()
                    ctx.arc(cx, cy * 0.72, w * 0.31, 0.12 * Math.PI, 0.88 * Math.PI)
                    ctx.stroke()
                } else if (root.sad) {
                    ctx.beginPath()
                    ctx.arc(cx, cy * 1.46, w * 0.30, 1.12 * Math.PI, 1.88 * Math.PI)
                    ctx.stroke()
                } else if (root.thinking) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, w * 0.10, 0, Math.PI * 2)
                    ctx.stroke()
                } else if (root.running) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, w * 0.13, 0, Math.PI * 2)
                    ctx.fill()
                } else if (root.coding || root.reading) {
                    ctx.beginPath()
                    ctx.moveTo(cx - w * 0.16, cy)
                    ctx.lineTo(cx + w * 0.16, cy)
                    ctx.stroke()
                } else if (root.sleeping) {
                    ctx.beginPath()
                    ctx.moveTo(cx - w * 0.14, cy)
                    ctx.lineTo(cx + w * 0.14, cy)
                    ctx.stroke()
                } else {
                    ctx.beginPath()
                    ctx.moveTo(cx - w * 0.17, cy)
                    ctx.quadraticCurveTo(cx, cy + h * 0.22, cx + w * 0.17, cy)
                    ctx.stroke()
                }
            }
        }

        // Keyboard while coding
        Item {
            id: keyboard
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.79 + root.typingOffset
            width: parent.width * 0.50
            height: parent.height * 0.16
            opacity: root.coding ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            Rectangle {
                anchors.fill: parent
                radius: height * 0.24
                color: root.surfaceColor
                border.width: 1
                border.color: root.accentAlt
            }

            Row {
                anchors.centerIn: parent
                spacing: parent.width * 0.035
                Repeater {
                    model: 7
                    Rectangle {
                        width: keyboard.width * 0.085
                        height: keyboard.height * 0.34
                        radius: 1.2
                        color: root.accent
                        opacity: 0.8
                    }
                }
            }
        }

        // Reading page
        Item {
            id: book
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.78
            width: parent.width * 0.46
            height: parent.height * 0.18
            opacity: root.reading ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            Rectangle {
                anchors.fill: parent
                radius: height * 0.12
                color: root.surfaceColor
                border.width: 1
                border.color: root.accentAlt
            }

            Repeater {
                model: 3
                Rectangle {
                    x: book.width * 0.12
                    y: book.height * (0.24 + index * 0.17)
                    width: book.width * (0.70 - index * 0.12)
                    height: Math.max(1, book.height * 0.055)
                    radius: height / 2
                    color: root.accentAlt
                    opacity: 0.8
                }
            }

            Rectangle {
                id: scanLine
                width: Math.max(1.5, book.width * 0.025)
                height: book.height * 0.56
                y: book.height * 0.22
                x: book.width * 0.20 + (book.width * 0.60) * ((root.scanOffset / (root.unit * 0.04)) + 0.5)
                radius: width / 2
                color: root.accent
                opacity: root.reading ? 0.95 : 0
            }
        }
    }

    // ── Thinking "?" ─────────────────────────────────────────────────────────
    Text {
        id: question
        text: "?"
        visible: opacity > 0
        opacity: root.thinking ? 1 : 0
        x: body.x + body.width * 0.78
        y: body.y - root.unit * 0.03 + root.questionOffset
        font.family: root.fontFamily
        font.pixelSize: Math.round(root.unit * 0.18)
        font.bold: true
        color: root.accentAlt
        z: 4

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.thinking
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "questionOffset"
            from: 0
            to: -root.unit * 0.035
            duration: 900
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "questionOffset"
            from: -root.unit * 0.035
            to: 0
            duration: 900
            easing.type: Easing.InOutSine
        }
    }

    // ── Browsing globe ──────────────────────────────────────────────────────
    Item {
        id: globe
        anchors.centerIn: parent
        width: root.unit * 0.98
        height: width
        opacity: root.browsing ? 0.95 : 0
        z: 1

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }

        Canvas {
            id: globeCanvas
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                const cx = width / 2
                const cy = height / 2
                const r = Math.min(width, height) * 0.46
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = Qt.rgba(root.accentAlt.r, root.accentAlt.g, root.accentAlt.b, 0.72)
                ctx.lineWidth = Math.max(1, width * 0.009)

                ctx.beginPath()
                ctx.arc(cx, cy, r, 0, Math.PI * 2)
                ctx.stroke()

                ctx.save()
                ctx.scale(0.52, 1)
                ctx.beginPath()
                ctx.arc(cx / 0.52, cy, r, 0, Math.PI * 2)
                ctx.stroke()
                ctx.restore()

                ctx.save()
                ctx.scale(1, 0.52)
                ctx.beginPath()
                ctx.arc(cx, cy / 0.52, r, 0, Math.PI * 2)
                ctx.stroke()
                ctx.restore()

                ctx.beginPath()
                ctx.moveTo(cx - r, cy)
                ctx.lineTo(cx + r, cy)
                ctx.stroke()
            }
        }

        RotationAnimation on rotation {
            running: root.active && !root.reducedMotion && root.browsing
            from: 0
            to: 360
            duration: 9000
            loops: Animation.Infinite
        }
    }

    // ── Running speed lines ─────────────────────────────────────────────────
    Item {
        id: speedLines
        anchors.fill: parent
        opacity: root.running ? 0.95 : 0
        z: 1

        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }

        Repeater {
            model: 3
            Rectangle {
                x: body.x - root.unit * (0.10 + index * 0.055)
                y: body.y + body.height * (0.34 + index * 0.16)
                width: root.unit * (0.18 - index * 0.035)
                height: Math.max(1.5, root.unit * 0.012)
                radius: height / 2
                color: root.accentAlt
                opacity: 0.55 - index * 0.12
            }
        }
    }

    // ── Happy sparkles ──────────────────────────────────────────────────────
    Repeater {
        model: 3
        Text {
            required property int index
            text: index === 1 ? "✦" : "✧"
            x: body.x + body.width * (index === 0 ? 0.08 : index === 1 ? 0.82 : 0.72)
            y: body.y + body.height * (index === 0 ? 0.14 : index === 1 ? 0.10 : 0.78)
            font.pixelSize: Math.round(root.unit * (index === 1 ? 0.16 : 0.12))
            color: root.successColor
            opacity: root.happy ? 0.95 : 0
            scale: root.sparkleScale
            z: 4

            Behavior on opacity {
                NumberAnimation { duration: 160 }
            }
            Behavior on scale {
                NumberAnimation { duration: 380; easing.type: Easing.OutBack }
            }
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.happy
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "sparkleScale"
            from: 0.72
            to: 1.18
            duration: 420
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "sparkleScale"
            from: 1.18
            to: 0.72
            duration: 420
            easing.type: Easing.InOutSine
        }
    }

    // ── Sad tear ────────────────────────────────────────────────────────────
    Rectangle {
        id: tear
        width: Math.max(2.5, root.unit * 0.040)
        height: width * 1.8
        radius: width / 2
        color: Qt.lighter(root.errorColor, 1.20)
        opacity: root.sad ? 0.95 : 0
        x: body.x + body.width * 0.33
        y: body.y + body.height * 0.52 + root.tearY
        z: 4

        Behavior on opacity {
            NumberAnimation { duration: 180 }
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.sad
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "tearY"
            from: 0
            to: root.unit * 0.10
            duration: 1100
            easing.type: Easing.InQuad
        }
        PauseAnimation { duration: 450 }
        NumberAnimation {
            target: root
            property: "tearY"
            from: root.unit * 0.10
            to: 0
            duration: 1
        }
        PauseAnimation { duration: 500 }
    }

    // ── Sleeping zZ ─────────────────────────────────────────────────────────
    Item {
        id: sleepMarks
        anchors.fill: parent
        opacity: root.sleeping ? 1 : 0
        z: 4

        Behavior on opacity {
            NumberAnimation { duration: 260 }
        }

        Text {
            text: "z"
            x: body.x + body.width * 0.74
            y: body.y + body.height * 0.14 - root.zOffset
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.unit * 0.13)
            font.bold: true
            color: Qt.darker(root.accentAlt, 1.35)
        }

        Text {
            text: "Z"
            x: body.x + body.width * 0.84
            y: body.y + body.height * 0.02 - root.zOffset * 0.7
            font.family: root.fontFamily
            font.pixelSize: Math.round(root.unit * 0.17)
            font.bold: true
            color: Qt.darker(root.accentAlt, 1.35)
            opacity: 0.8
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.sleeping
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "zOffset"
            from: 0
            to: root.unit * 0.035
            duration: 2200
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "zOffset"
            from: root.unit * 0.035
            to: 0
            duration: 2200
            easing.type: Easing.InOutSine
        }
    }

    // ── Shared animations ───────────────────────────────────────────────────
    SequentialAnimation {
        running: root.active && !root.reducedMotion && !root.sleeping && !root.sad
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "bodyOffsetY"
            from: 0
            to: root._bobAmplitude()
            duration: root._bobDuration()
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "bodyOffsetY"
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
        PauseAnimation { duration: 3000 }
        NumberAnimation {
            target: root
            property: "blink"
            from: 1
            to: 0.05
            duration: 85
            easing.type: Easing.InQuad
        }
        NumberAnimation {
            target: root
            property: "blink"
            from: 0.05
            to: 1
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.reading
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "scanOffset"
            from: -root.unit * 0.020
            to: root.unit * 0.020
            duration: 680
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "scanOffset"
            from: root.unit * 0.020
            to: -root.unit * 0.020
            duration: 680
            easing.type: Easing.InOutSine
        }
    }

    SequentialAnimation {
        running: root.active && !root.reducedMotion && root.coding
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "typingOffset"
            from: 0
            to: -root.unit * 0.012
            duration: 90
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "typingOffset"
            from: -root.unit * 0.012
            to: 0
            duration: 110
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 80 }
    }

    // Eye direction. Reading adds its own scanOffset; this is the base gaze.
    Behavior on eyeLookX {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
    Behavior on eyeLookY {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }
}
