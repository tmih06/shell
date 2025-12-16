import qs.components
import qs.components.containers
import qs.config
import Quickshell
import Quickshell.Wayland
import QtQuick

Item {
    id: root

    required property var visibilities
    required property Item panels

    visible: height > 0
    implicitWidth: Config.notifs.toplayer ? 0 : Math.max(panels.sidebar.width, content.implicitWidth)
    implicitHeight: Config.notifs.toplayer ? 0 : content.implicitHeight

    states: State {
        name: "hidden"
        when: root.visibilities.sidebar && Config.sidebar.enabled

        PropertyChanges {
            root.implicitHeight: 0
        }
    }

    transitions: Transition {
        Anim {
            target: root
            property: "implicitHeight"
            duration: Appearance.anim.durations.expressiveDefaultSpatial
            easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
        }
    }

    // Embedded content for normal layer
    Content {
        id: content

        visible: !Config.notifs.toplayer
        visibilities: root.visibilities
        panels: root.panels
    }

    // Overlay window for top layer
    Loader {
        active: Config.notifs.toplayer
        asynchronous: false

        sourceComponent: StyledWindow {
            id: overlayWindow

            screen: root.panels.screen
            name: "notifications-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            // Only anchor to top-right corner, with specific width/height
            anchors.top: true
            anchors.right: true
            
            implicitWidth: overlayContent.implicitWidth
            implicitHeight: overlayContent.implicitHeight

            // Add smooth transitions for window size changes
            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            
            Behavior on implicitHeight {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Content {
                id: overlayContent
                visibilities: root.visibilities
                panels: root.panels
                
                anchors.fill: parent
            }
        }
    }
}
