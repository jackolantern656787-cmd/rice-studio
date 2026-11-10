import QtQuick
import QtQuick.Controls
Button {
 id:control
 property bool primary:false
 property bool quiet:false
 property bool danger:false
 property bool reducedMotion:typeof studio!=="undefined" ? studio.reducedMotion:false
 implicitHeight:36
 implicitWidth:Math.max(64,label.implicitWidth+28)
 leftPadding:14;rightPadding:14;hoverEnabled:true
 scale:down ? .975:1
 Behavior on scale {NumberAnimation {duration:control.reducedMotion ? 0:130;easing.type:Easing.OutCubic}}
 contentItem:Text {textFormat:Text.PlainText;id:label;text:control.text;color:!control.enabled ? "#66636b":control.primary ? "#191715":control.danger ? "#e2a28b":"#ddd5ca";font.family:"JetBrains Mono";font.pixelSize:12;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
 background:Rectangle {
  radius:2
  color:!control.enabled ? "#191a1d":control.primary ? (control.down ? "#bd9267":control.hovered ? "#efc99b":"#d6ab7d"):control.hovered ? "#2b2c30":control.quiet ? "transparent":"#202125"
  border.width:control.quiet && !control.activeFocus ? 0:1
  border.color:control.activeFocus ? "#fff0d4":control.primary ? "#d6ab7d":control.hovered ? "#6c6257":"#3c3b40"
  Behavior on color {ColorAnimation {duration:control.reducedMotion ? 0:160}}
  Behavior on border.color {ColorAnimation {duration:control.reducedMotion ? 0:160}}
  Rectangle {anchors.bottom:parent.bottom;anchors.left:parent.left;anchors.right:parent.right;height:2;color:control.primary ? "#9d734e":"#a58261";opacity:control.hovered && !control.down ? .8:0;Behavior on opacity {NumberAnimation {duration:control.reducedMotion ? 0:150}}}
 }
 Accessible.name:text
 ToolTip.visible:hovered && text.length>32
 ToolTip.text:text
}
