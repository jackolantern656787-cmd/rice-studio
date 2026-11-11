import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
Item {
    id:page
    required property var studio
    property bool paletteOpen:false
    RowLayout {
        anchors.fill:parent;anchors.bottomMargin:17;spacing:22
        ColumnLayout {
            Layout.fillWidth:true;Layout.fillHeight:true;spacing:10
            Rectangle {
                Layout.fillWidth:true;Layout.fillHeight:true;color:"#0c0d0f";border.color:"#2c2c30"
                Image {id:wallpaper;anchors.fill:parent;anchors.margins:1;source:page.studio.canvasImage;fillMode:Image.PreserveAspectCrop;asynchronous:true;sourceSize.width:1400;opacity:status===Image.Ready ? 1:0;Behavior on opacity {NumberAnimation {duration:page.studio.reducedMotion ? 0:170}}}
                Text {textFormat:Text.PlainText;anchors.centerIn:parent;visible:wallpaper.status===Image.Error || wallpaper.source.toString()==="";text:"No image preview";font.family:"JetBrains Mono";font.pixelSize:13;color:"#77767a"}
            }
            RowLayout {
                Layout.fillWidth:true
                Text {textFormat:Text.PlainText;Layout.fillWidth:true;text:(page.studio.draft.wallpaper || "").split('/').pop();elide:Text.ElideMiddle;color:"#8a878c";font.family:"JetBrains Mono";font.pixelSize:11}
                ActionButton {text:"Change image";quiet:true;implicitHeight:28;onClicked:wallpaperDialog.open()}
            }
        }
        Rectangle {Layout.preferredWidth:1;Layout.fillHeight:true;color:"#2b2b30"}
        ScrollView {
            id:inspector
            Layout.preferredWidth:page.width>900 ? 300:256
            Layout.fillHeight:true;clip:true;contentWidth:availableWidth
            ColumnLayout {
                width:inspector.availableWidth-6;spacing:11
                Text {text:"THEME COLLECTION";color:"#d6ab7d";font.family:"JetBrains Mono";font.pixelSize:11}
                Text {Layout.fillWidth:true;wrapMode:Text.Wrap;text:"Use the theme bar to open its launcher. New Kitty windows use the preset’s terminal profile automatically.";font.pixelSize:12;color:"#aaa49a"}
                Text {textFormat:Text.PlainText;text:"SETUP";font.family:"JetBrains Mono";font.pixelSize:10;font.letterSpacing:1.2;color:"#8a878c";Layout.bottomMargin:4}
                Field {Layout.fillWidth:true;text:page.studio.draft.label || "";onTextEdited:page.studio.setField("label",text);Accessible.name:"Preset name"}
                GridLayout {
                    Layout.fillWidth:true;columns:2;columnSpacing:10;rowSpacing:9
                    Text {textFormat:Text.PlainText;text:"Bar";font.family:"JetBrains Mono";font.pixelSize:13;color:"#858389"}
                    Choice {Layout.fillWidth:true;model:page.studio.library.bars;textRole:"label";currentIndex:Math.max(0,model.findIndex(b=>b.key===page.studio.draft.bar));onActivated:page.studio.setField("bar",model[index].key)}
                    Text {textFormat:Text.PlainText;text:"Terminal";font.family:"JetBrains Mono";font.pixelSize:13;color:"#858389"}
                    Choice {Layout.fillWidth:true;model:page.studio.library.terminals;currentIndex:Math.max(0,model.indexOf(page.studio.draft.terminal));onActivated:page.studio.setField("terminal",model[index])}
                    Text {textFormat:Text.PlainText;text:"Launcher";font.family:"JetBrains Mono";font.pixelSize:13;color:"#858389"}
                    Field {enabled:false;Layout.fillWidth:true;text:page.studio.draft.launcher_theme || "";onTextEdited:page.studio.setField("launcher_theme",text)}
                    Text {textFormat:Text.PlainText;text:"Font";font.family:"JetBrains Mono";font.pixelSize:13;color:"#858389"}
                    Field {Layout.fillWidth:true;text:page.studio.draft.theme.fontFamily || "";onTextEdited:page.studio.setTheme("fontFamily",text)}
                    Text {textFormat:Text.PlainText;text:"Corners";font.family:"JetBrains Mono";font.pixelSize:13;color:"#858389"}
                    Field {Layout.fillWidth:true;text:String(page.studio.draft.theme.borderRadius || 0);validator:IntValidator {bottom:0;top:40} onEditingFinished:page.studio.setTheme("borderRadius",Number(text));Accessible.name:"Corner radius in pixels"}
                }
                Rectangle {Layout.fillWidth:true;height:1;color:"#2b2b30";Layout.topMargin:7;Layout.bottomMargin:2}
                ActionButton {Layout.fillWidth:true;text:page.paletteOpen ? "− Palette":"+ Palette";quiet:true;onClicked:page.paletteOpen=!page.paletteOpen}
                GridLayout {
                    visible:page.paletteOpen;columns:2;columnSpacing:10;rowSpacing:9;Layout.fillWidth:true
                    Repeater {model:["base","mantle","crust","text","surface0","surface1","blue","mauve"]
                        RowLayout {
                            id:swatch
                            required property string modelData
                            Layout.fillWidth:true;spacing:6
                            Rectangle {width:22;height:22;color:/^#[0-9a-fA-F]{6}$/.test(page.studio.draft.theme.colors[swatch.modelData] || "") ? page.studio.draft.theme.colors[swatch.modelData]:"#777777";border.color:"#4b494d";MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:page.studio.pickColor(swatch.modelData)}}
                            Column {spacing:3;Text {textFormat:Text.PlainText;text:swatch.modelData;font.family:"JetBrains Mono";font.pixelSize:10;color:"#858389"} Text {textFormat:Text.PlainText;text:page.studio.draft.theme.colors[swatch.modelData] || "";font.family:"JetBrains Mono";font.pixelSize:10;color:"#b4b0a9"}}
                        }
                    }
                }
                Text {text:"PRESET NOTES";font.family:"JetBrains Mono";font.pixelSize:10;color:"#8a878c"}
                TextArea {id:notes;Layout.fillWidth:true;Layout.preferredHeight:100;wrapMode:TextEdit.Wrap;text:(page.studio.library.notes || {})[page.studio.selectedKey] || "";placeholderText:"Tweaks, shortcuts, things to remember…";color:"#ddd5ca";font.family:"JetBrains Mono";font.pixelSize:11;background:Rectangle {color:"#1b1c20";border.color:notes.activeFocus ? "#d6ab7d":"#38383e"}}
                ActionButton {text:"Save notes";Layout.fillWidth:true;onClicked:page.studio.request("notes",{key:page.studio.selectedKey,text:notes.text},"Saving your notes")}
                ActionButton {Layout.fillWidth:true;Layout.topMargin:5;text:page.studio.selectedKey==="main" ? "Clone Main to edit":"Save changes";enabled:page.studio.selectedKey!=="main" && !page.studio.busy;onClicked:page.studio.saveAppearance()}
                Text {textFormat:Text.PlainText;Layout.fillWidth:true;wrapMode:Text.Wrap;text:page.studio.selectedKey==="main" ? "Main stays as your recovery baseline.":"A checkpoint is saved first.";font.family:"JetBrains Mono";font.pixelSize:11;color:"#8a878c";Layout.bottomMargin:14}
            }
        }
    }
    FileDialog {id:wallpaperDialog;title:"Choose wallpaper";parentWindow:page.Window.window;nameFilters:["Wallpaper (*.png *.jpg *.jpeg *.webp *.mp4 *.webm)"];onAccepted:page.studio.setField("wallpaper",decodeURIComponent(selectedFile.toString().replace(/^file:\/\//,'')))}
}
