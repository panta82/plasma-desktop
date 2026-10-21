/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick 2.15
import QtQuick.Templates 2.15 as T
import QtQml 2.15
import org.kde.plasma.core 2.0 as PlasmaCore

// Default tab: favorites, recent apps and recent files side by side
FocusScope {
    id: root

    readonly property int columnCount: Math.min(3, plasmoid.rootItem.minimumGridRowCount)
    readonly property var panes: [favoritesPane, recentAppsPane, recentFilesPane]
    // The pane that last had focus. It becomes the contentArea, so the search
    // field's arrow keys and Enter act on it.
    property HomePane currentPane: favoritesPane

    readonly property real paneWidth: Math.floor((width - separator1.width - separator2.width) / 3)

    implicitWidth: Math.max(favoritesPane.implicitWidth, recentAppsPane.implicitWidth, recentFilesPane.implicitWidth) * 3
        + separator1.implicitWidth + separator2.implicitWidth
    implicitHeight: Math.max(favoritesPane.implicitHeight, recentAppsPane.implicitHeight, recentFilesPane.implicitHeight)

    // Moves focus to the nearest non-empty pane in `step` direction (+1 is
    // towards the end of the reading order), keeping the row when possible.
    function focusAdjacentPane(fromPane, step) {
        let i = panes.indexOf(fromPane) + step
        while (i >= 0 && i < panes.length && (panes[i].view === null || panes[i].view.count === 0)) {
            i += step
        }
        if (i < 0 || i >= panes.length) {
            return false
        }
        const from = fromPane.view
        const target = panes[i].view
        const row = from.currentIndex >= 0 ? Math.floor(from.currentIndex / Math.max(from.view.columns, 1)) : 0
        const targetColumns = Math.max(target.view.columns, 1)
        const index = step > 0 ? row * targetColumns : row * targetColumns + targetColumns - 1
        target.currentIndex = Math.min(index, target.count - 1)
        target.currentItem.forceActiveFocus(step > 0 ? Qt.TabFocusReason : Qt.BacktabFocusReason)
        return true
    }

    function focusFirstItem() {
        currentPane = favoritesPane
        const view = favoritesPane.view
        if (view !== null && view.currentItem !== null) {
            view.currentItem.forceActiveFocus()
        }
    }

    // Arrow keys the grids don't handle bubble up to here
    Keys.onLeftPressed: event => {
        event.accepted = focusAdjacentPane(currentPane, LayoutMirroring.enabled ? 1 : -1)
    }
    Keys.onRightPressed: event => {
        event.accepted = focusAdjacentPane(currentPane, LayoutMirroring.enabled ? -1 : 1)
    }
    Keys.onUpPressed: plasmoid.rootItem.searchField.forceActiveFocus(Qt.BacktabFocusReason)
    Keys.onDownPressed: plasmoid.rootItem.footer.tabBar.forceActiveFocus(Qt.TabFocusReason)

    Row {
        anchors.fill: parent

        HomePane {
            id: favoritesPane
            focus: true
            width: root.paneWidth
            height: parent.height
            onActiveFocusChanged: if (activeFocus) {
                root.currentPane = favoritesPane
            }
            title: i18n("Favorites")
            placeholderIconName: "bookmarks"
            placeholderText: i18n("Right-click an application and choose \"Add to Favorites\"")
            viewComponent: DropAreaGridView {
                focus: true
                model: plasmoid.rootItem.rootModel.favoritesModel
                mayHaveScrollBar: true
                centerContent: true
                minimumColumnCount: root.columnCount
                showInactiveHighlight: false
            }
            KeyNavigation.tab: recentAppsPane
        }

        PlasmaCore.SvgItem {
            id: separator1
            height: parent.height
            implicitWidth: naturalSize.width
            elementId: "vertical-line"
            svg: KickoffSingleton.lineSvg
        }

        HomePane {
            id: recentAppsPane
            width: root.paneWidth
            height: parent.height
            onActiveFocusChanged: if (activeFocus) {
                root.currentPane = recentAppsPane
            }
            title: i18n("Recent Apps")
            placeholderIconName: "view-history"
            placeholderText: i18n("No recently used applications")
            viewComponent: KickoffGridView {
                focus: true
                model: plasmoid.rootItem.recentAppsModel
                mayHaveScrollBar: true
                centerContent: true
                minimumColumnCount: root.columnCount
                showInactiveHighlight: false
            }
            KeyNavigation.backtab: favoritesPane
            KeyNavigation.tab: recentFilesPane
        }

        PlasmaCore.SvgItem {
            id: separator2
            height: parent.height
            implicitWidth: naturalSize.width
            elementId: "vertical-line"
            svg: KickoffSingleton.lineSvg
        }

        HomePane {
            id: recentFilesPane
            width: root.width - x // absorb rounding from paneWidth
            height: parent.height
            onActiveFocusChanged: if (activeFocus) {
                root.currentPane = recentFilesPane
            }
            title: i18n("Recent Files")
            placeholderIconName: "document-open-recent"
            placeholderText: i18n("No recently opened files")
            viewComponent: KickoffGridView {
                focus: true
                model: plasmoid.rootItem.recentFilesModel
                mayHaveScrollBar: true
                centerContent: true
                minimumColumnCount: root.columnCount
                showInactiveHighlight: false
            }
            KeyNavigation.backtab: recentAppsPane
            KeyNavigation.tab: plasmoid.rootItem.footer ? plasmoid.rootItem.footer.nextItemInFocusChain() : null
        }
    }

    Connections {
        target: plasmoid
        function onExpandedChanged() {
            if (plasmoid.expanded) {
                // Let the tab bar and the views reset themselves first
                Qt.callLater(root.focusFirstItem)
            }
        }
    }

    // HomePage doesn't get destroyed when deactivated, so the bindings use
    // StackView.status and visible. This way the bindings are reset when
    // HomePage is Activated again.
    Binding {
        target: plasmoid.rootItem
        property: "sideBar"
        value: favoritesPane.view
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: plasmoid.rootItem
        property: "contentArea"
        value: root.currentPane.view
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
