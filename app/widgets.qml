import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
ShellRoot {
    id: root
    property string selected: ""
    property var layouts: ({})
    property var profiles: ({})
    property var stats: ({ram:0,cpu:0,detail:""})
    property var cpuHistory: []
    property var ramHistory: []
    property real oldTotal: 0
    property real oldIdle: 0
    property date now: new Date()
    readonly property var items: (layouts[selected] || []).filter(w=>w.enabled && w.kind!=="dock")
    readonly property var colors: ((profiles[selected] || {}).theme || {}).colors || ({base:"#191e20",text:"#c4cacc",blue:"#8b9c7b",surface0:"#303737"})
    FileView { path: Quickshell.env("HOME")+"/.local/state/rice-studio-portable/current";watchChanges:true;onLoaded: root.selected=text().trim();onFileChanged:reload() }
    FileView { path: Quickshell.env("HOME")+"/.config/rice-studio-portable/widgets.json";watchChanges:true;onLoaded: {try{root.layouts=JSON.parse(text());}catch(e){}} onFileChanged:reload() }
    FileView { path: Quickshell.env("HOME")+"/.config/rice-studio-portable/profiles.json";watchChanges:true;onLoaded: {try{root.profiles=JSON.parse(text());}catch(e){}} onFileChanged:reload() }
    Timer {interval:1000;running:root.selected!=="main" && root.items.length>0;repeat:true;onTriggered:root.now=new Date()}
    Timer {interval:2000;running:root.items.some(w=>w.kind==="cpu" || w.kind==="ram" || w.kind==="music");repeat:true;triggeredOnStart:true;onTriggered:if(!metrics.running)metrics.running=true}
    Process {
        id: metrics
        command:["python3",Quickshell.env("HOME")+"/.local/share/rice-studio-portable/metrics.py"]
        stdout:StdioCollector {onStreamFinished:{try {
            let d=JSON.parse(text);d.cpu=root.oldTotal && d.total>root.oldTotal ? Math.max(0,100*(1-(d.idle-root.oldIdle)/(d.total-root.oldTotal))):0;
            root.oldTotal=d.total;root.oldIdle=d.idle;root.stats=d;
            let c=root.cpuHistory.slice(),r=root.ramHistory.slice();c.push(d.cpu);r.push(d.ram);if(c.length>90)c.shift();if(r.length>90)r.shift();root.cpuHistory=c;root.ramHistory=r;
        }catch(e){}}}
    }
    Variants {
        model:Quickshell.screens
        PanelWindow {
            required property var modelData
            screen:modelData
            visible:root.selected!=="main" && root.items.length>0
            anchors {top:true;bottom:true;left:true;right:true}
            exclusionMode:ExclusionMode.Ignore
            WlrLayershell.layer:WlrLayer.Bottom
            WlrLayershell.namespace:"rice-studio-widgets"
            WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
            mask:Region {}
            color:"transparent"
            Repeater {
                model:root.items
                Rectangle {
                    id: card
                    required property var modelData
                    x:Math.min(modelData.x,Math.max(0,parent.width-width));y:Math.min(modelData.y,Math.max(0,parent.height-height))
                    width:Math.min(modelData.width,parent.width);height:Math.min(modelData.height,parent.height)
                    color: "#e8191e20"
                    border.width:1;border.color:root.colors.blue;radius:0
                    readonly property string kind:modelData.kind
                    Text {x:14;y:10;text:card.kind.toUpperCase();color:root.colors.blue;font.family:"JetBrains Mono";font.pixelSize:12}
                    Column {
                        x:16;y:38;width:parent.width-32;spacing:8
                        visible:card.kind==="clock"
                        Text {text:Qt.formatDateTime(root.now,"HH:mm");font.family:"JetBrains Mono";font.pixelSize:Math.min(72,card.width/5);color:root.colors.blue}
                        Text {text:Qt.formatDateTime(root.now,"yyyy-MM-dd");font.family:"JetBrains Mono";font.pixelSize:13;color:root.colors.text}
                    }
                    Column {
                        x:16;y:40;width:parent.width-32;spacing:10
                        visible:card.kind==="notes" || card.kind==="music"
                        Text {width:parent.width;text:card.kind==="notes" ? card.modelData.text : (root.stats.music || "Nothing playing");wrapMode:Text.Wrap;textFormat:Text.PlainText;maximumLineCount:Math.max(1,Math.floor((card.height-65)/20));elide:Text.ElideRight;font.family:"JetBrains Mono";font.pixelSize:15;color:root.colors.text}
                    }
                    Text {x:16;y:38;visible:card.kind==="cpu" || card.kind==="ram";text:Math.round(card.kind==="cpu" ? root.stats.cpu:root.stats.ram)+"%";font.family:"JetBrains Mono";font.pixelSize:28;color:root.colors.text}
                    Canvas {
                        id: graph;x:16;y:85;width:parent.width-32;height:Math.max(10,parent.height-104)
                        visible:card.kind==="cpu" || card.kind==="ram"
                        property var samples:card.kind==="cpu" ? root.cpuHistory:root.ramHistory
                        onSamplesChanged:requestPaint()
                        onWidthChanged:requestPaint()
                        onPaint:{let c=getContext("2d");c.clearRect(0,0,width,height);c.fillStyle=root.colors.blue;let a=samples,step=width/90;for(let i=0;i<a.length;i++){let h=Math.max(1,a[i]*height/100);c.fillRect(width-(a.length-i)*step,height-h,Math.max(1,step-1),h);}}
                    }
                    Column {
                        x:14;y:38;width:parent.width-28;spacing:8;visible:card.kind==="calendar"
                        Text {text:Qt.formatDateTime(root.now,"MMMM yyyy");font.family:"JetBrains Mono";font.pixelSize:14;color:root.colors.text}
                        Grid {
                            columns:7
                            Repeater {
                                model:49
                                Text {
                                    required property int index
                                    property int first:(new Date(root.now.getFullYear(),root.now.getMonth(),1).getDay()+6)%7
                                    property int d:index-7-first+1
                                    property int maxDay:new Date(root.now.getFullYear(),root.now.getMonth()+1,0).getDate()
                                    width:(card.width-28)/7;height:Math.max(16,(card.height-80)/7)
                                    text:index<7 ? ['Mo','Tu','We','Th','Fr','Sa','Su'][index] : (d>0 && d<=maxDay ? d:"")
                                    color:d===root.now.getDate() && index>=7 ? root.colors.blue:root.colors.text
                                    font.bold:d===root.now.getDate() && index>=7
                                    horizontalAlignment:Text.AlignHCenter;font.family:"JetBrains Mono";font.pixelSize:12
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
