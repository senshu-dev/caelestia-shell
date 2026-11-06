import QtQuick
import Caelestia.Config
import qs.components

Item {
    id: root

    required property ScreenState screenState
    required property bool fullscreen
    required property Item sidebarPanel
    property alias osdPanel: content.osdPanel
    property alias sessionPanel: content.sessionPanel
    property alias utilitiesPanel: content.utilitiesPanel

    visible: height > 0 && Config.notifs.enabled
    anchors.topMargin: -5
    implicitWidth: Config.notifs.enabled ? Math.max(sidebarPanel.width, content.implicitWidth) : 0
    implicitHeight: Config.notifs.enabled ? content.implicitHeight - anchors.topMargin : 0

    Content {
        id: content

        anchors.topMargin: -root.anchors.topMargin
        screenState: root.screenState
        fullscreen: root.fullscreen
    }
}
