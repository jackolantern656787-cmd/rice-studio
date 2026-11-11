import QtQuick
import QtQuick.Controls
AbstractButton {
    id: toggle
    property string onLabel: "ON"
    property string offLabel: "OFF"
    property bool reducedMotion: false
    FieldTheme { id: theme }
    checkable: true
    hoverEnabled: true
    implicitWidth: 102
    implicitHeight: 36
    background: Rectangle { color: theme.ink; border.width: 1; border.color: toggle.activeFocus ? theme.paper : toggle.hovered ? theme.accent : theme.rule; Behavior on border.color { ColorAnimation { duration: toggle.reducedMotion ? 0 : theme.quick } } }
    contentItem: Item {
        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: toggle.offLabel; font.family: theme.monoFont; font.pixelSize: 11; color: theme.muted }
        Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: toggle.onLabel; font.family: theme.monoFont; font.pixelSize: 11; color: theme.muted }
        // Mechanical paddle: straight slot, three grip lines, a 190ms detent.
        Rectangle {
            x: toggle.checked ? parent.width - width - 4 : 4
            y: toggle.down ? 6 : 4; width: 42; height: parent.height - 8
            color: toggle.checked ? theme.accent : theme.paper
            Behavior on color { ColorAnimation { duration: toggle.reducedMotion ? 0 : theme.quick } }
            Behavior on x { NumberAnimation { duration: toggle.reducedMotion ? 0 : theme.settle; easing.type: Easing.OutQuint } }
            Behavior on y { NumberAnimation { duration: toggle.reducedMotion ? 0 : theme.quick } }
            Text { anchors.centerIn: parent; text: toggle.checked ? toggle.onLabel : toggle.offLabel; font.family: theme.monoFont; font.pixelSize: 11; font.bold: true; color: theme.ink }
        }
    }
    opacity: enabled ? 1 : .45
}
