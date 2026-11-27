pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services

StyledWindow {
    id: root

    readonly property int timeout: 3000
    readonly property int barWidth: ShellState.componentsFor(root.screen)?.bar?.implicitWidth ?? 0
    property string capturePath

    function capture(path: string, target: ShellScreen): void {
        root.dismiss();
        root.screen = target;
        root.capturePath = path;
        root.visible = true;
        timer.restart();
    }

    function dismiss(): void {
        timer.stop();
        root.visible = false;

        if (root.capturePath)
            CUtils.deleteFile(Qt.resolvedUrl(root.capturePath));

        root.capturePath = "";
    }

    function edit(): void {
        const path = root.capturePath;
        if (!path)
            return;

        timer.stop();
        root.visible = false;
        root.capturePath = "";
        Quickshell.execDetached(["swappy", "-f", path]);
    }

    name: "screenshot-preview"

    visible: false
    mask: root.visible ? null : empty
    margins.bottom: card.edgeMargin
    margins.left: root.barWidth + card.edgeMargin
    anchors.bottom: true
    anchors.left: true
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Region {
        id: empty
    }

    Timer {
        id: timer

        interval: root.timeout
        onTriggered: root.dismiss()
    }

    StyledRect {
        id: card

        readonly property int edgeMargin: Tokens.padding.large
        readonly property real maxWidth: Math.round((root.screen?.width ?? 0) / 4)
        readonly property real maxHeight: Math.round((root.screen?.height ?? 0) / 4)

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large
        clip: true
        implicitWidth: img.width + Tokens.padding.small * 2
        implicitHeight: img.height + Tokens.padding.small * 2
        anchors.fill: parent

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.edit()
        }

        Image {
            id: img

            readonly property real previewScale: implicitWidth > 0 && implicitHeight > 0 ? Math.min(1, card.maxWidth / implicitWidth, card.maxHeight / implicitHeight) : 1

            sourceSize: Qt.size(card.maxWidth * 2, card.maxHeight * 2)
            width: Math.round(implicitWidth * previewScale)
            height: Math.round(implicitHeight * previewScale)
            anchors.centerIn: parent
            asynchronous: true
            fillMode: Image.PreserveAspectFit
            source: root.capturePath ? Qt.resolvedUrl(root.capturePath) : ""
        }
    }
}
