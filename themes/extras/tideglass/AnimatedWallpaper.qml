import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland
Variants {
 id:wallpapers
 required property var controller
 required property string videoPath
 required property bool enabled
 model:Quickshell.screens
 PanelWindow {
  id:window
  required property var modelData
  screen:modelData
  property bool failed:false
  readonly property bool shouldPlay:wallpapers.controller.active && wallpapers.enabled && !wallpapers.controller.reducedMotion && !failed
  visible:shouldPlay
  anchors {top:true;bottom:true;left:true;right:true}
  exclusionMode:ExclusionMode.Ignore
  WlrLayershell.layer:WlrLayer.Bottom
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.None
  WlrLayershell.namespace:"tideglass-video-wallpaper"
  mask:Region {}
  color:"transparent"
  onShouldPlayChanged:{if(shouldPlay)player.play();else player.stop();}
  MediaPlayer {
   id:player
   source:"file://"+wallpapers.videoPath
   loops:MediaPlayer.Infinite
   videoOutput:output
   audioOutput:AudioOutput {muted:true;volume:0}
   onMediaStatusChanged:if(mediaStatus===MediaPlayer.LoadedMedia && window.shouldPlay)play()
   onErrorOccurred:{window.failed=true;console.warn("Tideglass wallpaper:",errorString);}
   Component.onCompleted:if(window.shouldPlay)play()
  }
  VideoOutput {id:output;anchors.fill:parent;fillMode:VideoOutput.PreserveAspectCrop}
 }
}
