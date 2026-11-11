import QtQuick
import QtQuick.Controls
Button {
    id:button
    property string glyph:""
    property bool active:false
    property bool reducedMotion:false
    implicitHeight:26;implicitWidth:text ? Math.max(48,label.implicitWidth+16):26
    padding:5;hoverEnabled:true
    Accessible.name:text
    contentItem:Item {
        FieldIcon {visible:!!button.glyph;anchors.centerIn:parent;width:14;height:14;kind:button.glyph;ink:button.active ? "#d2c3ed":"#d1d5df";reducedMotion:button.reducedMotion}
        Text {id:label;visible:!!button.text;anchors.fill:parent;text:button.text;font.family:"Iosevka Nerd Font";font.pixelSize:12;horizontalAlignment:Text.AlignHCenter;verticalAlignment:Text.AlignVCenter;color:button.active ? "#e0d1f8":"#c6cbd8";elide:Text.ElideRight}
    }
    background:Rectangle {
        radius:2;color:button.down ? "#65738699":button.hovered || button.active ? "#45485870":"transparent"
        border.width:button.activeFocus ? 1:0;border.color:"#a99bc7"
        Behavior on color {ColorAnimation {duration:button.reducedMotion ? 0:100}}
    }
    opacity:enabled ? 1:.4
}
