import QtQuick
import QtQuick.Controls
TextField {
    id:control
    implicitHeight:34
    color:"#d0ceca";placeholderTextColor:"#666669"
    font.family:"JetBrains Mono";font.pixelSize:14
    padding:8;selectByMouse:true
    selectionColor:"#5c5141";selectedTextColor:"#f0ede8"
    background:Rectangle {color:"#111113";border.color:control.activeFocus ? "#b59e7b":"#343438";border.width:1}
}
