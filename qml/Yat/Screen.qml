/*******************************************************************************
* Copyright (c) 2013 Jørgen Lind
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
*******************************************************************************/

import QtQuick 2.5
import "qrc:/core/controls"

import Yat 1.0 as Yat

Item {
    id: root
    property alias screen: screenItem.screen
    property alias screenItem: screenItem

    property bool enableFocus: false
    onFocusChanged: { //transmit focus to child will result again in a FocusChanged event
        if(!enableFocus) {
            enableFocus = focus
            if(focus) {
                screenItem.forceActiveFocus() // we need active focus here
            } else {
                screenItem.focus = focus
            }
        } else {
            enableFocus = false
        }
    }

    Yat.TerminalScreen {
        id: screenItem

        property font font
        property real fontWidth: fontMetricText.paintedWidth
        property real fontHeight: fontMetricText.paintedHeight

        function emitKey(keyText, key, modifier) {
            screen.sendKey(keyText, key, modifier);
        }

        font.family: screen.platformName != "cocoa" ? "courier" : "menlo"
        anchors.fill: parent
    //    focus: true

        Component {
            id: textComponent
            Text {
            }
        }
        Component {
            id: cursorComponent
            Cursor {onBlinkingChanged: console.log("onBlinkingChanged")
            }
        }

        onFocusChanged: {
            if (focus) {
                keyboard.position = mapToItem(main).y + root.height
            }
        }

        Keys.onPressed: {
            if (event.key === Qt.Key_F1) {
                screen.printScreen()
            } else if(event.key === Qt.Key_F2) {
                screen.resetScreen()
            }
            screen.sendKey(event.text, event.key, event.modifiers);
            event.accepted = true;
        }

        Text {
            id: fontMetricText
            text: "B"
            font: parent.font
            visible: false
            textFormat: Text.PlainText
        }

        Rectangle {
            id: background
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: scroller.left
            anchors.bottom: parent.bottom
            color: screen.defaultBackgroundColor //design.defaultColorBackground
        }
        Flickable {
            id: flickable
            anchors.top: parent.top
            anchors.left: parent.left
            contentWidth: width
            contentHeight: textContainer.height
            interactive: true
            flickableDirection: Flickable.VerticalFlick
            contentY: ((screen.contentHeight - screen.height) * screenItem.fontHeight)
            clip: true

            Item {
                id: textContainer
                width: parent.width
                height: screen.contentHeight * screenItem.fontHeight

                Selection {z: textContainer.z + 0.1
                    characterHeight: screenItem.fontHeight
                    characterWidth: screenItem.fontWidth
                    screenWidth: screenItem.width

                    startX: screen.selection.startX
                    startY: screen.selection.startY

                    endX: screen.selection.endX
                    endY: screen.selection.endY

                    visible: screen.selection.enable
                }
            }

            Item {
                id: cursorContainer
                width: textContainer.width
                height: textContainer.height
            }


            onContentYChanged: {
                if(!atYEnd) screenItem.scrollBottom()
            }
            onContentHeightChanged: {
    //            if(!atYEnd) screenItem.scrollBottom()
                flickable.contentY = Math.max(0, flickable.contentHeight - flickable.height)
            }
        }

        function scrollBottom() {
                var top_line = Math.floor(Math.max(flickable.contentY,0) / screenItem.fontHeight);
                screen.ensureVisiblePages(top_line);
    //        flickable.contentY = Math.max(0, flickable.contentHeight - flickable.height)
        }

        StdScrollBar {
            id: scroller
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            orientation: Qt.Vertical

            onFocusChanged: {
                if(!focus) screenItem.focus = true
            }

            sliderSize: {
                Math.max(design.buttonHeight,
                         (flickable.height / (flickable.contentHeight)) * (height - (2 * design.buttonHeight)))
            }
            sliderPos: {
                if(flickable.contentHeight === flickable.height) {
                    design.buttonHeight
                } else {
                    ((flickable.contentY / (flickable.contentHeight-flickable.height)) * (height-((2*design.buttonHeight)+sliderSize))) + design.buttonHeight
                }
            }

            signal changePosition(string type,real x,real y)
            onChangePosition: {
                switch(type) {
                case "relPos": // 1 Line
                    flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height,
                                                              flickable.contentY + (y * screenItem.fontHeight)))
                    break;
                case "relPages": // 1 Page
                    flickable.contentY = Math.max(0, Math.min(flickable.contentHeight - flickable.height,
                                                              flickable.contentY + (y * flickable.height)))
                    break;
                case "absPos":
                    flickable.contentY = ((y-design.buttonHeight)/(height-(2*design.buttonHeight)-sliderSize)) *
                            (flickable.contentHeight-flickable.height)
                    break;
                default: break;
                }
            }
        }

        Connections {
            id: connections

            target: screen

            onFlash: {
                flashAnimation.start()
            }

            onReset: {
                resetScreenItems();
            }

            onTextCreated: {
                var textSegment = textComponent.createObject(screenItem,
                    {
                        "parent" : textContainer,
                        "objectHandle" : text,
                        "font" : screenItem.font,
                        "fontWidth" : screenItem.fontWidth,
                        "fontHeight" : screenItem.fontHeight,
                    });
            }

            onCursorCreated: {
                if (cursorComponent.status != Component.Ready) {
                    console.log(cursorComponent.errorString());
                    return;
                }
                var cursorVariable = cursorComponent.createObject(screenItem,
                    {
                        "parent" : cursorContainer,
                        "objectHandle" : cursor,
                        "fontWidth" : screenItem.fontWidth,
                        "fontHeight" : screenItem.fontHeight,
                    })
            }

            onRequestHeightChange: {
                terminalWindow.height = newHeight * screenItem.fontHeight;
                terminalWindow.contentItem.height = newHeight * screenItem.fontHeight;
            }

            onRequestWidthChange: {
                terminalWindow.width = newWidth * screenItem.fontWidth;
                terminalWindow.contentItem.width = newWidth * screenItem.fontWidth;
            }
        }

        onFontChanged: {
            setTerminalHeight();
            setTerminalWidth();
        }

        onWidthChanged: {
            setTerminalWidth();
        }
        onHeightChanged: {
            setTerminalHeight();
        }

        function setTerminalWidth() {
            if (fontWidth > 0) {
                var pty_width = Math.floor((width - scroller.width) / fontWidth);
                flickable.width = pty_width * fontWidth;
                screen.width = pty_width;
            }
        }

        function setTerminalHeight() {
            if (fontHeight > 0) {
                var pty_height = Math.floor(height / fontHeight);
                flickable.height = pty_height * fontHeight;
                screen.height = pty_height;
            }
        }

        Rectangle {
            id: flash
            z: 1.2
            anchors.fill: flickable
            color: "grey"
            opacity: 0
            SequentialAnimation {
                id: flashAnimation
                NumberAnimation {
                    target: flash
                    property: "opacity"
                    to: 1
                    duration: 75
                }
                NumberAnimation {
                    target: flash
                    property: "opacity"
                    to: 0
                    duration: 75
                }
            }
        }

        MouseArea {
            id: mousArea

            property int drag_start_x
            property int drag_start_y
            property bool active: false

            enabled: design.isTouch
            anchors.fill: flickable
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onPressAndHold: {console.log("mouse.button",mouse.button)
                if (mouse.button == Qt.LeftButton || mouse.button == Qt.NoButton) {
                    active = true
                    propagateComposedEvents = true
                    hoverEnabled = true;
                    var transformed_mouse = mapToItem(textContainer, mouse.x, mouse.y);
                    var character = Math.floor((transformed_mouse.x / screenItem.fontWidth));
                    var line = Math.floor(transformed_mouse.y / screenItem.fontHeight);
                    var start = Qt.point(character,line);
                    drag_start_x = character;
                    drag_start_y = line;
                    screen.selection.startX = character;
                    screen.selection.startY = line;
                    screen.selection.endX = character;
                    screen.selection.endY = line;
                }
            }

            onPositionChanged: {
                if(active) {
                    var transformed_mouse = mapToItem(textContainer, mouse.x, mouse.y);
                    var character = Math.floor(transformed_mouse.x / screenItem.fontWidth);
                    var line = Math.floor(transformed_mouse.y / screenItem.fontHeight);
                    var current_pos = Qt.point(character,line);
                    if (line < drag_start_y || (line === drag_start_y && character < drag_start_x)) {
                        screen.selection.startX = character;
                        screen.selection.startY = line;
                        screen.selection.endX = drag_start_x;
                        screen.selection.endY = drag_start_y;
                    } else {
                        screen.selection.startX = drag_start_x;
                        screen.selection.startY = drag_start_y;
                        screen.selection.endX = character;
                        screen.selection.endY = line;
                    }
                }
            }

            onReleased: {
                if (mouse.button == Qt.LeftButton || mouse.button == Qt.NoButton) {
                    active = false
                    propagateComposedEvents = false
                    hoverEnabled = false;
                    screen.selection.sendToSelection();
                }
            }

            onClicked: {
                if (mouse.button == Qt.MiddleButton) {
                    screen.selection.pasteFromSelection();
                }
            }

            onDoubleClicked: {
                if (mouse.button == Qt.LeftButton || mouse.button == Qt.NoButton) {
                    var transformed_mouse = mapToItem(textContainer, mouse.x, mouse.y);
                    var character = Math.floor(transformed_mouse.x / screenItem.fontWidth);
                    var line = Math.floor(transformed_mouse.y / screenItem.fontHeight);
                    screen.doubleClicked(character,line);
                }
            }
        }
    }
}
