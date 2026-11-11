pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Scheme
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    required property ScreenState screenState

    readonly property bool isInputFocused: searchBar.activeFocus
    property var rawList: []

    function reload(): void {
        listProc.running = true;
    }

    function filterList(): void {
        listModel.clear();
        const q = searchBar.text.toLowerCase().trim();
        for (let i = 0; i < rawList.length; i++) {
            const line = rawList[i];
            if (!line)
                continue;
            const tabIdx = line.indexOf("\t");
            if (tabIdx === -1)
                continue;
            const clipId = line.slice(0, tabIdx).trim();
            const clipPreview = line.slice(tabIdx + 1).trim();
            if (q && !clipPreview.toLowerCase().includes(q))
                continue;
            const isBinary = clipPreview.startsWith("[[ binary data");
            listModel.append({
                clipId: clipId,
                clipPreview: isBinary ? Tr.tr("Image (%1)").arg(clipPreview.replace(/^\[\[\s*binary data\s*/, "").replace(/\s*\]\]$/, "")) : clipPreview,
                isImage: isBinary,
                fullLine: line
            });
        }
    }

    Connections {
        target: root.screenState
        function onClipboardChanged(): void {
            if (root.screenState.clipboard) {
                root.reload();
                searchBar.forceActiveFocus();
            }
        }
    }

    Component.onCompleted: root.reload()

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim();
                root.rawList = raw ? raw.split("\n") : [];
                root.filterList();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.medium

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            MaterialIcon {
                text: "content_paste"
                color: Colours.tPalette.primary
                fontStyle: Tokens.font.icon.medium
            }

            StyledText {
                text: Tr.tr("Clipboard")
                font: Tokens.font.title.small
                color: Colours.tPalette.onSurface
            }

            StyledText {
                text: `(${listModel.count})`
                font: Tokens.font.label.medium
                color: Colours.tPalette.outline
            }

            Item {
                Layout.fillWidth: true
            }

            IconButton {
                icon: "delete_sweep"
                type: IconButton.Tonal
                onClicked: {
                    Quickshell.execDetached(["cliphist", "wipe"]);
                    root.rawList = [];
                    listModel.clear();
                }
            }

            IconButton {
                icon: "close"
                type: IconButton.Text
                onClicked: root.screenState.clipboard = false
            }
        }

        // Search Bar
        SearchBar {
            id: searchBar

            Layout.fillWidth: true
            placeholderText: Tr.tr("Search clipboard...")

            onTextChanged: root.filterList()

            Keys.onEscapePressed: {
                if (text) {
                    text = "";
                } else {
                    root.screenState.clipboard = false;
                }
            }
        }

        // Content List
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: listView

                anchors.fill: parent
                clip: true
                spacing: Tokens.spacing.small

                model: ListModel {
                    id: listModel
                }

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: listView
                }

                delegate: StyledRect {
                    id: itemDelegate

                    required property string clipId
                    required property string clipPreview
                    required property bool isImage
                    required property string fullLine
                    required property int index

                    width: listView.width
                    height: 48
                    radius: Tokens.rounding.large
                    color: itemState.hovered ? Colours.tPalette.surfaceContainerHigh : Colours.tPalette.surfaceContainerLow

                    StateLayer {
                        id: itemState

                        anchors.fill: parent
                        radius: Tokens.rounding.large
                        onClicked: {
                            Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist decode | wl-copy", "--", itemDelegate.fullLine]);
                            root.screenState.clipboard = false;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Tokens.padding.medium
                        anchors.rightMargin: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: itemDelegate.isImage ? "image" : "description"
                            color: itemDelegate.isImage ? Colours.tPalette.tertiary : Colours.tPalette.secondary
                            fontStyle: Tokens.font.icon.small
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: itemDelegate.clipPreview
                            font: Tokens.font.body.medium
                            color: Colours.tPalette.onSurface
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        IconButton {
                            icon: "delete"
                            type: IconButton.Text
                            font: Tokens.font.icon.small
                            onClicked: {
                                const lineToDelete = itemDelegate.fullLine;
                                Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "--", lineToDelete]);
                                root.rawList = root.rawList.filter(l => l !== lineToDelete);
                                listModel.remove(itemDelegate.index);
                            }
                        }
                    }
                }

                // Empty state
                StyledText {
                    anchors.centerIn: parent
                    visible: listModel.count === 0 && !listProc.running
                    text: searchBar.text ? Tr.tr("No matching clipboard items") : Tr.tr("Clipboard history is empty")
                    font: Tokens.font.body.medium
                    color: Colours.tPalette.outline
                }
            }
        }
    }
}
