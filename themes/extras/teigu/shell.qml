import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
ShellRoot {
    id: root
    property bool opened:false
    property string selected:""
    onSelectedChanged:opened=false
    FileView {path:"@STUDIO_STATE@/current";watchChanges:true;onLoaded:root.selected=text().trim();onFileChanged:reload()}
    IpcHandler {target:"notifications";function toggle():void {if(root.selected==="teigu")root.opened=!root.opened;}}
    PanelWindow {
        visible:root.opened && root.selected==="teigu"
        anchors {top:true;bottom:true;right:true}
        margins {top:60;bottom:10;right:10}
        implicitWidth:480
        exclusionMode:ExclusionMode.Ignore
        WlrLayershell.layer:WlrLayer.Overlay
        WlrLayershell.namespace:"teigu-notifications"
        WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
        color:"transparent"
        NotificationPanel {
            mode:"notifications";backend:"@STUDIO_APP@/themes/extras/pixel/backend.py"
            x:0;y:0;width:parent.width;height:parent.height
            focus:true;Keys.onEscapePressed:root.opened=false
        }
    }
}
