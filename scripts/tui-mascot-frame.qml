import QtQuick
import Quickshell
import Quickshell.Wayland
import "characters"

/**
 * Renders one mascot expression on a transparent 340x340 stage.
 *
 * Used by generate-tui-assets.sh to build the PNG frames the /mascot TUI
 * picker shows. The shell wrapper copies this file into a temp directory next
 * to a `characters` symlink.
 */
ShellRoot {
    id: root

    readonly property string character: (Quickshell.env("MASCOT_CHARACTER") || "clawd").toLowerCase()
    readonly property string state: Quickshell.env("MASCOT_STATE") || "idle"
    readonly property string output: Quickshell.env("MASCOT_OUT") || "/tmp/mascot-tui-frame.png"

    PanelWindow {
        anchors { top: true; left: true }
        implicitWidth: 340
        implicitHeight: 340
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "mascot-tui-frame"

        Item {
            id: content
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "transparent"
            }

            Loader {
                x: 20
                y: 20
                width: 300
                height: 300
                sourceComponent: root.character === "empo" ? empoComponent : clawdComponent
            }
        }
    }

    Component {
        id: empoComponent
        Empo {
            expression: root.state
            active: true
            reducedMotion: true
        }
    }

    Component {
        id: clawdComponent
        Clawd {
            expression: root.state
            active: true
            reducedMotion: true
        }
    }

    Timer {
        interval: 900
        running: true
        onTriggered: {
            content.grabToImage(result => {
                console.log("saved", result.saveToFile(root.output))
                quitTimer.start()
            }, Qt.size(340, 340))
        }
    }

    Timer {
        id: quitTimer
        interval: 250
        onTriggered: Qt.quit()
    }
}
