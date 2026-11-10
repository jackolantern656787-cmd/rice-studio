import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Item {
 id:page
 required property var studio
 property string sortOrder:"Collection order"
 function rows(){let a=studio.library.profiles.filter(p=>(p.title+" "+p.description).toLowerCase().includes(studio.filter.toLowerCase()) && (!studio.favoritesOnly || studio.favorites.indexOf(p.key)>=0));if(sortOrder==="A → Z")a.sort((a,b)=>a.title.localeCompare(b.title));if(sortOrder==="Favorites first")a.sort((a,b)=>(studio.favorites.indexOf(b.key)>=0 ? 1:0)-(studio.favorites.indexOf(a.key)>=0 ? 1:0));return a;}
 ColumnLayout {
  anchors.fill:parent;spacing:16
  RowLayout {
   Layout.fillWidth:true
   Column {spacing:6
    Text {text:"Your desktop, collected.";color:"#eee7dc";font.family:"C059";font.pixelSize:34}
    Text {text:page.studio.library.profiles.length+" presets / select a study, then make it yours";color:"#88878b";font.family:"JetBrains Mono";font.pixelSize:11}
   }
   Item {Layout.fillWidth:true}
   Choice {Layout.preferredWidth:190;model:["Collection order","A → Z","Favorites first"];onActivated:page.sortOrder=model[index]}
   ActionButton {text:page.studio.favoritesOnly ? "★ Favorites":"☆ All presets";onClicked:page.studio.favoritesOnly=!page.studio.favoritesOnly}
  }
  GridView {
   id:grid;Layout.fillWidth:true;Layout.fillHeight:true;clip:true;cellWidth:width>1060 ? width/3:width/2;cellHeight:260
   model:page.rows()
   ScrollBar.vertical:ScrollBar {width:4}
   delegate:Item {
    id:card;required property var modelData;required property int index
    width:grid.cellWidth-16;height:grid.cellHeight-16
    activeFocusOnTab:true
    Accessible.role:Accessible.Button
    Accessible.name:modelData.title+", "+modelData.description
    Keys.onReturnPressed:{page.studio.choose(modelData.key,false);page.studio.setPage("appearance");}
    Keys.onSpacePressed:page.studio.choose(modelData.key,false)
    opacity:0
    Component.onCompleted:entrance.start()
    SequentialAnimation {id:entrance;PauseAnimation {duration:page.studio.reducedMotion ? 0:Math.min(card.index,8)*32} NumberAnimation {target:card;property:"opacity";to:1;duration:page.studio.duration;easing.type:Easing.OutCubic}}
    property bool chosen:modelData.key===page.studio.selectedKey
    property var captures:(page.studio.library.media || {})[modelData.key] || []
    property string picture: {let a=captures.filter(m=>!m.video);return a.length ? a[0].url:modelData.image;}
    scale:hover.hovered ? 1.012:1
    Behavior on scale {NumberAnimation {duration:page.studio.duration;easing.type:Easing.OutCubic}}
    Rectangle {anchors.fill:parent;color:"#1b1c20";border.color:card.chosen || card.activeFocus ? "#d6ab7d":hover.hovered ? "#73706b":"#303136";Behavior on border.color {ColorAnimation {duration:page.studio.duration}}}
    Image {x:1;y:1;width:parent.width-2;height:150;source:card.picture;fillMode:Image.PreserveAspectCrop;asynchronous:true;sourceSize.width:700}
    Rectangle {x:1;y:1;width:parent.width-2;height:150;color:"#17000000"}
    Text {x:14;y:13;text:String(card.index+1).padStart(2,'0');font.family:"JetBrains Mono";font.pixelSize:11;color:"#fff4df";style:Text.Outline;styleColor:"#333333"}
    Rectangle {visible:card.modelData.key===page.studio.library.current;x:12;y:119;width:90;height:22;color:"#192521";Text {anchors.centerIn:parent;text:"● ACTIVE";color:"#b9d4b4";font.family:"JetBrains Mono";font.pixelSize:10}}
    Column {x:14;y:163;width:parent.width-28;spacing:5
     Text {text:card.modelData.title;color:"#ece4d8";font.family:"C059";font.pixelSize:22}
     Text {width:parent.width;text:card.modelData.description || "Your personal starting point";elide:Text.ElideRight;color:"#99949a";font.family:"JetBrains Mono";font.pixelSize:10}
     Text {text:card.captures.length ? card.captures.length+" captured previews":"Wallpaper study · capture a desktop preview";color:"#716e75";font.family:"JetBrains Mono";font.pixelSize:9}
    }
    HoverHandler {id:hover}
    MouseArea {anchors.fill:parent;cursorShape:Qt.PointingHandCursor;onClicked:{card.forceActiveFocus();page.studio.choose(card.modelData.key,false);}onDoubleClicked:{page.studio.choose(card.modelData.key,false);page.studio.setPage("appearance");}}
    ActionButton {anchors.right:parent.right;anchors.top:parent.top;anchors.margins:7;text:page.studio.favorites.indexOf(card.modelData.key)>=0 ? "★":"☆";implicitWidth:34;implicitHeight:30;onClicked:page.studio.favorite(card.modelData.key)}
   }
   Text {visible:grid.count===0;anchors.centerIn:parent;text:"No presets here yet. Try another filter.";color:"#aaa49a";font.family:"JetBrains Mono"}
  }
  RowLayout {Layout.bottomMargin:14;Layout.fillWidth:true
   Text {text:"DOUBLE-CLICK TO EDIT";font.family:"JetBrains Mono";font.pixelSize:10;color:"#77747c"}
   Item {Layout.fillWidth:true}
   ActionButton {text:"Edit "+page.studio.selected.title+" →";onClicked:page.studio.setPage("appearance")}
  }
 }
}
