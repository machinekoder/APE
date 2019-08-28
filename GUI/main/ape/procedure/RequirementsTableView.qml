import QtQuick 2.2
import QtQuick.Controls 1.4 as C1
import ape.core 1.0

C1.TableView {
  id: root
  property int editingRow: -1
  property bool readOnly: false

  selectionMode: C1.SelectionMode.SingleSelection

  signal valueUpdate(int row, string key, string value)

  onDoubleClicked: root.editingRow = row
  onModelChanged: root.editingRow = -1
  onCurrentRowChanged: root.editingRow = -1

  QtObject {
    id: d

    function valueUpdate(row, value) {
      var key = root.model[row]["key"]
      updateTimer.row = row
      updateTimer.key = key
      updateTimer.value = value
      updateTimer.start()
    }
  }

  Connections {
    target: nodeHandler
    ignoreUnknownSignals: true

    onAppEntryValueCopied: {
      var row = root.currentRow
      if (row > -1) {
        d.valueUpdate(row, value)
      }
    }
  }

  Timer {
    id: updateTimer
    property int row: 0
    property string key: ""
    property string value: ""
    interval: 50
    repeat: false

    onTriggered: {
      root.valueUpdate(row, key, value)
    }
  }

  C1.TableViewColumn {
    title: qsTr("Requirement")
    role: "key"
    width: root.width / 2
    resizable: true
  }

  C1.TableViewColumn {
    title: qsTr("Value")
    role: "value"
    width: root.width / 2 - 2
    resizable: true

    delegate: Item {
      id: item
      property bool editing: root.editingRow === styleData.row
      property bool modified: root.model ? (root.model[styleData.row] ? Boolean(
                                                                          root.model[styleData.row]["modified"]) : false) : false
      Text {
        anchors.fill: parent
        anchors.leftMargin: Style.singleMargin
        verticalAlignment: Text.AlignVCenter
        text: textInput.text
        elide: styleData.elideMode
        visible: !item.editing
        color: modified ? Style.green1 : styleData.textColor
      }

      TextInput {
        id: textInput
        anchors.fill: parent
        anchors.leftMargin: Style.singleMargin
        verticalAlignment: Text.AlignVCenter
        text: String(styleData.value)
        selectByMouse: true
        visible: item.editing
        readOnly: root.readOnly
        enabled: visible
        color: Style.blue1

        onEditingFinished: {
          root.editingRow = -1
          d.valueUpdate(styleData.row, text)
        }

        onVisibleChanged: {
          if (visible) {
            selectAll()
            forceActiveFocus()
          }
        }
      }
    }
  }
}
