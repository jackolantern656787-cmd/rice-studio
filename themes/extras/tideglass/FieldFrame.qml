import QtQuick
Canvas {
    FieldTheme { id: theme }
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    // Only opposing corners are clipped, like a folded equipment fascia.
    onPaint: {
        const c=getContext("2d");c.reset();c.clearRect(0,0,width,height);
        c.fillStyle=theme.ink;c.strokeStyle=theme.rule;c.lineWidth=1;
        c.beginPath();c.moveTo(.5,.5);c.lineTo(width-11,.5);c.lineTo(width-.5,11);
        c.lineTo(width-.5,height-.5);c.lineTo(11,height-.5);c.lineTo(.5,height-11);c.closePath();c.fill();c.stroke();
    }
}
