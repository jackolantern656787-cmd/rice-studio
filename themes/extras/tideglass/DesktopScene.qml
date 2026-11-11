import QtQuick
Item {
 required property var controller
 FontLoader {id:pixel;source:"file://@STUDIO_APP@/themes/extras/pixel/RicePixel.ttf"}
   readonly property real u:width/1920
   Rectangle {anchors.fill:parent;color:"#180b1423"}
   Rectangle {
    id:clockBox;x:8*parent.u;y:48*parent.u;width:450*parent.u;height:254*parent.u
    radius:2;color:"#86293246";border.width:1;border.color:"#849c9ab8"
    Text {id:clock;anchors.horizontalCenter:parent.horizontalCenter;y:60*parent.parent.u;text:Qt.formatDateTime(controller.now,"HH:mm");font.family:pixel.name;font.pixelSize:82*parent.parent.u;color:"#c6bfea"}
    Text {anchors.horizontalCenter:parent.horizontalCenter;anchors.top:clock.bottom;anchors.topMargin:17*parent.parent.u;text:Qt.formatDateTime(controller.now,"yyyy-MM-dd");font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:13*parent.parent.u;color:"#c7c9df"}
   }
   Rectangle {
    id:systemBox;width:540*parent.u;height:252*parent.u;anchors.right:parent.right;anchors.rightMargin:8*parent.u;y:48*parent.u
    radius:2;color:"#9b283244";border.width:1;border.color:"#849c9ab8"
    Text {x:16*parent.parent.u;y:10*parent.parent.u;text:"┌ treefetch";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:12*parent.parent.u;color:"#afbfdf"}
    Text {x:20*parent.parent.u;y:42*parent.parent.u;text:"     /\\\n    /  \\\n   / /\\ \\\n  / /  \\ \\\n / /    \\ \\\n/_/      \\_\\";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:16*parent.parent.u;color:"#b8c2e3";lineHeight:.95}
    Column {x:192*parent.parent.u;y:37*parent.parent.u;width:parent.width-210*parent.parent.u;spacing:4*parent.parent.u
     readonly property real u:parent.parent.u
     Text {width:parent.width;text:(controller.info.user || "user")+"@arch";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:13*parent.u;font.bold:true;color:"#d5c3ed"}
     Rectangle {width:parent.width*.72;height:1;color:"#9d9cb7"}
     Repeater {model:[['os','Arch Linux'],['kernel',controller.info.kernel],['shell',controller.info.shell],['uptime',controller.info.uptime],['memory',controller.stats.detail]]
      Row {required property var modelData;width:parent.width;spacing:7*parent.u
       Text {width:68*parent.parent.u;text:'• '+parent.modelData[0];font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11*parent.parent.u;color:"#bdc7e6"}
       Text {width:parent.width-75*parent.parent.u;text:parent.modelData[1];textFormat:Text.PlainText;elide:Text.ElideRight;font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:11*parent.parent.u;color:"#d2d8e7"}
      }
     }
    }
    Rectangle {x:17*parent.parent.u;anchors.bottom:parent.bottom;anchors.bottomMargin:35*parent.parent.u;width:110*parent.parent.u;height:18*parent.parent.u;color:"#bcb7dd";radius:2
     Text {anchors.centerIn:parent;text:"  ~  ❯";font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:10*parent.parent.parent.u;color:"#33405a"}
    }
    Rectangle {anchors.right:parent.right;anchors.rightMargin:14*parent.parent.u;anchors.bottom:parent.bottom;anchors.bottomMargin:35*parent.parent.u;width:145*parent.parent.u;height:18*parent.parent.u;color:"#d3d0e6";radius:1
     Text {anchors.centerIn:parent;text:"at "+Qt.formatDateTime(controller.now,"HH:mm:ss");font.family:"JetBrainsMono Nerd Font Mono";font.pixelSize:10*parent.parent.parent.u;color:"#33405a"}
    }
   }
   Rectangle {
    id:spectrumBox;x:8*parent.u;width:parent.width-16*parent.u;height:232*parent.u;anchors.bottom:parent.bottom;anchors.bottomMargin:5*parent.u
    color:"#80252d38";border.width:1;border.color:"#849c9ab8";radius:0
    Canvas {
     id:audioCanvas;anchors.fill:parent;anchors.margins:8
     property var samples:controller.audio
     property real u:spectrumBox.parent.u
     onSamplesChanged:requestPaint()
     onWidthChanged:requestPaint()
     onPaint:{
      let c=getContext('2d');c.clearRect(0,0,width,height);
      let a=samples.length ? samples:Array(80).fill(0),step=width/a.length,gap=Math.max(1,3*u),unit=Math.max(3,7*u),bh=Math.max(2,5*u);
      for(let i=0;i<a.length;i++){
       let count=Math.max(1,Math.min(20,a[i]));
       for(let j=0;j<count;j++){
        c.fillStyle=j<3 ? '#c7c9ee':j<8 ? '#a9a9d3':j<13 ? '#a59ac4':j<17 ? '#bba2c2':'#d3b5c4';
        c.fillRect(i*step,height-bh-j*unit,Math.max(1,step-gap),bh);
       }
      }
     }
    }
   }
}
