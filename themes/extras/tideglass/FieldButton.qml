import QtQuick
import QtQuick.Controls
Button {
    id: button
    property string glyph: ""
    property bool accent: false
    property bool reducedMotion: false
    FieldTheme { id: theme }
    implicitWidth: glyph && !text ? 36 : Math.max(84, label.implicitWidth + (glyph ? 48 : 28))
    implicitHeight: 36
    padding: 10
    hoverEnabled: true
    font.family: theme.monoFont
    font.pixelSize: 13
    transform: Translate {
        y: button.down ? 2 : 0
        Behavior on y { NumberAnimation { duration: button.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } }
    }
    contentItem: Item {
        FieldIcon { visible: !!button.glyph; kind: button.glyph; width: 18; height: 18; anchors.verticalCenter: parent.verticalCenter; x: button.text ? 0 : (parent.width-width)/2; ink: button.accent ? theme.ink : theme.paper }
        Text { id: label; anchors.fill: parent; anchors.leftMargin: button.glyph && button.text ? 26 : 0; text: button.text; font: button.font; textFormat: Text.PlainText; color: !button.enabled ? theme.muted : button.accent ? theme.ink : theme.paper; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    }
    background: Rectangle {
        radius: 0
        color: button.accent ? theme.accent : button.hovered ? theme.rule : theme.panel
        border.width: 1
        border.color: button.activeFocus ? theme.paper : button.accent ? theme.accent : theme.rule
        opacity: button.enabled ? 1 : .48
        Behavior on color { ColorAnimation { duration: button.reducedMotion ? 0 : theme.quick } }
        Rectangle { x: 0; y: parent.height; width: parent.width; height: button.down ? 0 : 2; color: theme.ink }
    }
}
