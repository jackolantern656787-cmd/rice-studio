import QtQuick
Canvas {
 id:icon
 required property string kind
 property color ink:"#d8c9ef"
 onInkChanged:requestPaint()
 onKindChanged:requestPaint()
 onWidthChanged:requestPaint()
 onHeightChanged:requestPaint()
 onPaint:{
  let c=getContext("2d");c.reset();c.clearRect(0,0,width,height);c.scale(width/64,height/64);
  c.strokeStyle=ink;c.fillStyle=ink;c.lineWidth=3;c.lineCap="round";c.lineJoin="round";
  if(kind==="lock"){
   c.beginPath();c.arc(32,24,11,Math.PI,0);c.lineTo(43,32);c.moveTo(21,32);c.lineTo(21,24);c.stroke();
   c.beginPath();c.roundedRect(16,29,32,28,3,3);c.fill();
  }else if(kind==="logout"){
   c.beginPath();c.moveTo(29,10);c.lineTo(12,10);c.lineTo(12,54);c.lineTo(29,54);c.stroke();
   c.beginPath();c.moveTo(26,32);c.lineTo(54,32);c.moveTo(43,21);c.lineTo(54,32);c.lineTo(43,43);c.stroke();
  }else if(kind==="suspend"){
   c.beginPath();c.arc(32,32,24,0,Math.PI*2);c.stroke();c.fillRect(24,21,5,22);c.fillRect(35,21,5,22);
  }else if(kind==="reboot"){
   c.beginPath();c.arc(32,32,24,Math.PI*.72,Math.PI*2.42);c.stroke();
   c.beginPath();c.moveTo(12,36);c.lineTo(13,48);c.lineTo(25,46);c.stroke();
  }else{
   c.beginPath();c.arc(32,34,23,-Math.PI*.29,Math.PI*1.29);c.stroke();
   c.beginPath();c.moveTo(32,6);c.lineTo(32,30);c.stroke();
  }
 }
}
