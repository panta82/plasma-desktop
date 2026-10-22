/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.plasmoid
import QtQuick.Templates as T
import QtQml
import org.kde.plasma.components as PC3

EmptyPage {
    id: root
    // Fixed rather than measured: the Applications tab, whose category list
    // used to set this, isn't laid out until it's first shown.
    property real preferredSideBarWidth: KickoffSingleton.gridCellSize * 2

    contentItem: HorizontalStackView {
        id: stackView
        focus: true
        // Size for the largest tab so the popup doesn't resize when switching
        implicitWidth: Math.max(homePage.implicitWidth, applicationsPage.implicitWidth)
        implicitHeight: Math.max(homePage.implicitHeight, applicationsPage.implicitHeight)
        property int currentTab: 0
        // Not using components for Home and Applications to prevent them from being destroyed
        initialItem: HomePage {
            id: homePage
        }
        readonly property Item applicationsPageItem: ApplicationsPage {
            id: applicationsPage
            preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
        }
        Component {
            id: placesPage
            PlacesPage {
                preferredSideBarWidth: root.preferredSideBarWidth + kickoff.backgroundMetrics.leftPadding
                preferredSideBarHeight: applicationsPage.implicitSideBarHeight
            }
        }
        Connections {
            target: footer.tabBar
            function onCurrentIndexChanged() {
                const index = footer.tabBar.currentIndex
                // Slide in from the side of the tab being opened
                stackView.reverseTransitions = index > stackView.currentTab
                stackView.currentTab = index
                stackView.replace([homePage, applicationsPage, placesPage][index])
            }
        }
    }

    footer: Footer {
        id: footer
        Binding {
            target: kickoff
            property: "footer"
            value: footer
            restoreMode: Binding.RestoreBinding
        }
        // Eat down events to prevent them from reaching the contentArea or searchField
        Keys.onDownPressed: {}
    }
}
