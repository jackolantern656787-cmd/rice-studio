import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root
    required property var controller
    // INTEGRATION — override this path if the Python backend lives elsewhere.
    property string backendPath: Quickshell.env("HOME") + "/.local/share/rice-studio-portable/themes/extras/tideglass/controls.py"
    FieldTheme { id: theme }
    readonly property bool reducedMotion: controller.reducedMotion
    property string mode: ""
    property string shownMode: "volume"
    property string monitorName: ""
    property string pendingMode: ""
    property var data: ({ outputs:[], ports:[], apps:[], devices:[], networks:[], volume:0, muted:false, wifiEnabled:false, wifiDevice:"" })
    property var pendingAction: ({})
    property var pendingLevel: ({})
    property bool appDragging: false
    readonly property bool busy: apply.running
    property string errorText: ""
    property var chosenNetwork: null
    property real progress: mode !== "" ? 1 : 0
    Behavior on progress { NumberAnimation { duration: root.reducedMotion ? 0 : theme.entrance; easing.type: Easing.OutQuint } }

    onModeChanged: {
        password.text = "";
        if (mode !== "") {
            controller.dismissOtherPanels(); shownMode=mode; errorText=""; chosenNetwork=null;
            showOutputs=false;refresh(); Qt.callLater(()=>closeButton.forceActiveFocus());
        } else volumeDelay.stop();
    }
    Connections { target: root.controller; function onActiveChanged(){ if(!root.controller.active)root.mode=""; } }
    function toggle(value) {
        if(!controller.active)return;
        if(mode===value){mode="";return;}
        pendingMode=value; monitor.running=true;
    }
    function refresh(scan) {
        if(read.running)return;
        read.command=["python3",backendPath,scan ? "scan":"snapshot"]; read.running=true;
    }
    function acceptSnapshot(d) {
        // Preserve delegates when unchanged; a background poll must not steal a drag.
        for(const key of ["outputs","ports","networks","devices","apps"])
            if((key==="apps" && appDragging) || JSON.stringify(data[key])===JSON.stringify(d[key])) d[key]=data[key];
        data=d;
        if(!volume.pressed && !volumeDelay.running)volume.value=d.volume || 0;
        if(!microphone.pressed && !volumeDelay.running)microphone.value=d.micVolume || 0;
    }
    function act(request) {
        if(busy)return;
        errorText=""; pendingAction=request; apply.running=true;
    }
    function queueLevel(request) { pendingLevel=request; volumeDelay.restart(); }
    function chooseNetwork(network) { chosenNetwork=network; password.text=""; Qt.callLater(()=>{if(!network.active)password.forceActiveFocus();}); }
    function connectChosen() {
        if(chosenNetwork)act({action:"connect",ssid:chosenNetwork.ssid,device:chosenNetwork.device,password:password.text});
        password.text="";
    }
    Process {
        id: monitor; command:["hyprctl","activeworkspace","-j"]
        stdout: StdioCollector { onStreamFinished:{ try{root.monitorName=JSON.parse(text).monitor || "";}catch(e){} root.mode=root.pendingMode; } }
    }
    Process {
        id: read
        stdout: StdioCollector { onStreamFinished:{
            try{const d=JSON.parse(text);if(d.error)root.errorText=d.error;else root.acceptSnapshot(d);}
            catch(e){root.errorText="Could not read device status.";}
        } }
    }
    Process {
        id: apply; command:["python3",root.backendPath,"apply"]; stdinEnabled:true
        // Secrets live in this one stdin message; clear the retained object immediately.
        onStarted:{ write(JSON.stringify(root.pendingAction)+"\n");root.pendingAction={}; }
        stdout: StdioCollector { onStreamFinished:{
            try{const d=JSON.parse(text);root.errorText=d.error || "";if(!d.error)root.chosenNetwork=null;}
            catch(e){root.errorText="Could not change device settings.";}
            actionRefresh.restart();
        } }
    }
    Timer { id:actionRefresh; interval:140; onTriggered:root.refresh(); }
    Timer { interval:2500; running:root.mode!==""; repeat:true; onTriggered:if(!root.busy && !volume.pressed && !microphone.pressed && !root.appDragging)root.refresh(); }
    Timer {
        id: volumeDelay; interval:90
        onTriggered:{if(root.busy)restart();else root.act(root.pendingLevel);}
    }
    IpcHandler { target:"volume"; function toggle():void {root.toggle("volume");} }
    IpcHandler { target:"network"; function toggle():void {root.toggle("network");} }
    IpcHandler {
        target:"tideglass-system"
        function status():string {return JSON.stringify({mode:root.mode,busy:root.busy,outputs:(root.data.outputs||[]).length,apps:(root.data.apps||[]).length,networks:(root.data.networks||[]).length,error:root.errorText,audioError:root.data.audioError||"",networkError:root.data.networkError||""});}
    }

    property bool showOutputs:false
    PanelWindow {
        id:window
        visible:root.controller.active && (root.mode!=="" || root.progress>.001)
        screen:Quickshell.screens.find(s=>s.name===root.monitorName) || Quickshell.screens[0]
        anchors {top:true;bottom:true;left:true;right:true}
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.keyboardFocus:root.mode!=="" ? WlrKeyboardFocus.Exclusive:WlrKeyboardFocus.None
        WlrLayershell.namespace:"tideglass-system-panel"
        color:"transparent"
        MouseArea {anchors.fill:parent;onClicked:root.mode="";}
        Rectangle {
            id:panel
            // Compact reference layout. Change width, inset, alpha and animation here.
            anchors.right:parent.right;anchors.rightMargin:12;y:40-(1-root.progress)*6
            width:Math.min(330,window.width-24)
            height:Math.min(body.implicitHeight+24,window.height-60)
            radius:4;color:"#b8242e3c";border.width:1;border.color:"#657c879e"
            opacity:root.progress
            Behavior on height {NumberAnimation {duration:root.reducedMotion ? 0:160;easing.type:Easing.OutCubic}}
            Keys.onEscapePressed:root.mode=""
            MouseArea {anchors.fill:parent}
            Flickable {
                anchors.fill:parent;anchors.margins:12
                contentWidth:width;contentHeight:body.implicitHeight;clip:true
                boundsBehavior:Flickable.StopAtBounds
                ScrollBar.vertical:ScrollBar {policy:ScrollBar.AsNeeded}
                Column {
                    id:body;width:panel.width-24;spacing:8
                    Row {
                        width:parent.width;height:24
                        Text {width:parent.width-(root.shownMode==="network" ? 104:26);text:root.shownMode==="volume" ? "Audio Control":"Wi-Fi";font.family:"Iosevka Nerd Font";font.pixelSize:14;color:"#d9d8e6";anchors.verticalCenter:parent.verticalCenter}
                        CompactButton {visible:root.shownMode==="network";text:root.data.wifiEnabled ? "On":"Off";active:!!root.data.wifiEnabled;enabled:!root.busy && !!root.data.wifiDevice;reducedMotion:root.reducedMotion;Accessible.name:"Wi-Fi radio";onClicked:root.act({action:"radio",enabled:!root.data.wifiEnabled})}
                        CompactButton {visible:root.shownMode==="network";glyph:"scan";enabled:!root.busy && !read.running && !!root.data.wifiEnabled;reducedMotion:root.reducedMotion;Accessible.name:"Scan networks";onClicked:root.refresh(true)}
                        CompactButton {id:closeButton;glyph:"close";reducedMotion:root.reducedMotion;Accessible.name:"Close panel";onClicked:root.mode=""}
                    }
                    Column {
                        width:parent.width;spacing:4;visible:root.shownMode==="volume"
                        Row {
                            width:parent.width;height:20
                            CompactButton {glyph:root.data.muted ? "mute":"sound";active:!!root.data.muted;implicitHeight:20;implicitWidth:22;reducedMotion:root.reducedMotion;Accessible.name:"Mute main audio";onClicked:root.act({action:"mute"})}
                            Text {text:"Main Audio";width:parent.width-60;font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#c8ccda";anchors.verticalCenter:parent.verticalCenter}
                            Text {text:Math.round(volume.value)+"%";font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#b7bdcc";anchors.verticalCenter:parent.verticalCenter}
                        }
                        CompactSlider {id:volume;width:parent.width;reducedMotion:root.reducedMotion;enabled:!root.data.audioError;Accessible.name:"Main audio volume";onMoved:root.queueLevel({action:"volume",value:Math.round(value)})}
                        Column {
                            visible:!!root.data.micAvailable;width:parent.width;spacing:2
                            Row {width:parent.width;height:20
                                CompactButton {text:root.data.micMuted ? "×":"·";active:!!root.data.micMuted;implicitWidth:22;implicitHeight:20;reducedMotion:root.reducedMotion;Accessible.name:"Mute microphone";onClicked:root.act({action:"mic-mute"})}
                                Text {text:"Microphone";width:parent.width-60;font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#c8ccda";anchors.verticalCenter:parent.verticalCenter}
                                Text {text:Math.round(microphone.value)+"%";font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#b7bdcc";anchors.verticalCenter:parent.verticalCenter}
                            }
                            CompactSlider {id:microphone;width:parent.width;reducedMotion:root.reducedMotion;Accessible.name:"Microphone volume";onMoved:root.queueLevel({action:"mic-volume",value:Math.round(value)})}
                        }
                        Row {width:parent.width;height:24
                            Text {width:parent.width-58;text:(root.data.outputs||[]).filter(o=>o.active).map(o=>o.label.replace("\n"," · ")).join("");textFormat:Text.PlainText;elide:Text.ElideRight;font.family:"Iosevka Nerd Font";font.pixelSize:10;color:"#a5afc2";anchors.verticalCenter:parent.verticalCenter}
                            CompactButton {text:"Output";active:root.showOutputs;implicitHeight:22;reducedMotion:root.reducedMotion;onClicked:root.showOutputs=!root.showOutputs}
                        }
                        Column {visible:root.showOutputs;width:parent.width;spacing:2
                            Repeater {model:root.data.outputs||[];delegate:CompactButton {required property var modelData;width:body.width;text:(modelData.active ? "• ":"")+modelData.label.replace("\n"," · ");active:modelData.active;enabled:!root.busy;reducedMotion:root.reducedMotion;onClicked:root.act({action:"output",name:modelData.name})}}
                            Repeater {model:(root.data.ports||[]).length>1 ? root.data.ports:[];delegate:CompactButton {required property var modelData;width:body.width;text:modelData.label;active:modelData.active;enabled:!root.busy;reducedMotion:root.reducedMotion;onClicked:root.act({action:"port",name:modelData.name})}}
                        }
                        Rectangle {width:parent.width;height:1;color:"#466b7488"}
                        Text {visible:(root.data.apps||[]).length>0;text:"Applications";font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#c8ccda";topPadding:4}
                        Repeater {model:root.data.apps||[];delegate:Column {
                            id:app;required property var modelData;width:body.width;spacing:1
                            Row {width:parent.width;height:20
                                CompactButton {glyph:app.modelData.muted ? "mute":"sound";active:app.modelData.muted;implicitWidth:22;implicitHeight:20;reducedMotion:root.reducedMotion;Accessible.name:"Mute "+app.modelData.label;onClicked:root.act({action:"app-mute",index:app.modelData.index})}
                                Text {width:parent.width-60;text:app.modelData.label;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#c8ccda";anchors.verticalCenter:parent.verticalCenter}
                                Text {text:Math.round(appFader.value)+"%";font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#b7bdcc";anchors.verticalCenter:parent.verticalCenter}
                            }
                            CompactSlider {id:appFader;width:parent.width;enabled:app.modelData.writable;reducedMotion:root.reducedMotion;Accessible.name:app.modelData.label+" volume";onPressedChanged:root.appDragging=pressed;onMoved:root.queueLevel({action:"app-volume",index:app.modelData.index,value:Math.round(value)});Binding {target:appFader;property:"value";value:app.modelData.volume;when:!appFader.pressed && !root.volumeDelayActive && !root.busy && !root.actionRefreshActive && !root.readActive;restoreMode:Binding.RestoreNone}}
                        }}
                        Text {visible:!!root.data.audioError;text:root.data.audioError||"";width:parent.width;wrapMode:Text.WordWrap;font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#debcc7"}
                    }
                    Column {
                        width:parent.width;spacing:4;visible:root.shownMode==="network"
                        Text {visible:(root.data.devices||[]).some(d=>d.type==="ethernet" && d.state==="connected");text:"Ethernet connected";font.family:"Iosevka Nerd Font";font.pixelSize:10;color:"#a6bfaf";bottomPadding:5}
                        Text {visible:!root.data.wifiDevice || !root.data.wifiEnabled;text:root.data.wifiDevice ? "Wi-Fi is off.":"No Wi-Fi adapter.";font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#aab4c7"}
                        Text {visible:!!root.data.wifiEnabled && (root.data.networks||[]).length===0;text:"No networks listed. Use scan to refresh.";width:parent.width;wrapMode:Text.WordWrap;font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#aab4c7"}
                        Repeater {model:root.data.wifiEnabled ? (root.data.networks||[]):[];delegate:Button {
                            id:station;required property var modelData;width:body.width;height:43;padding:5;hoverEnabled:true
                            Accessible.name:modelData.ssid+(modelData.active ? ", connected":"")
                            onClicked:root.chooseNetwork(modelData)
                            background:Rectangle {radius:2;color:station.down ? "#8055667d":station.hovered || station.modelData.active ? "#4550637a":"transparent";border.width:station.activeFocus ? 1:0;border.color:"#a99bc7";Behavior on color {ColorAnimation {duration:root.reducedMotion ? 0:100}}}
                            contentItem:Item {
                                FieldIcon {x:1;anchors.verticalCenter:parent.verticalCenter;width:22;height:22;kind:"signal";strength:station.modelData.signal;ink:station.modelData.active ? "#a6bfaf":"#b7bfd0";reducedMotion:root.reducedMotion}
                                Text {x:32;y:station.modelData.active ? 0:7;width:parent.width-99;text:station.modelData.ssid;textFormat:Text.PlainText;elide:Text.ElideRight;font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#d5d9e4"}
                                Text {x:32;y:18;visible:station.modelData.active;text:"Connected";font.family:"Iosevka Nerd Font";font.pixelSize:9;color:"#a6bfaf"}
                                FieldIcon {visible:!!station.modelData.security && station.modelData.security!=="--";anchors.right:parent.right;anchors.rightMargin:33;y:10;width:12;height:12;kind:"lock";ink:"#a5afc2"}
                                Text {anchors.right:parent.right;y:9;text:station.modelData.signal+"%";font.family:"Iosevka Nerd Font";font.pixelSize:10;color:"#a5afc2"}
                            }
                        }}
                        Column {visible:root.chosenNetwork!==null;width:parent.width;spacing:6
                            Rectangle {width:parent.width;height:1;color:"#466b7488"}
                            Text {text:root.chosenNetwork ? root.chosenNetwork.ssid:"";textFormat:Text.PlainText;elide:Text.ElideRight;width:parent.width;font.family:"Iosevka Nerd Font";font.pixelSize:12;color:"#d5d9e4"}
                            TextField {id:password;width:parent.width;height:30;visible:!!root.chosenNetwork && !root.chosenNetwork.active && !!root.chosenNetwork.security && root.chosenNetwork.security!=="--";echoMode:TextInput.Password;placeholderText:"Password (blank for saved network)";font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#d5d9e4";placeholderTextColor:"#a5afc2";Accessible.name:"Wi-Fi password";onAccepted:root.connectChosen();background:Rectangle {color:"#66202b3a";radius:2;border.width:1;border.color:password.activeFocus ? "#b5a0d2":"#657688"}}
                            Row {spacing:6
                                CompactButton {text:root.chosenNetwork && root.chosenNetwork.active ? "Disconnect":"Connect";active:true;enabled:!root.busy;reducedMotion:root.reducedMotion;onClicked:{if(root.chosenNetwork.active)root.act({action:"disconnect",device:root.chosenNetwork.device});else root.connectChosen();}}
                                CompactButton {text:"Cancel";enabled:!root.busy;reducedMotion:root.reducedMotion;onClicked:{root.chosenNetwork=null;password.text="";}}
                            }
                        }
                        Text {visible:!!root.data.networkError;text:root.data.networkError||"";width:parent.width;wrapMode:Text.WordWrap;font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#debcc7"}
                    }
                    Text {visible:root.busy || !!root.errorText;text:root.errorText||"Applying…";textFormat:Text.PlainText;width:parent.width;wrapMode:Text.WordWrap;font.family:"Iosevka Nerd Font";font.pixelSize:11;color:"#debcc7"}
                }
            }
        }
    }
    readonly property bool volumeDelayActive:volumeDelay.running
    readonly property bool actionRefreshActive:actionRefresh.running
    readonly property bool readActive:read.running
}
