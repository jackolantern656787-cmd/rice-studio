import QtQuick

Item {
    id: pixel
    property bool showClock: true
    property date now: new Date()
    readonly property real unit: width / 800
    anchors.fill: parent
    Timer { interval: 1000; running: pixel.visible; repeat: true; onTriggered: { pixel.now = new Date(); clock.requestPaint(); } }
    Rectangle { anchors.fill: parent; color: "#0d0c0c" }
    Canvas {
        id: texture
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            let c=getContext("2d"), u=pixel.unit;
            c.clearRect(0,0,width,height);
            // Stable fine grain and staggered pin dots, without a frame loop.
            let seed=417;
            function random() { seed=(seed*16807)%2147483647; return seed/2147483647; }
            for(let y=0;y<height;y+=3*u) for(let x=0;x<width;x+=3*u) {
                c.fillStyle="rgba(190,180,170,"+(random()*0.018)+")";
                c.fillRect(x,y,u,u);
            }
            for(let y=26*u,row=0;y<height;y+=17*u,row++) for(let x=(row%2 ? 8:0)*u;x<width;x+=17*u) {
                c.fillStyle="rgba(176,169,154,"+(0.12+random()*0.10)+")";
                c.fillRect(Math.round(x),Math.round(y),Math.max(1,u*.7),Math.max(1,u*.7));
            }
            let glow=c.createRadialGradient(width*.87,height*.89,0,width*.87,height*.89,width*.75);
            glow.addColorStop(0,"rgba(110,104,96,0.08)"); glow.addColorStop(1,"rgba(0,0,0,0)");
            c.fillStyle=glow;c.fillRect(0,0,width,height);
        }
    }
    Item {
        width: parent.width; height: parent.height
        opacity: pixel.showClock ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 220 } }
        Canvas {
            id: clock
            x: 2*pixel.unit; y: 63*pixel.unit
            width: 120*pixel.unit; height: 29*pixel.unit
            onWidthChanged: requestPaint()
            onPaint: {
                let c=getContext("2d"); c.clearRect(0,0,width,height);
                let digits={
                    '0':["01110","11011","11011","11011","11011","11011","01110"],
                    '1':["00110","01110","00110","00110","00110","00110","11111"],
                    '2':["11110","00011","00011","01110","11000","11000","11111"],
                    '3':["11110","00011","00011","01110","00011","00011","11110"],
                    '4':["11011","11011","11011","11111","00011","00011","00011"],
                    '5':["11111","11000","11000","11110","00011","00011","11110"],
                    '6':["01110","11000","11000","11110","11011","11011","01110"],
                    '7':["11111","00011","00011","00110","01100","01100","01100"],
                    '8':["01110","11011","11011","01110","11011","11011","01110"],
                    '9':["01110","11011","11011","01111","00011","00011","01110"],
                    ':':["0","1","1","0","1","1","0"]};
                let value=Qt.formatDateTime(pixel.now,"HH:mm"), b=3.45*pixel.unit, offset=0;
                c.fillStyle="#deded9";
                for(let ch of value) {
                    let glyph=digits[ch];
                    for(let y=0;y<7;y++) for(let x=0;x<glyph[y].length;x++)
                        if(glyph[y][x]==='1')c.fillRect(Math.round(offset+x*b),Math.round(y*b),Math.ceil(b),Math.ceil(b));
                    offset+=(glyph[0].length+1)*b;
                }
            }
        }
        Text {
            x: 2*pixel.unit; y: 101*pixel.unit
            text: Qt.formatDateTime(pixel.now,"dddd, d MMMM")
            font.family: "Iosevka Nerd Font"; font.pixelSize: Math.max(10,6*pixel.unit)
            color: "#aaa9a2"
        }
        Rectangle { x: 2*pixel.unit; y: 111*pixel.unit; width: 120*pixel.unit; height: Math.max(1,pixel.unit*.5); color: "#4c4b46" }
    }
}
