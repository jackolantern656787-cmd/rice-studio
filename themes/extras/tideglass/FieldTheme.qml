import QtQuick
QtObject {
    // PALETTE — seven inks; both panels and every custom component use these.
    readonly property color ink: "#151B21"
    readonly property color panel: "#202932"
    readonly property color rule: "#46525E"
    readonly property color paper: "#E6DDCA"
    readonly property color accent: "#B5A0D2"
    readonly property color live: "#A6BFA8"
    readonly property color muted: "#9BA6B1"

    // FONT PAIR — installed locally; no web fonts or downloads required.
    readonly property string displayFont: "Noto Serif"
    readonly property string monoFont: "Iosevka Nerd Font"

    // SIZES — panel width and content inset. Components scale within this width.
    readonly property int panelWidth: 464
    readonly property int inset: 22
    readonly property int rowHeight: 68

    // MOTION — durations in milliseconds; parent passes reducedMotion throughout.
    readonly property int quick: 110
    readonly property int settle: 190
    readonly property int entrance: 230
}
