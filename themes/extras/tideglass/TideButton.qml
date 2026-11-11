import QtQuick
import QtQuick.Controls
Button {
 id:button
 property bool accent:false
 implicitHeight:34
 implicitWidth:Math.max(86,label.implicitWidth+32)
 padding:10
 font.family:"Noto Sans"
 font.pixelSize:12
 hoverEnabled:true
 contentItem:Text {id:label;text:button.text;font:button.font;textFormat:Text.PlainText;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;color:!button.enabled ? "#657186":button.accent ? "#25303f":"#d1d7e5";wrapMode:Text.WordWrap;maximumLineCount:button.height>40 ? 2:1;elide:Text.ElideRight}
 background:Rectangle {radius:3;color:!button.enabled ? "#25303c":button.accent ? (button.down ? "#a49abf":button.hovered ? "#d0c0eb":"#bca6da"):(button.down ? "#4b556a":button.hovered ? "#39475c":"#273344");border.width:1;border.color:button.activeFocus ? "#dec6fa":"#52617a";Behavior on color {ColorAnimation {duration:100}}}
}
