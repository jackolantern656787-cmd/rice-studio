import QtQuick
import Quickshell.Io

Item {
    id: widgets
    property bool enabledForProfile: false
    property alias calendarHitbox: calendar
    property real u: width / 300
    property string popupMode: ""
    property date today: new Date()
    property int monthOffset: 0
    readonly property date month: new Date(today.getFullYear(), today.getMonth()+monthOffset, 1)
    readonly property int firstDay: (month.getDay()+6)%7
    readonly property int daysInMonth: new Date(month.getFullYear(),month.getMonth()+1,0).getDate()
    property real cpu: 0
    property real lastTotal: 0
    property real lastIdle: 0
    property var samples: []
    readonly property color ink: "#c9c8c0"
    readonly property string face: "Rice Pixel"
    anchors.fill: parent
    Timer { interval: 60000; repeat: true; running: widgets.enabledForProfile; onTriggered: widgets.today=new Date() }
    Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: widgets.enabledForProfile; onTriggered: { if(!stats.running) stats.running=true; } }
    property var cpuSamples: []
    property var ramSamples: []
    property real ram: 0
    property string ramDetail: ""
    onPopupModeChanged: { samples=popupMode === "ram" ? ramSamples:cpuSamples;graph.requestPaint(); }
    Process {
        id: stats
        command: ["python3", "@STUDIO_APP@/themes/extras/pixel/backend.py", "stats"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data=JSON.parse(text);
                    if(data.error)return;
                    widgets.ram=data.ram;widgets.ramDetail=data.detail;
                    if(widgets.lastTotal>0 && data.total>widgets.lastTotal)
                        widgets.cpu=Math.max(0,Math.min(100,100*(1-(data.idle-widgets.lastIdle)/(data.total-widgets.lastTotal))));
                    let c=widgets.cpuSamples.slice(),r=widgets.ramSamples.slice();
                    c.push(widgets.cpu);r.push(widgets.ram);
                    if(c.length>100)c.shift();if(r.length>100)r.shift();
                    widgets.cpuSamples=c;widgets.ramSamples=r;
                    widgets.samples=widgets.popupMode === "ram" ? r:c;
                    graph.requestPaint();
                    widgets.lastTotal=data.total;widgets.lastIdle=data.idle;
                } catch(e) {}
            }
        }
    }
    Rectangle {
        id: systemCard
        visible: widgets.popupMode === "system" || widgets.popupMode === "ram"
        x: 4*widgets.u; y: 17*widgets.u
        width: parent.width-8*widgets.u; height: 170*widgets.u
        color: "#101010"; border.color: "#484740"; border.width: 1; radius: 0
        Rectangle { x: 3; y: 3; width: parent.width-6; height: parent.height-6; color: "transparent"; border.color: "#252522"; border.width: 1 }
        Text { x: 7*widgets.u; y: 4*widgets.u; text: widgets.popupMode === "ram" ? "▣ ram" : "▣ cpu"; color: widgets.ink; font.family: widgets.face; font.pixelSize: Math.max(10,6*widgets.u) }
        Text { anchors.right: parent.right; anchors.rightMargin: 6*widgets.u; y: 4*widgets.u; text: Math.round(widgets.popupMode === "ram" ? widgets.ram : widgets.cpu)+"%"; color: widgets.ink; font.family: widgets.face; font.pixelSize: Math.max(10,6*widgets.u) }
        Text {
            x: 7*widgets.u; y: 18*widgets.u
            text: widgets.popupMode === "ram" ? widgets.ramDetail : "CPU utilization · 2-second samples"
            color: "#86867c";font.family: widgets.face;font.pixelSize: 11
        }
        Canvas {
            id: graph
            x: 6*widgets.u; y: 30*widgets.u; width: parent.width-12*widgets.u; height: parent.height-36*widgets.u
            onWidthChanged: requestPaint()
            onPaint: {
                let c=getContext("2d");c.clearRect(0,0,width,height);
                c.fillStyle="#31312d";c.fillRect(0,height-1,width,1);
                let a=widgets.samples, step=width/100;
                c.fillStyle="#9f9f95";
                for(let i=0;i<a.length;i++) {
                    let h=Math.max(1,a[i]/100*(height-2));
                    c.fillRect(Math.floor(width-(a.length-i)*step),Math.floor(height-h),Math.max(1,Math.floor(step)-1),Math.ceil(h));
                }
            }
        }
    }
    Rectangle {
        id: calendar
        visible: widgets.popupMode === "calendar"
        anchors.top: parent.top; anchors.right: parent.right
        anchors.topMargin: 17*widgets.u; anchors.rightMargin: 5*widgets.u
        width: Math.min(300*widgets.u,parent.width-20);height: 191*widgets.u
        color: "#101010";border.width: 1;border.color: "#57564e";radius: 0
        Text { x: 9*widgets.u;y: 8*widgets.u;text: Qt.formatDateTime(widgets.today,"HH:mm");color: widgets.ink;font.family: widgets.face;font.bold: true;font.pixelSize: 14*widgets.u }
        Text { x: 9*widgets.u;y: 27*widgets.u;text: Qt.formatDateTime(widgets.today,"dddd, d MMMM");color: "#99998f";font.family: widgets.face;font.pixelSize: Math.max(10,6*widgets.u) }
        Rectangle { x: 8*widgets.u;y: 42*widgets.u;width: parent.width-16*widgets.u;height: 1;color: "#34342f" }
        Text { anchors.horizontalCenter: parent.horizontalCenter;y: 50*widgets.u;text: Qt.formatDateTime(widgets.month,"MMMM yyyy");color: widgets.ink;font.family: widgets.face;font.pixelSize: Math.max(11,7*widgets.u) }
        Repeater {
            model: ["‹","›"]
            Rectangle {
                required property int index
                required property string modelData
                x: index===0 ? 9*widgets.u : calendar.width-29*widgets.u;y: 47*widgets.u;width: 20*widgets.u;height: 20*widgets.u
                color: nav.containsMouse ? "#2a2a26" : "transparent"
                Text { anchors.centerIn: parent;text: modelData;color: widgets.ink;font.pixelSize: 14*widgets.u }
                MouseArea { id: nav;anchors.fill: parent;hoverEnabled: true;cursorShape: Qt.PointingHandCursor;onClicked: widgets.monthOffset+= index===0 ? -1:1 }
            }
        }
        Grid {
            x: 9*widgets.u;y: 73*widgets.u;columns: 7;spacing: 0
            Repeater {
                model: 49
                Rectangle {
                    required property int index
                    readonly property int day: index-7-widgets.firstDay+1
                    readonly property bool valid: day>0 && day<=widgets.daysInMonth
                    readonly property bool current: valid && widgets.monthOffset===0 && day===widgets.today.getDate()
                    width: (calendar.width-18*widgets.u)/7;height: 15*widgets.u
                    color: current ? "#bcbcb2" : "transparent";radius: 1
                    Text {
                        anchors.centerIn: parent
                        text: index<7 ? ["Mo","Tu","We","Th","Fr","Sa","Su"][index] : (parent.valid ? parent.day : "")
                        color: parent.current ? "#141412" : (index<7 ? "#77776f" : widgets.ink)
                        font.family: widgets.face;font.pixelSize: Math.max(10,6*widgets.u)
                    }
                }
            }
        }
    }
}
