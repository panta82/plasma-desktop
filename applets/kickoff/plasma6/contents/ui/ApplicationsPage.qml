/*
 * SPDX-FileCopyrightText: 2021 Noah Davis <noahadvs@gmail.com>
 * SPDX-License-Identifier: LGPL-2.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.plasma.plasmoid
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQml
import org.kde.plasma.components as PC3
import org.kde.plasma.private.kicker as Kicker

// Apps tab: categories and their apps on the left, all apps A-Z on the right
BasePage {
    id: root
    sideBarComponent: KickoffListView {
        id: sideBar
        focus: true // needed for Loaders
        model: kickoff.categoriesModel
        // needed otherwise app displayed at top-level will show a first character as group.
        section.property: ""
        delegate: KickoffListDelegate {
            width: view.availableWidth
            isCategoryListItem: true
        }
    }
    contentAreaComponent: FocusScope {
        id: contentArea

        // Reading count makes these re-evaluate after the models (re)populate.
        // modelForRow() returns null for top-level apps, which launch from the sidebar instead.
        readonly property Kicker.AppsModel categoryModel: kickoff.categoriesModel.count > 0 && root.sideBarItem
            ? kickoff.categoriesModel.modelForRow(root.sideBarItem.currentIndex) : null
        readonly property Kicker.AppsModel allAppsModel: kickoff.rootModel.count > 1
            ? kickoff.rootModel.modelForRow(1) : null // row 0 is favorites

        property bool allAppsFocused: false
        // The view the search field's arrow keys and Enter act on
        readonly property Item currentView: allAppsFocused ? allAppsStack.currentItem : categoryLoader.item

        readonly property real paneImplicitWidth: KickoffSingleton.gridCellSize * Math.min(3, kickoff.minimumGridRowCount)
            + kickoff.backgroundMetrics.leftPadding + kickoff.backgroundMetrics.rightPadding
        implicitWidth: paneImplicitWidth * 2 + separator.implicitWidth
        implicitHeight: Math.max(categoryLoader.implicitHeight, allAppsStack.implicitHeight)

        function focusView(view, reason) {
            if (view.currentItem) {
                view.currentItem.forceActiveFocus(reason)
            } else {
                view.forceActiveFocus(reason)
            }
        }

        // Unhandled Left on the category view keeps bubbling to BasePage, which focuses the sidebar
        Keys.onLeftPressed: event => {
            const toAllApps = LayoutMirroring.enabled && !allAppsFocused
            const toCategory = !LayoutMirroring.enabled && allAppsFocused
            if (toAllApps || toCategory) {
                focusView(toAllApps ? allAppsStack.currentItem : categoryLoader.item, Qt.BacktabFocusReason)
            } else {
                event.accepted = false
            }
        }
        Keys.onRightPressed: event => {
            const toAllApps = !LayoutMirroring.enabled && !allAppsFocused
            const toCategory = LayoutMirroring.enabled && allAppsFocused
            if (toAllApps || toCategory) {
                focusView(toAllApps ? allAppsStack.currentItem : categoryLoader.item, Qt.TabFocusReason)
            } else {
                event.accepted = false
            }
        }

        Loader {
            id: categoryLoader
            focus: true
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            width: Math.round((parent.width - separator.width) / 2)
            sourceComponent: Plasmoid.configuration.applicationsDisplay === 0 ? categoryGridComponent : categoryListComponent
            onActiveFocusChanged: if (activeFocus) {
                contentArea.allAppsFocused = false
            }
        }

        KSvg.SvgItem {
            id: separator
            anchors {
                left: categoryLoader.right
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: naturalSize.width
            elementId: "vertical-line"
            svg: KickoffSingleton.lineSvg
        }

        VerticalStackView {
            id: allAppsStack
            anchors {
                left: separator.right
                right: parent.right
                top: parent.top
                bottom: parent.bottom
            }
            onActiveFocusChanged: if (activeFocus) {
                contentArea.allAppsFocused = true
            }

            popEnter: Transition {
                NumberAnimation {
                    property: "x"
                    from: 0.5 * root.width
                    to: 0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            pushEnter: Transition {
                NumberAnimation {
                    property: "x"
                    from: 0.5 * -root.width
                    to: 0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.OutCubic
                }
            }

            initialItem: allAppsListComponent
        }

        Component {
            id: categoryListComponent
            KickoffListView {
                objectName: "applicationsListView"
                mainContentView: true
                focus: true
                model: contentArea.categoryModel
                section.property: ""
            }
        }

        Component {
            id: categoryGridComponent
            KickoffGridView {
                objectName: "applicationsGridView"
                focus: true
                model: contentArea.categoryModel
            }
        }

        Component {
            id: allAppsListComponent
            KickoffListView {
                id: allAppsListView
                objectName: "allAppsListView"
                mainContentView: true
                focus: true
                model: contentArea.allAppsModel
                section.property: "group"
                section.criteria: ViewSection.FirstCharacter
                hasSectionView: true

                onShowSectionViewRequested: sectionName => {
                    allAppsStack.push(allAppsSectionViewComponent, {
                        "currentSection": sectionName,
                        "parentView": allAppsListView
                    });
                }
            }
        }

        Component {
            id: allAppsSectionViewComponent
            SectionView {
                model: contentArea.allAppsModel.sections

                onHideSectionViewRequested: index => {
                    allAppsStack.pop();
                    allAppsStack.currentItem.view.positionViewAtIndex(index, ListView.Beginning);
                    allAppsStack.currentItem.currentIndex = index;
                }
            }
        }
    }
    // ApplicationsPage doesn't get destroyed when deactivated, so the bindings use
    // StackView.status and visible. This way the bindings are reset when
    // ApplicationsPage is Activated again.
    Binding {
        target: kickoff
        property: "sideBar"
        value: root.sideBarItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: kickoff
        property: "contentArea"
        value: root.contentAreaItem.currentView // NOT just root.contentAreaItem
        when: root.T.StackView.status === T.StackView.Active && root.visible
        restoreMode: Binding.RestoreBinding
    }
}
