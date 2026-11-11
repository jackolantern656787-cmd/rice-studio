import QtQuick
import QtQuick.Controls
Button {
    id: row
    property string label: ""
    property string detail: ""
    property string glyph: "monitor"
    property bool selected: false
    property bool secured: false
    property int strength: -1
    property bool reducedMotion: false
    FieldTheme { id: theme }
    implicitHeight: theme.rowHeight
    hoverEnabled: true
    leftPadding: 12; rightPadding: 10
    Accessible.name: label + (selected ? ", connected" : "") + (strength >= 0 ? ", signal " + strength + " percent" : "") + (secured ? ", secured" : "")
    contentItem: Item {
        FieldIcon { x: 1; anchors.verticalCenter: parent.verticalCenter; width: 30; height: 30; kind: row.strength >= 0 ? "signal" : row.glyph; strength: Math.max(0,row.strength); ink: row.selected ? theme.live : row.hovered ? theme.accent : theme.muted; reducedMotion: row.reducedMotion }
        Text { x: 46; y: row.detail ? 10 : 14; width: parent.width-142; text: row.label; textFormat: Text.PlainText; font.family: theme.monoFont; font.pixelSize: 15; color: theme.paper; elide: Text.ElideRight }
        Text { x: 46; y: 33; width: parent.width-142; visible: !!row.detail; text: row.detail; textFormat: Text.PlainText; font.family: theme.monoFont; font.pixelSize: 11; color: row.selected ? theme.live : theme.muted; elide: Text.ElideRight }
        FieldIcon { visible: row.secured; anchors.right: parent.right; anchors.rightMargin: 45; y: 10; width: 16; height: 16; kind: "lock"; ink: theme.muted }
        Text { anchors.right: parent.right; y: 10; text: row.strength >= 0 ? row.strength + "%" : row.selected ? "IN USE" : "SELECT"; font.family: theme.monoFont; font.pixelSize: 10; color: row.selected ? theme.live : theme.muted }
        FieldIcon { anchors.right: parent.right; y: 33; width: 16; height: 16; kind: row.selected ? "check" : "arrow"; ink: row.selected ? theme.live : row.hovered ? theme.accent : theme.rule }
    }
    background: Rectangle {
        color: row.down ? theme.rule : row.hovered || row.selected ? theme.panel : "transparent"
        Behavior on color { ColorAnimation { duration: row.reducedMotion ? 0 : theme.quick } }
        Rectangle { anchors.bottom: parent.bottom; height: 1; width: parent.width; color: row.activeFocus ? theme.accent : theme.rule }
        Rectangle { x: 0; y: 9; width: row.selected ? 3 : 0; Behavior on width { NumberAnimation { duration: row.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } } height: parent.height-18; color: theme.live }
    }
    transform: Translate { x: row.down ? 2 : 0; Behavior on x { NumberAnimation { duration: row.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } } }
}
