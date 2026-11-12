import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Battery levels of wireless peripherals (mouse, keyboard, ...) from UPower.
// Logitech HID++ devices only report coarse levels, which UPower maps to fixed
// percentages (full 100, high 80, normal 55, low 10, critical 5), so the panel
// shows levels rather than percentages.
Panel {
  id: root
  moduleName: "sthurgren.peripherals"
  ipcTarget: "sthurgren.peripherals"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property color foreground: bar ? bar.foreground : Commons.Color.foreground
  readonly property color urgent: bar ? bar.urgent : Commons.Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property var devices: {
    var list = UPower.devices.values.filter(function(d) {
      return d && d.isPresent && !d.isLaptopBattery && !d.powerSupply
        && d.type !== UPowerDeviceType.LinePower
        && d.type !== UPowerDeviceType.Battery
        && d.type !== UPowerDeviceType.Ups
    })
    return list.sort(function(a, b) { return a.percentage - b.percentage })
  }
  readonly property var lowest: devices.length > 0 ? devices[0] : null
  readonly property bool lowestIsLow: lowest !== null && isLow(lowest)

  function isMouse(d) {
    return d.type === UPowerDeviceType.Mouse || /mouse/i.test(d.model)
  }

  function isLow(d) {
    return d.percentage < 0.2 && d.state !== UPowerDeviceState.Charging
  }

  // UPower reports some Logitech mice as keyboards, so check for a mouse first.
  function deviceGlyph(d) {
    if (isMouse(d)) return "󰍽"
    switch (d.type) {
      case UPowerDeviceType.Keyboard: return "󰌌"
      case UPowerDeviceType.Headset:
      case UPowerDeviceType.Headphones: return "󰋋"
      case UPowerDeviceType.Speakers:
      case UPowerDeviceType.OtherAudio: return "󰓃"
      case UPowerDeviceType.GamingInput: return "󰊴"
      case UPowerDeviceType.Phone: return "󰏲"
      case UPowerDeviceType.Tablet: return "󰓶"
      case UPowerDeviceType.Pen: return "󰏪"
      case UPowerDeviceType.Touchpad: return "󰟸"
      case UPowerDeviceType.Wearable: return "󰖉"
      default: return "󰂯"
    }
  }

  function levelText(d) {
    if (d.state === UPowerDeviceState.Charging) return strings.t("level.charging")
    var f = d.percentage
    if (f >= 0.95) return strings.t("level.full")
    if (f >= 0.7) return strings.t("level.high")
    if (f >= 0.4) return strings.t("level.good")
    if (f >= 0.08) return strings.t("level.low")
    return strings.t("level.critical")
  }

  function batteryGlyph(d) {
    if (d.state === UPowerDeviceState.Charging) return "󰂄"
    var f = d.percentage
    if (f < 0.08) return "󰂃"
    var glyphs = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    return glyphs[Math.max(0, Math.min(9, Math.round(f * 10) - 1))]
  }

  readonly property string summary: {
    if (devices.length === 0) return strings.t("noDevices")
    var low = devices.filter(isLow)
    if (low.length === 1) return strings.t("oneLow").arg(low[0].model)
    if (low.length > 1) return strings.tn("manyLow", low.length).arg(Commons.I18n.formatNumber(low.length))
    return strings.tn("deviceCount", devices.length).arg(Commons.I18n.formatNumber(devices.length))
  }

  visible: devices.length > 0
  implicitWidth: visible ? button.implicitWidth : 0
  implicitHeight: visible ? button.implicitHeight : 0

  onDevicesChanged: if (devices.length === 0) close()

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.lowest ? root.deviceGlyph(root.lowest) : "󰌌"
    foreground: root.lowestIsLow ? root.urgent : root.barForeground
    tooltipText: ""
    onPressed: function(b) { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened && root.visible
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      implicitHeight: column.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          title: strings.t("title")
          meta: root.summary
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: root.lowest ? root.deviceGlyph(root.lowest) : "󰌌"
              color: root.lowestIsLow ? root.urgent : hero.foreground
              font.family: hero.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Column {
          width: parent.width
          spacing: Style.space(8)

          Repeater {
            model: root.devices

            RowLayout {
              required property var modelData
              readonly property bool low: root.isLow(modelData)
              width: parent.width
              spacing: Style.space(12)

              Text {
                textFormat: Text.PlainText
                text: root.deviceGlyph(modelData)
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                Layout.preferredWidth: Style.space(22)
              }

              Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: modelData.model
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                elide: Text.ElideRight
              }

              Text {
                textFormat: Text.PlainText
                text: root.levelText(modelData)
                color: low ? root.urgent : root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }

              Text {
                textFormat: Text.PlainText
                text: root.batteryGlyph(modelData)
                color: low ? root.urgent : root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
              }
            }
          }
        }
      }
    }
  }
}
