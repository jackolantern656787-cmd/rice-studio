import QtQuick
Item {
    id: section
    property string label: ""
    FieldTheme { id: theme }
    implicitHeight: 23
    Text { id: caption; text: section.label.toUpperCase(); font.family: theme.monoFont; font.pixelSize: 11; font.letterSpacing: 1.5; color: theme.muted }
    Rectangle { x: caption.implicitWidth+14; y: 8; width: Math.max(0,parent.width-x); height: 1; color: theme.rule }
}
