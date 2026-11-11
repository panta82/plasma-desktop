/*
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtCore
import org.kde.kitemmodels as KItemModels
import org.kde.kirigamiaddons.formcard as FormCard

// Plasma's recent-app registry can outlive the launcher file after an uninstall.
KItemModels.KSortFilterProxyModel {
    id: root

    // Keep favorites in the list; the delegates use rootModel for favorite actions.
    readonly property var favoritesModel: null

    filterRoleName: "favoriteId"
    filterRowCallback: (sourceRow, sourceParent) => {
        const sourceIndex = root.sourceModel.index(sourceRow, 0, sourceParent);
        const storageId = root.sourceModel.data(sourceIndex, root.filterRole);
        return !!storageId && root.launcherExists(storageId);
    }

    function launcherExists(storageId, directory = "") {
        if (storageId.startsWith("/")) {
            return FormCard.FileHelper.fileExists(storageId);
        }
        if (StandardPaths.locate(StandardPaths.ApplicationsLocation, directory + storageId).toString() !== "") {
            return true;
        }

        // Desktop IDs flatten subdirectories with hyphens, e.g. wine-Programs-app.desktop.
        for (let separator = storageId.indexOf("-"); separator >= 0; separator = storageId.indexOf("-", separator + 1)) {
            const subdirectory = directory + storageId.slice(0, separator) + "/";
            if (StandardPaths.locate(StandardPaths.ApplicationsLocation, subdirectory, StandardPaths.LocateDirectory).toString() !== ""
                && root.launcherExists(storageId.slice(separator + 1), subdirectory)) {
                return true;
            }
        }
        return false;
    }

    // Delegates pass proxy rows, so map launches and context-menu actions back.
    function trigger(row, actionId, argument) {
        const sourceIndex = root.mapToSource(root.index(row, 0));
        return sourceIndex.valid && root.sourceModel.trigger(sourceIndex.row, actionId, argument);
    }
}
