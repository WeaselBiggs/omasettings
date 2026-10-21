import QtQuick
import qs.Commons
import qs.Ui
import "." as Local

// The keyboard cursor for a row that is not a SettingRow.
//
// A device, a network and a binding are lists of things rather than one
// setting each, and their rows are built to look like it. Rather than force
// them into SettingRow's shape, this carries the same contract into them:
// drop one in, anchored over the row, and the row joins the cursor.
//
// It registers itself rather than its parent, and mirrors the geometry the
// window sorts by, so from the window's side it is simply another row.
Item {
  id: nav

  // Filled in by whoever drops it in.
  property var navKeys: []
  signal navActivate()
  signal navStep(int delta)

  // The window's side of the contract.
  property bool current: false
  property bool navBlocking: false
  property bool changed: false
  signal resetRequested()

  // Behind the row's own content: the band is a background, and drawing it
  // over the text would tint what it is meant to be pointing at.
  z: -1

  // What this row is called, for the search. A row named by the system rather
  // than by the source has to say so itself.
  property string searchText: ""
  readonly property bool searchHidden: navController !== null
    && navController.searching === true
    && !navController.rowMatches(searchText, "", "")

  property var navController: null

  // Told, not asked, the same as SettingRow: the window has to be handed
  // the block or it keeps reading Escape as "close" under a half-typed
  // passphrase.
  onNavBlockingChanged: {
    if (navController && navController.setNavBlocked !== undefined) navController.setNavBlocked(nav, navBlocking)
  }

  function findController() {
    var node = nav.parent
    while (node) {
      if (node.registerNavRow !== undefined) return node
      if (node.app !== undefined && node.app !== null
          && node.app.registerNavRow !== undefined) return node.app
      node = node.parent
    }
    return null
  }

  Component.onCompleted: {
    nav.navController = findController()
    if (nav.navController) nav.navController.registerNavRow(nav)
    // A row rebuilt while it already holds the keys (the Wi-Fi list under
    // an open prompt) had no controller when navBlocking was first set, so
    // the block is told again now that there is one to tell.
    if (nav.navBlocking && nav.navController && nav.navController.setNavBlocked !== undefined)
      nav.navController.setNavBlocked(nav, true)
  }

  Component.onDestruction: {
    // The Wi-Fi list is rebuilt every few seconds, so a row can go while it
    // holds the keyboard; left behind, the block would eat every key.
    if (nav.navController && nav.navController.setNavBlocked !== undefined) nav.navController.setNavBlocked(nav, false)
    if (nav.navController) nav.navController.unregisterNavRow(nav)
  }

  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: -Style.space(10)
    anchors.rightMargin: -Style.space(10)
    radius: Style.cornerRadius
    color: Qt.rgba(Local.Palette.accent.r, Local.Palette.accent.g, Local.Palette.accent.b, 0.14)
    visible: nav.current
  }
}
