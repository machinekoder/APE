import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Controls 1.4 as C1
import QtQuick.Layouts 1.3
import ape.core 1.0
import ape.controls 1.0
import ape.procedure 1.0

Item {
  id: root
  Layout.fillWidth: true
  Layout.fillHeight: true

  ProcedureModel {
    id: procedureModel
    procInterface: nodeHandler.procInterface
  }

  ImportExportDialog {
    id: importExportDialog
  }

  CreateDeviceDialog {
    id: createDeviceDialog

    onAccepted: {
      nodeHandler.procInterface.createDevice(name, type, requirements)
      nodeHandler.appInterface.refreshAppImage()
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.singleMargin

    RowLayout {
      Layout.preferredHeight: 200

      GroupBox {
        Layout.fillWidth: true
        Layout.fillHeight: true

        title: qsTr("Procedures")

        RowLayout {
          anchors.fill: parent

          ProcedureTreeView {
            id: treeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: procedureModel

            onCurrentIndexChanged: {
              if (currentIndex.valid) {
                instancesTableView.clearSelection()
                proclistTableView.clearSelection()
              }
            }

            onSelectedProcedureChanged: {
              if (selectedProcedure.length > 0) {
                var device = treeView.selectedProcedure[0]
                var proc = treeView.selectedProcedure[1]
                var reqs = nodeHandler.procInterface.getRequirements(device,
                                                                     proc)
                procReqView.model = reqs
              } else {
                procReqView.model = []
              }
            }
          }
        }
      }

      ColumnLayout {
        Button {
          text: qsTr("Create<br>Procedure")
          enabled: treeView.selectedProcedure.length > 0
          onClicked: {
            var row = instancesTableView.currentRow
            nodeHandler.procInterface.createProcedure(
                  treeView.selectedProcedure[0], treeView.selectedProcedure[1])
            nodeHandler.procInterface.refreshProcedures()
            instancesTableView.selectRow(row)
          }
        }

        Button {
          text: qsTr("Create<br>Device")
          onClicked: createDeviceDialog.open()
        }
      }

      GroupBox {
        title: qsTr("Requirements")
        Layout.fillWidth: true
        Layout.fillHeight: true

        RowLayout {
          anchors.fill: parent

          RequirementsTableView {
            id: procReqView
            Layout.fillHeight: true
            Layout.fillWidth: true
            readOnly: true
            visible: treeView.currentIndex.valid
                     || !(reqTableView.visible || instReqTableView.visible)
          }

          RequirementsTableView {
            id: reqTableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (proclistTableView.currentRow > -1)
                     && (proclistTableView.model.length > 0)

            onValueUpdate: {
              var tableRow = proclistTableView.currentRow
              var reqs = reqTableView.model
              reqs[row]["value"] = value
              nodeHandler.procInterface.updateProclistItem(
                    proclistTableView.currentRow, reqs)
              nodeHandler.procInterface.refreshProclist()
              proclistTableView.selectRow(tableRow)
            }

            model: (proclistTableView.currentRow
                    > -1) ? getModel(
                              proclistTableView.model[proclistTableView.currentRow]) : []

            function getModel(base) {
              // extend requirements with additional default requirements
              var reqs = nodeHandler.procInterface.getRequirements(
                    base["device"], base["procedure"])
              var base_reqs = base["requirements"]
              for (var i = 0; i < base_reqs.length; ++i) {
                var found = false
                for (var j = 0; j < reqs.length; ++j) {
                  if (reqs[j]["key"] == base_reqs[i]["key"]) {
                    reqs[j]["value"] = base_reqs[i]["value"]
                    found = true
                    break
                  }
                }
                if (!found) {
                  reqs.push(base_reqs[i])
                }
              }
              return reqs
            }
          }

          RequirementsTableView {
            id: instReqTableView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: (instancesTableView.currentRow > -1)
                     && (instancesTableView.model.length > 0)

            onValueUpdate: {
              var newModel = JSON.parse(JSON.stringify(model))
              newModel[row]["value"] = value
              newModel[row]["modified"] = true
              model = newModel
            }
          }
        }
      }
    }

    RowLayout {
      Layout.preferredHeight: 200

      GroupBox {
        Layout.fillWidth: true
        Layout.fillHeight: true

        title: qsTr("Instances")

        ColumnLayout {
          anchors.fill: parent

          ProceduresTableView {
            id: instancesTableView
            Layout.fillHeight: true
            Layout.fillWidth: true
            property string selectedUuid: (currentRow > -1)
                                          && model.length > 0 ? model[currentRow]['uuid'] : ''
            model: nodeHandler.procInterface.procedures

            onCurrentRowChanged: {
              if (currentRow > -1) {
                treeView.clearSelection()
                proclistTableView.clearSelection()
                var device = model[currentRow]['device']
                var proc = model[currentRow]['procedure']
                var reqs = nodeHandler.procInterface.getRequirements(device,
                                                                     proc)
                instReqTableView.model = reqs
              }
            }
          }

          RowLayout {
            Button {
              Layout.fillWidth: true
              text: qsTr("Execute")
              enabled: instancesTableView.currentRow > -1
              onClicked: {
                nodeHandler.procInterface.doProcedure(
                      instancesTableView.selectedUuid, instReqTableView.model)
                nodeHandler.appInterface.refreshProclog()
              }
            }
          }
        }
      }

      ColumnLayout {
        Button {
          text: qsTr("Move Up")
          enabled: proclistTableView.currentRow > 0
          onClicked: {
            var row = proclistTableView.currentRow
            nodeHandler.procInterface.moveProcedureUp(row)
            nodeHandler.procInterface.refreshProclist()
            proclistTableView.selectRow(row - 1)
          }
        }

        Button {
          text: qsTr("Move Down")
          enabled: (proclistTableView.currentRow > -1)
                   && (proclistTableView.currentRow < proclistTableView.rowCount - 1)
          onClicked: {
            var row = proclistTableView.currentRow
            nodeHandler.procInterface.moveProcedureDown(row)
            nodeHandler.procInterface.refreshProclist()
            proclistTableView.selectRow(row + 1)
          }
        }

        Item {
          height: Style.singleSpacing
        }

        Button {
          text: qsTr("Add\n>")
          enabled: instancesTableView.currentRow > -1
          onClicked: {
            var row = instancesTableView.currentRow
            nodeHandler.procInterface.addProclistItem(
                  instancesTableView.selectedUuid, instReqTableView.model)
            nodeHandler.procInterface.refreshProclist()
            instancesTableView.selectRow(row)
          }
        }

        Button {
          text: qsTr("Remove\n<")
          enabled: proclistTableView.currentRow > -1
          onClicked: {
            nodeHandler.procInterface.removeProclistItem(
                  proclistTableView.currentRow)
            nodeHandler.procInterface.refreshProclist()
          }
        }

        Button {
          text: qsTr("Clear\n<<")
          enabled: proclistTableView.rowCount > 0
          onClicked: {
            nodeHandler.procInterface.clearProclist()
            nodeHandler.procInterface.refreshProclist()
          }
        }

        Item {
          height: Style.singleSpacing
        }

        Button {
          text: qsTr("Remove\n*")
          enabled: instancesTableView.currentRow > -1
          onClicked: {
            nodeHandler.procInterface.removeProcedure(
                  instancesTableView.selectedUuid)
            nodeHandler.procInterface.refreshProcedures()
            nodeHandler.procInterface.refreshProclist()
          }
        }

        Button {
          text: qsTr("Clear All\n**")
          enabled: instancesTableView.rowCount > 0
          onClicked: {
            nodeHandler.procInterface.clearProcedures()
            nodeHandler.procInterface.refreshProcedures()
            nodeHandler.procInterface.refreshProclist()
          }
        }

        Button {
          text: qsTr("Reload")
          onClicked: {
            nodeHandler.procInterface.reloadProcedures()
            nodeHandler.procInterface.refreshEprocs()
            nodeHandler.procInterface.refreshProcedures()
            nodeHandler.procInterface.refreshProclist()
          }
        }

        Item {
          height: Style.singleSpacing
        }

        Button {
          text: qsTr("Export...")
          onClicked: {
            importExportDialog.openMode = false
            importExportDialog.open()
          }
        }

        Button {
          text: qsTr("Import...")
          onClicked: {
            importExportDialog.openMode = true
            importExportDialog.open()
          }
        }
      }

      GroupBox {
        Layout.fillWidth: true
        Layout.fillHeight: true
        title: qsTr("Proclist")

        ColumnLayout {
          anchors.fill: parent

          ProceduresTableView {
            id: proclistTableView
            Layout.fillHeight: true
            Layout.fillWidth: true
            model: nodeHandler.procInterface.proclist

            onCurrentRowChanged: {
              if (currentRow > -1) {
                treeView.clearSelection()
                instancesTableView.clearSelection()
              }
            }
          }

          RowLayout {
            Button {
              text: qsTr("Execute")
              Layout.fillWidth: true
              enabled: proclistTableView.currentRow > -1
              onClicked: {
                nodeHandler.procInterface.doProclistItem(
                      proclistTableView.currentRow)
                nodeHandler.appInterface.refreshProclog()
              }
            }

            Button {
              text: qsTr("Execute All")
              Layout.fillWidth: true
              enabled: proclistTableView.rowCount > 0
              onClicked: {
                nodeHandler.procInterface.doProclist()
                nodeHandler.appInterface.refreshProclog()
              }
            }
          }
        }
      }
    }
  }
}
