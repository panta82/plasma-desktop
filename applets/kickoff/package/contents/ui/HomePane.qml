/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQml 2.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.extras 2.0 as PlasmaExtras

// A titled column on the Home tab, wrapping a single KickoffGridView
FocusScope {
    id: root

    property alias title: heading.text
    property string placeholderText
    property string placeholderIconName
    property alias viewComponent: viewLoader.sourceComponent
    readonly property KickoffGridView view: viewLoader.item

    implicitWidth: viewLoader.implicitWidth
    implicitHeight: heading.implicitHeight + viewLoader.implicitHeight

    PlasmaExtras.Heading {
        id: heading
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        topPadding: PlasmaCore.Units.smallSpacing * 2
        bottomPadding: PlasmaCore.Units.smallSpacing
        leftPadding: plasmoid.rootItem.backgroundMetrics.leftPadding
        rightPadding: plasmoid.rootItem.backgroundMetrics.rightPadding
        level: 4
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        textFormat: Text.PlainText
    }

    Loader {
        id: viewLoader
        focus: true
        anchors {
            left: parent.left
            right: parent.right
            top: heading.bottom
            bottom: parent.bottom
        }
    }

    // Only created when needed, like the search view's "No matches" message;
    // a hidden PlaceholderMessage still lays itself out and logs layout warnings.
    Loader {
        anchors.centerIn: viewLoader
        width: Math.max(0, viewLoader.width - (PlasmaCore.Units.largeSpacing * 2))
        active: root.view !== null && root.view.count === 0
        visible: active
        asynchronous: true
        sourceComponent: PlasmaExtras.PlaceholderMessage {
            iconName: root.placeholderIconName
            text: root.placeholderText
        }
    }
}
