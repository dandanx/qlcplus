/*
  Q Light Controller Plus
  TreeNodeDelegate.qml

  Copyright (c) Massimo Callegari

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0.txt

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

import QtQuick 2.2

import "."

Column
{
    id: nodeContainer
    width: 350
    //height: nodeLabel.height + nodeChildrenView.height

    property string textLabel
    property string nodePath
    property var nodeChildren
    property bool isExpanded: false
    property bool isSelected: false
    property string nodeIcon: "qrc:/folder.svg"
    property string childrenDelegate: "qrc:/FunctionDelegate.qml"

    signal toggled(bool expanded, int newHeight)
    signal clicked(int ID, var qItem, int mouseMods)
    signal doubleClicked(int ID, int Type)
    signal pathChanged(string oldPath, string newPath)

    Rectangle
    {
        color: nodeIconImg.visible ? "transparent" : UISettings.sectionHeader
        width: nodeContainer.width
        height: UISettings.listItemHeight

        // selection rectangle
        Rectangle
        {
            anchors.fill: parent
            radius: 3
            color: UISettings.highlight
            visible: isSelected
        }

        Image
        {
            id: nodeIconImg
            visible: nodeIcon == "" ? false : true
            width: visible ? parent.height : 0
            height: parent.height
            source: nodeIcon
        }

        TextInput
        {
            property string originalText

            id: nodeLabel
            x: nodeIconImg.width + 1
            z: 0
            width: parent.width - nodeIconImg.width - 1
            height: UISettings.listItemHeight
            readOnly: true
            text: textLabel
            verticalAlignment: TextInput.AlignVCenter
            color: UISettings.fgMain
            font.family: UISettings.robotoFontName
            font.pixelSize: UISettings.textSizeDefault
            echoMode: TextInput.Normal
            selectByMouse: true
            selectionColor: "#4DB8FF"
            selectedTextColor: "#111"

            function disableEditing()
            {
                z = 0
                select(0, 0)
                readOnly = true
                cursorVisible = false
            }

            onEditingFinished:
            {
                disableEditing()
                nodeContainer.pathChanged(nodePath, text)
            }
            Keys.onEscapePressed:
            {
                disableEditing()
                nodeLabel.text = originalText
            }
        }

        Timer
        {
            id: clickTimer
            interval: 200
            repeat: false
            running: false

            property int modifiers: 0

            onTriggered:
            {
                isExpanded = !isExpanded
                nodeContainer.clicked(-1, nodeContainer, modifiers)
                modifiers = 0
            }
        }

        MouseArea
        {
            anchors.fill: parent
            height: UISettings.listItemHeight
            onClicked:
            {
                clickTimer.modifiers = mouse.modifiers
                clickTimer.start()
            }
            onDoubleClicked:
            {
                clickTimer.stop()
                clickTimer.modifiers = 0
                nodeLabel.originalText = textLabel
                nodeLabel.z = 5
                nodeLabel.readOnly = false
                nodeLabel.forceActiveFocus()
                nodeLabel.cursorPosition = nodeLabel.text.length
                nodeLabel.cursorVisible = true
            }
        }
    }

    Repeater
    {
        id: nodeChildrenView
        visible: isExpanded
        width: nodeContainer.width - 20
        model: visible ? nodeChildren : null
        delegate:
            Component
            {
                Loader
                {
                    id: childrenLoader
                    width: nodeChildrenView.width
                    x: 20
                    //height: 35
                    source: hasChildren ? "qrc:/TreeNodeDelegate.qml" : childrenDelegate
                    onLoaded:
                    {
                        item.textLabel = label
                        item.isSelected = Qt.binding(function() { return isSelected })

                        if (hasChildren)
                        {
                            item.nodePath = nodePath + "/" + path
                            item.isExpanded = isExpanded
                            item.nodeChildren = childrenModel
                            item.nodeIcon = nodeContainer.nodeIcon
                            item.childrenDelegate = childrenDelegate

                            console.log("Item path: " + item.nodePath + ", label: " + label)
                        }
                        else
                        {
                            if (item.cRef)
                                item.cRef = classRef
                        }
                    }
                    Connections
                    {
                        target: item
                        onClicked:
                        {
                            if (qItem == item)
                            {
                                model.isSelected = (mouseMods & Qt.ControlModifier) ? 2 : 1
                                if (model.hasChildren)
                                    model.isExpanded = item.isExpanded
                            }
                            nodeContainer.clicked(ID, qItem, mouseMods)
                        }
                    }
                    Connections
                    {
                        ignoreUnknownSignals: true
                        target: item
                        onDoubleClicked: nodeContainer.doubleClicked(ID, Type)
                    }
                    Connections
                    {
                        ignoreUnknownSignals: true
                        target: item
                        onPathChanged: nodeContainer.pathChanged(oldPath, newPath)
                    }
                }
        }
    }
}
