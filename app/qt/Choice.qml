import QtQuick
import QtQuick.Controls
ComboBox {
    id:control
    implicitHeight:34
    font.family:"JetBrains Mono";font.pixelSize:14
    contentItem:Text {textFormat:Text.PlainText;leftPadding:8;rightPadding:24;text:control.displayText;color:"#d0ceca";font:control.font;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
    background:Rectangle {color:"#111113";border.color:control.activeFocus ? "#b59e7b":"#343438"}
    indicator:Text {textFormat:Text.PlainText;x:control.width-20;anchors.verticalCenter:parent.verticalCenter;text:"⌄";color:"#93918c";font.pixelSize:14}
    popup:Popup {
        y:control.height+3;width:control.width;padding:4
        implicitHeight:Math.min(contentItem.implicitHeight+8,250)
        background:Rectangle {color:"#171719";border.color:"#555155"}
        contentItem:ListView {clip:true;implicitHeight:contentHeight;model:control.popup.visible ? control.delegateModel:null;currentIndex:control.highlightedIndex;ScrollIndicator.vertical:ScrollIndicator {}}
    }
    delegate:ItemDelegate {
        required property var modelData
        required property int index
        width:control.width-8;height:31
        contentItem:Text {textFormat:Text.PlainText;text:control.textRole ? modelData[control.textRole]:modelData;color:"#d0ceca";font:control.font;verticalAlignment:Text.AlignVCenter;elide:Text.ElideRight}
        background:Rectangle {color:parent.highlighted ? "#35302a":"transparent"}
        highlighted:control.highlightedIndex===index
    }
}
