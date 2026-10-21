import QtQuick
import qs.Commons
import qs.Ui
import "." as Local

// A multiplier such as a display scale or scroll speed, in steps of 0.05
// unless the row says otherwise: blur noise lives between 0 and 0.2, where a
// twentieth is a quarter of the whole range.
SettingRow {
  id: factorRow
  property real value: 1
  property real minimum: 0.1
  property real maximum: 3
  property real step: 0.05
  // Three at most: the state reads floats back rounded to three places, so
  // a finer readout would never agree with what comes back.
  readonly property int decimals: step < 0.01 ? 3 : 2
  signal committed(string next)

  // What was asked for is what the row shows until the state answers. A write
  // takes a refresh to come back, and reading `value` in the meantime is
  // reading the number from before the write — which is why a dragged slider
  // sprang back to where it started and then jumped to where it was put.
  property real pending: value
  property bool stepping: false
  // The value the state held when the write went out. An answer that is
  // neither that nor what was asked for is the system disagreeing — Hyprland
  // snaps a scale it cannot do exactly — and the row stops guessing rather
  // than showing a number the screen is not using.
  property real basis: value
  readonly property real effective: stepping ? pending : value
  readonly property real shown: factorSlider.dragging ? factorSlider.liveValue : effective

  onValueChanged: {
    if (!stepping) return
    if (Math.abs(value - pending) < step / 10 || Math.abs(value - basis) > step / 10) stepping = false
  }

  navKeys: [{ key: "\u2190\u2192", label: "Adjust" }]

  // One door for the keys and the slider: an optimistic value the drag did not
  // take part in is the bug this exists to fix.
  function commit(next) {
    var wanted = Math.max(factorRow.minimum, Math.min(factorRow.maximum, Math.round(next / factorRow.step) * factorRow.step))
    if (Math.abs(wanted - factorRow.effective) < factorRow.step / 10) return
    factorRow.pending = wanted
    factorRow.basis = factorRow.value
    factorRow.stepping = true
    factorRow.committed(wanted.toFixed(factorRow.decimals))
  }

  onNavStep: function(delta) {
    factorRow.commit(factorRow.effective + delta * factorRow.step)
  }

  Row {
    width: parent.width
    spacing: Style.space(10)

    PanelSlider {
      id: factorSlider
      width: parent.width - factorReadout.width - Style.space(10)
      anchors.verticalCenter: parent.verticalCenter
      minimum: factorRow.minimum
      maximum: factorRow.maximum
      step: factorRow.step
      value: Math.max(factorRow.minimum, Math.min(factorRow.maximum, factorRow.effective))
      enabled: factorRow.enabled
      onReleased: function(v) { factorRow.commit(v) }
    }

    Text {
      id: factorReadout
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(76)
      horizontalAlignment: Text.AlignRight
      text: "×" + factorRow.shown.toFixed(factorRow.decimals)
      color: Local.Palette.muted
      font.family: Local.Palette.fontFamily
      font.pixelSize: Style.font.caption
    }
  }
}
