import QtQuick
import QtQuick.Controls
Slider {
    id:slider
    property bool reducedMotion:false
    // Minimal reference slider: change these four colors here.
    property color fillColor:"#c5c0dd"
    property color trackColor:"#566071"
    from:0;to:100;stepSize:1;height:22;implicitHeight:22;padding:3
    hoverEnabled:true
    background:Rectangle {
        x:slider.leftPadding;y:slider.topPadding+(slider.availableHeight-height)/2
        width:slider.availableWidth;height:4;radius:1;color:slider.trackColor
        Rectangle {width:slider.visualPosition*parent.width;height:parent.height;radius:1;color:slider.fillColor}
    }
    handle:Rectangle {
        x:slider.leftPadding+slider.visualPosition*(slider.availableWidth-width)
        y:slider.topPadding+(slider.availableHeight-height)/2
        width:7;height:slider.pressed || slider.hovered ? 13:10;radius:1
        color:slider.pressed ? "#ffffff":"#e1deed"
        border.width:slider.activeFocus ? 1:0;border.color:"#b5a0d2"
        Behavior on height {NumberAnimation {duration:slider.reducedMotion ? 0:100;easing.type:Easing.OutCubic}}
    }
    opacity:enabled ? 1:.4
}
