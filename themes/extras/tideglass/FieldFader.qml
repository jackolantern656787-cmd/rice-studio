import QtQuick
import QtQuick.Controls
Slider {
    id: fader
    property bool showScale: true
    property bool reducedMotion: false
    FieldTheme { id: theme }
    from: 0; to: 100; stepSize: 1
    implicitHeight: showScale ? 66 : 42
    height: implicitHeight
    leftPadding: 9; rightPadding: 9; topPadding: 6; bottomPadding: showScale ? 24 : 6
    hoverEnabled: true
    // SIZES — 41 etched segments and a chamfered 18×30 thumb.
    background: Item {
        x: fader.leftPadding; y: fader.topPadding; width: fader.availableWidth; height: fader.availableHeight
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 11; color: theme.ink; border.width: 1; border.color: theme.rule }
        Repeater {
            model: 41
            Rectangle {
                required property int index
                x: index * (parent.width-3)/40
                anchors.verticalCenter: parent.verticalCenter
                width: index % 10 === 0 ? 2 : 1
                height: index % 10 === 0 ? 22 : 10
                color: index/40 <= fader.visualPosition ? theme.accent : theme.rule
                Behavior on color { ColorAnimation { duration: fader.reducedMotion ? 0 : theme.quick } }
            }
        }
        Row {
            visible: fader.showScale
            y: parent.height + 5; width: parent.width
            Repeater { model: [0,25,50,75,100]; Text { required property var modelData; width: (fader.availableWidth)/5; text: modelData; font.family: theme.monoFont; font.pixelSize: 10; color: theme.muted; horizontalAlignment: modelData===0 ? Text.AlignLeft : modelData===100 ? Text.AlignRight : Text.AlignHCenter } }
        }
    }
    handle: Canvas {
        id: thumb
        x: fader.leftPadding + fader.visualPosition * (fader.availableWidth-width)
        y: fader.topPadding + (fader.availableHeight-height)/2 + (fader.pressed ? 2 : 0)
        width: 18; height: 30
        scale: fader.hovered ? 1.08 : 1
        Behavior on scale { NumberAnimation { duration: fader.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: fader.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } }
        Connections { target: fader; function onPressedChanged(){thumb.requestPaint();} function onActiveFocusChanged(){thumb.requestPaint();} function onHoveredChanged(){thumb.requestPaint();} }
        onPaint: {
            const c=getContext("2d");c.reset();c.clearRect(0,0,width,height);
            c.fillStyle=fader.pressed ? theme.accent : theme.paper;
            c.strokeStyle=fader.activeFocus || fader.hovered ? theme.accent : theme.ink;c.lineWidth=1;
            c.beginPath();c.moveTo(4,0);c.lineTo(14,0);c.lineTo(18,4);c.lineTo(18,26);c.lineTo(14,30);c.lineTo(4,30);c.lineTo(0,26);c.lineTo(0,4);c.closePath();c.fill();c.stroke();
            c.strokeStyle=theme.ink;c.lineWidth=1;
            for(let y=10;y<=20;y+=5){c.beginPath();c.moveTo(5,y);c.lineTo(13,y);c.stroke();}
        }
    }
    opacity: enabled ? 1 : .45
}
