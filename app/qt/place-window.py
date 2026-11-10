"""Place only this app's window; never change global rules or layouts."""
import os,json,subprocess,time
try:
 for _ in range(15):
  clients=json.loads(subprocess.check_output(['hyprctl','clients','-j'],timeout=3))
  client=next((c for c in clients if c.get('pid')==os.getppid() and c.get('title')=='Rice Studio · Portable'),None)
  if client:break
  time.sleep(.15)
 if client:
  monitors=json.loads(subprocess.check_output(['hyprctl','monitors','-j'],timeout=3))
  m=next((m for m in monitors if m['id']==client['monitor']),monitors[0]);scale=m.get('scale',1);mw=int(m['width']/scale);mh=int(m['height']/scale)
  w=min(1400,mw-64);h=min(900,mh-90);x=m['x']+(mw-w)//2;y=m['y']+(mh-h)//2
  selector=json.dumps('address:'+client['address'])
  code=('' if client.get('floating') else f'hl.dispatch(hl.dsp.window.float({{window={selector},action="set"}}));')
  code+=f'hl.dispatch(hl.dsp.window.resize({{window={selector},x={w},y={h},relative=false}}));hl.dispatch(hl.dsp.window.move({{window={selector},x={x},y={y},relative=false}}))'
  subprocess.run(['hyprctl','eval',code],capture_output=True,timeout=5)
except (OSError,ValueError,subprocess.SubprocessError):pass
