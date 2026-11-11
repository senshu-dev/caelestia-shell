pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState

    readonly property bool shouldBeActive: screenState.clipboard
    property real offsetScale: shouldBeActive ? 0 : 1

    readonly property bool isFocused: (content.item as Content)?.isInputFocused ?? false

    visible: offsetScale < 1
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitWidth: 380
    implicitHeight: 520
    width: implicitWidth
    height: implicitHeight
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.leftMargin: Tokens.padding.large + Config.border.thickness
        anchors.bottomMargin: Tokens.padding.large + Config.border.thickness

        active: root.shouldBeActive || root.visible

        sourceComponent: Content {
            screenState: root.screenState
        }
    }
}
