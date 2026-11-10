// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Softbrick (zcyrl)
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "characters"

/**
 * Mascot Code — standalone Quickshell overlay.
 *
 * This is the "works outside inir" build: one transparent layer-shell window
 * in the bottom-right corner, a character, a speech bubble, and the OpenCode
 * state file. It does not need niri, iNiR, GTK, npm or a browser.
 *
 * Pick the character with MASCOT_CHARACTER=empo or MASCOT_CHARACTER=claude
 * (default: empo).
 *
 * It shows while an `opencode` TUI process is running. Focus-aware hiding is
 * an iNiR/niri integration and lives in the inir version, not here.
 */
ShellRoot {
    id: root

    readonly property string statePath: "/tmp/opencode-mascot.json"
    readonly property string mascotConfigDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/mascot-code"
    readonly property string sharedCharacter: {
        if (!characterFile.loaded) return ""
        try {
            const data = JSON.parse(characterFile.text())
            const value = String(data.character ?? "").toLowerCase()
            // "clawd" is the spelling older pickers wrote; keep reading it.
            if (value === "clawd") return "claude"
            return ["empo", "claude"].includes(value) ? value : ""
        } catch (error) {
            return ""
        }
    }
    readonly property string character: {
        const value = sharedCharacter.length > 0
            ? sharedCharacter
            : (Quickshell.env("MASCOT_CHARACTER") || "empo").toLowerCase()
        return value === "clawd" ? "claude" : value
    }
    property bool openCodeRunning: false
    property string state: "idle"
    property string detail: ""
    property double timestamp: 0
    property double now: Date.now()

    readonly property string displayState: {
        if (timestamp > 0 && now - timestamp > 60000)
            return "sleeping"
        return state
    }
    readonly property string line: {
        const value = String(detail ?? "").trim()
        switch (displayState) {
        case "reading": return value ? `reading ${value}` : "reading"
        case "coding": return value ? `coding ${value}` : "coding"
        case "running": return value ? `running ${value}` : "running"
        case "browsing": return value ? `browsing ${value}` : "browsing"
        case "thinking":
            return value && value !== "thinking" ? `thinking ${value}` : "thinking..."
        case "happy": return value && value !== "done" ? value : "done!"
        case "sad": return value ? `error: ${value}` : "something went wrong"
        case "sleeping":
        case "idle":
        default:
            return ""
        }
    }

    function applyState(raw) {
        try {
            const parsed = JSON.parse(String(raw ?? ""))
            if (!parsed || typeof parsed !== "object") return
            const next = String(parsed.state ?? "")
            if (["idle", "thinking", "reading", "coding", "running",
                 "browsing", "happy", "sad", "sleeping"].indexOf(next) === -1)
                return
            root.state = next
            root.detail = String(parsed.detail ?? "")
            const ts = Number(parsed.ts ?? 0)
            root.timestamp = isFinite(ts) && ts > 0 ? ts : Date.now()
            root.now = Date.now()
        } catch (error) {
            // Ignore malformed/partial JSON and keep the last good state.
        }
    }

    // Is OpenCode running? A terminal TUI counts, and so does the desktop
    // app. Skip `opencode serve --service`, the desktop backend that stays
    // alive after the app window closes. Polling is cheap and works on every
    // distro; no inotifywait dependency in this build.
    Process {
        id: openCodeProbe
        command: ["bash", "-c", "for pid in $(pgrep -x opencode 2>/dev/null); do cmd=$(ps -o args= -p \"$pid\" 2>/dev/null); case \" $cmd \" in *\" serve \"*) continue ;; esac; exit 0; done; pgrep -f 'opencode-desktop|ai.opencode.desktop' >/dev/null 2>&1"]
        onExited: exitCode => root.openCodeRunning = (exitCode === 0)
    }
    Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!openCodeProbe.running) openCodeProbe.running = true
    }

    // The plugin writes atomically. We read the path every second instead of
    // holding an inode watcher, so a rename never leaves us stuck on old JSON.
    Process {
        id: stateReader
        command: ["cat", root.statePath]
        stdout: StdioCollector {
            onStreamFinished: root.applyState(text)
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.openCodeRunning
        triggeredOnStart: true
        onTriggered: {
            root.now = Date.now()
            if (!stateReader.running) stateReader.running = true
        }
    }

    // The /mascot picker in OpenCode writes this shared selection. It wins over
    // MASCOT_CHARACTER so TUI, desktop and standalone agree on the character.
    FileView {
        id: characterFile
        path: root.mascotConfigDir + "/character.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    PanelWindow {
        id: window
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        anchors {
            right: true
            bottom: true
        }
        margins {
            right: 24
            bottom: 24
        }
        implicitWidth: 430
        implicitHeight: 210
        color: "transparent"
        visible: root.openCodeRunning
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "mascot-code"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region { item: mascotItem }

        Item {
            id: mascotItem
            width: 180
            height: 180
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            Loader {
                anchors.fill: parent
                sourceComponent: root.character === "claude"
                    ? claudeComponent
                    : empoComponent
            }
        }

        Rectangle {
            id: bubble
            anchors.right: mascotItem.left
            anchors.rightMargin: 10
            anchors.verticalCenter: mascotItem.verticalCenter
            visible: opacity > 0
            opacity: root.line.length > 0 ? 1 : 0
            width: Math.min(bubbleText.implicitWidth + 20, 210)
            height: bubbleText.implicitHeight + 20
            radius: 12
            color: Qt.rgba(0.08, 0.10, 0.15, 0.92)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)

            Behavior on opacity {
                NumberAnimation { duration: 180 }
            }

            Text {
                id: bubbleText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, 190)
                text: root.line
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.family: "sans-serif"
                font.pixelSize: 13
                color: "#f2f5ff"
            }
        }
    }

    Component {
        id: empoComponent
        Empo {
            expression: root.displayState
            detail: root.detail
            active: root.openCodeRunning
            reducedMotion: false
            accent: "#ff9ecf"
            accentAlt: "#8fb8ff"
            ink: "#1a1a1f"
            errorColor: "#ff6b8a"
            successColor: "#8ee6b0"
            surfaceColor: "#1b1f2a"
            mutedColor: "#8b93a7"
            fontFamily: "sans-serif"
        }
    }

    Component {
        id: claudeComponent
        Claude {
            expression: root.displayState
            detail: root.detail
            active: root.openCodeRunning
            reducedMotion: false
        }
    }
}
