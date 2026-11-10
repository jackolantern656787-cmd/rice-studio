import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
ScrollView {
    id:page
    required property var studio
    property int selectedIndex:-1
    property string dragHint:""
    clip:true;contentWidth:availableWidth
    readonly property var picked: selectedIndex>=0 && selectedIndex<studio.widgetDraft.length ? studio.widgetDraft[selectedIndex]:null
    ColumnLayout {
        width:page.availableWidth-8;spacing:16
        RowLayout {Layout.fillWidth:true;Column {spacing:7;Text {textFormat:Text.PlainText;text:"Widget layout";font.family:"C059";font.pixelSize:22;font.weight:Font.Normal;color:"#ddddde"} Text {textFormat:Text.PlainText;text:"Drag to place. Use the corner handle to resize. Save when it feels right.";font.pixelSize:11;color:"#99999a"}} Item {Layout.fillWidth:true}}
        Rectangle {
            id:desktop
            Layout.fillWidth:true;Layout.preferredHeight:width*9/16
            radius:0;color:"#121213";border.color:"#444445";clip:true
            Image {anchors.fill:parent;source:page.studio.canvasImage;fillMode:Image.PreserveAspectCrop;asynchronous:true;sourceSize.width:1200;opacity:.72}
            Rectangle {width:parent.width;height:16;color:"#d5131314";Text {textFormat:Text.PlainText;x:10;anchors.verticalCenter:parent.verticalCenter;text:"LAYOUT PREVIEW · 1920 × 1080";font.family:"JetBrains Mono";font.pixelSize:7;color:"#bebebf"}}
            Repeater {
                model:page.studio.widgetDraft
                Rectangle {
                    id:widget
                    required property var modelData
                    required property int index
                    property real scaleX:desktop.width/1920
                    property real scaleY:(desktop.height-16)/1080
                    x:modelData.x*scaleX;y:16+modelData.y*scaleY
                    width:Math.min(desktop.width,modelData.width*scaleX);height:Math.min(desktop.height-16,modelData.height*scaleY)
                    color:widgetMouse.containsMouse || index===page.selectedIndex ? "#ee222223":"#e5181819"
                    border.color:index===page.selectedIndex ? "#c7aa83":"#7d7d7e";border.width:index===page.selectedIndex ? 2:1;radius:0;opacity:modelData.enabled ? 1:.45
                    Text {textFormat:Text.PlainText;x:8;y:7;text:widget.modelData.kind.toUpperCase();font.family:"JetBrains Mono";font.pixelSize:8;color:"#c7aa83"}
                    Text {textFormat:Text.PlainText;anchors.centerIn:parent;text:({clock:"16:09",calendar:"MO TU WE TH FR",cpu:"▁▂▁▃▅▃▂",ram:"▃▄▅▅▆▅▅",music:"♫  NOW PLAYING",notes:"YOUR NOTE",dock:"▣  ▣  ▣  ▣  ▣"})[widget.modelData.kind] || "";font.family:"JetBrains Mono";font.pixelSize:widget.modelData.kind==="clock" ? Math.min(28,widget.width*.16):9;color:"#dfdfe0"}
                    MouseArea {
                        id:widgetMouse
                        anchors.fill:parent;hoverEnabled:true;cursorShape:pressed ? Qt.ClosedHandCursor:Qt.OpenHandCursor
                        drag.target:widget;drag.minimumX:0;drag.minimumY:16;drag.maximumX:Math.max(0,desktop.width-widget.width);drag.maximumY:Math.max(16,desktop.height-widget.height)
                        onPressed:page.selectedIndex=widget.index
                        onPositionChanged:if(pressed)page.dragHint=Math.round(widget.x/widget.scaleX)+", "+Math.round((widget.y-16)/widget.scaleY)
                        onReleased:{page.studio.updateWidget(widget.index,{x:Math.round(widget.x/widget.scaleX),y:Math.round((widget.y-16)/widget.scaleY)});page.dragHint="";}
                    }
                    Rectangle {
                        visible:widget.index===page.selectedIndex;width:9;height:9;anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:3;radius:0;color:"#c7aa83"
                        MouseArea {
                            anchors.fill:parent;anchors.margins:-5;cursorShape:Qt.SizeFDiagCursor
                            property point origin
                            property real startW
                            property real startH
                            onPressed:mouse=>{origin=mapToItem(desktop,mouse.x,mouse.y);startW=widget.width;startH=widget.height;}
                            onPositionChanged:mouse=>{if(!pressed)return;let now=mapToItem(desktop,mouse.x,mouse.y);widget.width=Math.max(180*widget.scaleX,Math.min(desktop.width-widget.x,startW+now.x-origin.x));widget.height=Math.max(100*widget.scaleY,Math.min(desktop.height-widget.y,startH+now.y-origin.y));}
                            onReleased:page.studio.updateWidget(widget.index,{width:Math.round(widget.width/widget.scaleX),height:Math.round(widget.height/widget.scaleY)})
                        }
                    }
                }
            }
            Rectangle {visible:page.studio.widgetDraft.length===0;anchors.centerIn:parent;width:280;height:52;radius:0;color:"#dd131314";border.color:"#3e3e3f";Text {textFormat:Text.PlainText;anchors.centerIn:parent;text:"Add your first widget below.";font.pixelSize:13;color:"#cccccd"}}
            Text {textFormat:Text.PlainText;anchors.right:parent.right;anchors.bottom:parent.bottom;anchors.margins:10;visible:page.dragHint!=="";text:page.dragHint;font.family:"JetBrains Mono";font.pixelSize:10;color:"#dfdfe0"}
        }
        Flow {
            Layout.fillWidth:true;spacing:7
            Repeater {model:page.studio.library.widgetTypes.filter(k=>k!=="dock" || page.studio.selectedKey==="honeyveil");ActionButton {required property string modelData;text:"+ "+modelData.charAt(0).toUpperCase()+modelData.slice(1);implicitHeight:36;reducedMotion:page.studio.reducedMotion;onClicked:{page.studio.addWidget(modelData);page.selectedIndex=page.studio.widgetDraft.length-1;}}}
        }
        RowLayout {
            Layout.fillWidth:true
            Text {textFormat:Text.PlainText;text:"SELECT WIDGET";font.family:"JetBrains Mono";font.pixelSize:9;color:"#8f8f90"}
            Choice {Layout.fillWidth:true;model:page.studio.widgetDraft.map((w,i)=>(i+1)+" / "+w.kind+(w.enabled ? "":" · hidden"));currentIndex:page.selectedIndex;onActivated:page.selectedIndex=index}
        }
        Rectangle {
            Layout.fillWidth:true;implicitHeight:childrenRect.height+26;color:"#19191a";radius:0;border.color:"#333334";visible:page.picked!==null
            ColumnLayout {
                x:14;y:14;width:parent.width-28;spacing:12
                RowLayout {Layout.fillWidth:true;Text {textFormat:Text.PlainText;text:page.picked ? page.picked.kind.toUpperCase()+" / INSPECTOR":"";font.family:"JetBrains Mono";font.pixelSize:10;color:"#b4b4b5"} Item {Layout.fillWidth:true} CheckBox {text:"Visible";checked:page.picked ? page.picked.enabled:false;onToggled:if(page.picked)page.studio.updateWidget(page.selectedIndex,{enabled:checked});palette.windowText:"#cbcbcc";palette.highlight:"#c7aa83"} ActionButton {text:"Remove";danger:true;implicitHeight:34;onClicked:{page.studio.deleteWidget(page.selectedIndex);page.selectedIndex=-1;}}}
                GridLayout {
                    columns:4;columnSpacing:12;Layout.fillWidth:true;visible:!page.picked || page.picked.kind!=="dock"
                    Repeater {model:["x","y","width","height"]
                        ColumnLayout {required property string modelData;Layout.fillWidth:true;Text {textFormat:Text.PlainText;text:parent.modelData.toUpperCase();font.family:"JetBrains Mono";font.pixelSize:9;color:"#8f8f90"} Field {Layout.fillWidth:true;text:page.picked ? String(page.picked[parent.modelData]):"";validator:IntValidator {bottom:0;top:16000} onEditingFinished:{if(!page.picked)return;let p={};p[parent.modelData]=Number(text);page.studio.updateWidget(page.selectedIndex,p);}}}
                    }
                }
                Text {visible:page.picked && page.picked.kind==="dock";text:"Dock stays centered at the bottom. Visible toggles it for this preset.";wrapMode:Text.Wrap;Layout.fillWidth:true;color:"#a5a5a6";font.pixelSize:11}
                Field {Layout.fillWidth:true;visible:page.picked && page.picked.kind==="notes";placeholderText:"Write a note…";text:page.picked ? page.picked.text || "":"";onTextEdited:page.studio.updateWidget(page.selectedIndex,{text:text})}
            }
        }
        Text {textFormat:Text.PlainText;Layout.fillWidth:true;wrapMode:Text.Wrap;text:page.studio.widgetDraft.length+" optional widgets · positions repeat per monitor. Your original desktop widgets remain untouched.";font.pixelSize:11;color:"#8e8e8f"}
        RowLayout {Layout.fillWidth:true;Layout.bottomMargin:24;ActionButton {text:"Save widget layout";primary:true;enabled:!page.studio.busy;onClicked:page.studio.saveWidgets();reducedMotion:page.studio.reducedMotion} Text {textFormat:Text.PlainText;Layout.fillWidth:true;wrapMode:Text.Wrap;text:"The canvas is a draft until you save.";font.pixelSize:11;color:"#8e8e8f"}}
    }
}
