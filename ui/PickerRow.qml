import QtQuick
import qs.Commons
import qs.Ui
import "." as Local

SettingRow {
  id: pickerRow
  property var options: []
  property string value: ""
  property bool searchable: false
  signal picked(string next)

  // Options arrive either as bare strings or as {value,label} objects.
  readonly property var normalized: {
    var out = []
    var list = pickerRow.options || []
    for (var i = 0; i < list.length; i++) {
      var entry = list[i]
      if (entry && typeof entry === "object") out.push(entry)
      else out.push({ value: String(entry), label: String(entry) })
    }
    return out
  }

  // Space opens the list, the way clicking the control would; stepping picks
  // a neighbour without opening anything. While the list is open it owns the
  // keyboard — its own Up/Down and Escape are the ones that should run.
  navKeys: [{ key: "Space", label: "Open list" }, { key: "\u2190\u2192", label: "Choose" }]

  onNavActivate: if (dropdownLoader.item) dropdownLoader.item.open()
  navBlocking: dropdownLoader.item ? dropdownLoader.item.popupOpen === true : false

  onNavStep: function(delta) {
    var list = pickerRow.normalized
    if (list.length === 0) return
    var at = 0
    for (var i = 0; i < list.length; i++)
      if (String(list[i].value) === String(pickerRow.value)) { at = i; break }
    var next = Math.max(0, Math.min(list.length - 1, at + delta))
    if (next !== at) pickerRow.picked(String(list[next].value))
  }

  Loader {
    id: dropdownLoader
    width: parent.width
    sourceComponent: pickerRow.searchable ? searchableComponent : plainComponent
  }

  Component {
    id: plainComponent
    Dropdown {
      id: plainDrop
      width: parent ? parent.width : 0
      showLabel: false
      fontFamily: Local.Palette.fontFamily
      value: pickerRow.value
      options: pickerRow.normalized
      onChanged: function(next) { pickerRow.picked(next) }
      // The kit assigns `value` on a pick, which drops the binding above, so
      // from then on the row is resynced by hand: when the value moves (a
      // reset, a change made elsewhere) and when a write finishes without
      // moving it (a refused pick). Not re-bound on the pick itself: that
      // snaps the control back to the old value for as long as the apply
      // takes, seconds for a theme.
      Connections {
        target: pickerRow
        function onValueChanged() { plainDrop.value = pickerRow.value }
      }
      Connections {
        target: pickerRow.nav
        function onBusyChanged() { if (pickerRow.nav && !pickerRow.nav.busy) plainDrop.value = pickerRow.value }
      }
    }
  }

  Component {
    id: searchableComponent
    SearchableDropdown {
      id: searchDrop
      width: parent ? parent.width : 0
      showLabel: false
      fontFamily: Local.Palette.fontFamily
      placeholderText: "Search…"
      value: pickerRow.value
      options: pickerRow.normalized
      onChanged: function(next) { pickerRow.picked(next) }
      // Same resync as the plain dropdown above, for the same reason.
      Connections {
        target: pickerRow
        function onValueChanged() { searchDrop.value = pickerRow.value }
      }
      Connections {
        target: pickerRow.nav
        function onBusyChanged() { if (pickerRow.nav && !pickerRow.nav.busy) searchDrop.value = pickerRow.value }
      }
    }
  }
}
