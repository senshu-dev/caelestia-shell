pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services
import qs.utils

StyledRect {
    id: root

    property bool compact
    property bool expanded

    implicitHeight: layout.implicitHeight + layout.anchors.margins * 2

    onCompactChanged: {
        if (root.compact)
            root.expanded = false;
    }

    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.medium

        RowLayout {
            spacing: Tokens.spacing.extraSmall

            MaterialIcon {
                text: "tune"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("App volumes")
                font: Tokens.font.body.medium
                elide: Text.ElideRight
            }

            StyledText {
                visible: Audio.streams.length > 0
                text: Tr.trN("%n app", "%n apps", Audio.streams.length)
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
            }

            IconButton {
                visible: root.compact
                icon: root.expanded ? "unfold_less" : "unfold_more"
                type: IconButton.Text
                onClicked: root.expanded = !root.expanded
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: Audio.streams.length === 0
            text: Tr.tr("No apps playing audio")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
        }

        StyledListView {
            id: streams

            Layout.fillWidth: true
            Layout.preferredHeight: root.compact && !root.expanded ? 0 : implicitHeight
            implicitHeight: Math.min(streams.contentHeight, 3 * 56 + 2 * Tokens.spacing.medium)
            visible: Audio.streams.length > 0
            clip: true
            spacing: Tokens.spacing.medium
            model: Audio.streams

            StyledScrollBar.vertical: StyledScrollBar {
                flickable: streams
            }

            delegate: AppVolumeRow {
                width: streams.width
            }

            Behavior on Layout.preferredHeight {
                Anim {}
            }
        }
    }
}
