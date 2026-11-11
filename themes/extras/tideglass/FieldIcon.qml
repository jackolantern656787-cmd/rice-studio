import QtQuick
Canvas {
    id: icon
    property string kind: "sound"
    property color ink: theme.paper
    property real strength: 100
    property bool reducedMotion: false
    property real animatedStrength: strength
    FieldTheme { id: theme }
    Behavior on ink { ColorAnimation { duration: icon.reducedMotion ? 0 : theme.quick; easing.type: Easing.OutCubic } }
    Behavior on animatedStrength { NumberAnimation { duration: icon.reducedMotion ? 0 : theme.settle; easing.type: Easing.OutCubic } }
    onAnimatedStrengthChanged: requestPaint()
    onInkChanged: requestPaint()
    onKindChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    // CUSTOM ICON SYSTEM — drawn on the same 32-unit grid, 1.6-unit square strokes.
    // Signal towers have cut tops rather than the usual rounded Wi-Fi arcs.
    onPaint: {
        const c = getContext("2d");
        c.reset(); c.clearRect(0, 0, width, height); c.scale(width / 32, height / 32);
        c.strokeStyle = ink; c.fillStyle = ink; c.lineWidth = 1.6;
        c.lineCap = "square"; c.lineJoin = "miter";
        function path(points) {
            c.beginPath(); c.moveTo(points[0][0], points[0][1]);
            for (let i=1; i<points.length; i++) c.lineTo(points[i][0], points[i][1]);
            c.stroke();
        }
        if (kind === "signal") {
            for (let i=0; i<4; i++) {
                const x=2+i*7, top=25-(5+i*5);
                c.globalAlpha = Math.max(.2, Math.min(1, (animatedStrength-i*25)/25));
                c.beginPath(); c.moveTo(x,27); c.lineTo(x,top+2); c.lineTo(x+2,top);
                c.lineTo(x+4,top); c.lineTo(x+4,27); c.closePath(); c.fill();
            }
            c.globalAlpha=1;
        } else if (kind === "lock") {
            c.beginPath(); c.arc(16,12,6,Math.PI,0); c.lineTo(22,16); c.stroke();
            c.strokeRect(7,15,18,13); c.fillRect(15,20,2,4);
        } else if (kind === "wired") {
            c.strokeRect(7,4,18,14); path([[11,4],[11,9],[21,9],[21,4]]);
            path([[16,18],[16,26],[5,26]]); path([[16,26],[27,26]]);
        } else if (kind === "monitor") {
            c.strokeRect(3,4,26,18); path([[16,22],[16,28],[8,28],[24,28]]);
            c.fillRect(7,18,2,1);
        } else if (kind === "chip") {
            c.strokeRect(8,8,16,16); c.strokeRect(12,12,8,8);
            for(let p=11;p<24;p+=5) { path([[p,3],[p,8]]); path([[p,24],[p,29]]); path([[3,p],[8,p]]); path([[24,p],[29,p]]); }
        } else if (kind === "close") {
            path([[8,8],[24,24]]); path([[24,8],[8,24]]);
        } else if (kind === "scan") {
            path([[5,13],[5,5],[13,5]]); path([[19,5],[27,5],[27,13]]);
            path([[27,19],[27,27],[19,27]]); path([[13,27],[5,27],[5,19]]);
            c.beginPath(); c.arc(16,16,5,0,Math.PI*2); c.stroke();
        } else if (kind === "check") {
            path([[6,16],[13,23],[27,8]]);
        } else if (kind === "arrow") {
            path([[5,16],[27,16],[20,9]]); path([[27,16],[20,23]]);
        } else {
            path([[4,12],[10,12],[17,6],[17,26],[10,20],[4,20],[4,12]]);
            if (kind === "mute") {
                path([[22,12],[29,20]]); path([[29,12],[22,20]]);
            } else {
                c.beginPath(); c.arc(16,16,8,-.65,.65); c.stroke();
                c.beginPath(); c.arc(16,16,13,-.65,.65); c.stroke();
            }
        }
    }
}
