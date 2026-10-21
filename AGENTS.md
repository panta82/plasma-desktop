# AGENTS.md

This is a personal fork of KDE's `plasma-desktop` and is not meant to go upstream.
It is based on Plasma 5.27 (Kubuntu `4:5.27.12`). The work lives on the `kickoff-mods`
branch and only touches the Kickoff start menu (`applets/kickoff/`).

## Additions

1. **New menu** – a reworked Kickoff layout with three tabs:
   - **Home** (the default tab): favorites, recent apps and recent files in three side-by-side panes
     (`HomePage.qml`, `HomePane.qml`).
   - **Apps**: categories and their apps on the left, all apps A–Z on the right (`ApplicationsPage.qml`).
   - **Places**: unchanged from upstream.

## Related forks

- **`panta82/kactivitymanagerd`**, branch `5.27.11-fixes`: fixes per-application blocking in
  System Settings → Recent Files, which the Home tab's recent apps and files depend on. Build and
  install steps are in that repo's `AGENTS.md`.
