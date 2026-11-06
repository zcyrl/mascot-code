import QtQuick
import Quickshell
import Quickshell.Wayland
import "characters"

/**
 * Offscreen-ish screenshot stage used by capture-character-screenshots.sh.
 *
 * Quickshell draws a 1100x650 black panel, waits for the expression to settle,
 * grabs the frame and quits. The shell wrapper copies this file into a temp
 * directory next to a `characters` symlink, then normalises the PNG size with
 * ImageMagick.
 */
ShellRoot {
    id: root

    readonly property string character: (Quickshell.env("MASCOT_CHARACTER") || "clawd").toLowerCase()
    readonly property string state: Quickshell.env("MASCOT_STATE") || "idle"
    readonly property string output: Quickshell.env("MASCOT_OUT") || "/tmp/mascot-shot.png"
    readonly property var lines: ({
        "idle": "",
        "thinking": "thinking after reading main.py",
        "reading": "reading main.py",
        "coding": "coding test.py",
        "running": "running pytest -q",
        "browsing": "browsing docs.opencode.ai",
        "happy": "done!",
        "sad": "error: tool failed",
        "sleeping": ""
    })

    PanelWindow {
        anchors { top: true; left: true }
        implicitWidth: 1100
        implicitHeight: 650
        color: "#000000"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "mascot-screenshot"

        Item {
            id: content
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "#000000"
            }

            Rectangle {
                id: bubble
                anchors.right: stage.left
                anchors.rightMargin: 14
                anchors.verticalCenter: stage.verticalCenter
                visible: opacity > 0
                opacity: root.lines[root.state] ? 1 : 0
                width: Math.min(bubbleText.implicitWidth + 24, 320)
                height: bubbleText.implicitHeight + 24
                radius: 12
                color: "#14161c"
                border.width: 1
                border.color: "#2c2f39"

                Text {
                    id: bubbleText
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, 290)
                    text: root.lines[root.state] ?? ""
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "sans-serif"
                    font.pixelSize: 15
                    color: "#f2f5ff"
                }
            }

            Item {
                id: stage
                x: 810
                y: 360
                width: 280
                height: 280

                Loader {
                    anchors.fill: parent
                    sourceComponent: root.character === "empo" ? empoComponent : clawdComponent
                }
            }
        }
    }

    Component {
        id: empoComponent
        Empo {
            expression: root.state
            detail: root.lines[root.state] ?? ""
            active: true
            reducedMotion: false
        }
    }

    Component {
        id: clawdComponent
        Clawd {
            expression: root.state
            detail: root.lines[root.state] ?? ""
            active: true
            reducedMotion: false
        }
    }

    Timer {
        interval: 1400
        running: true
        onTriggered: {
            content.grabToImage(result => {
                console.log("saved", result.saveToFile(root.output))
                quitTimer.start()
            }, Qt.size(1100, 650))
        }
    }

    Timer {
        id: quitTimer
        interval: 250
        onTriggered: Qt.quit()
    }
}
