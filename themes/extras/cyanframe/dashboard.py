#!/usr/bin/env python3
"""Cyanframe dashboard: real tools, current monitor, repeatable placement."""
from pathlib import Path
import argparse,fcntl,json,os,shlex,shutil,signal,subprocess,time
H=Path.home();D=H/'.local/share/rice-studio-portable/themes/extras/cyanframe'
def query(kind):return json.loads(subprocess.check_output(['hyprctl',kind,'-j'],text=True,timeout=5))
def rects(m):
 w,h=m['width'],m['height']
 if m.get('transform',0)%2:w,h=h,w
 scale=m.get('scale',1);w=round(w/scale);h=round(h/scale)
 l,t,r,b=m.get('reserved',[0,0,0,0]);x=m['x']+l;y=m['y']+t;w-=l+r;h-=t+b
 gap=10;x+=gap;y+=gap;w-=2*gap;h-=2*gap
 left=round(w*.38);mid=round(w*.28);rx=x+left+mid+2*gap;rw=w-left-mid-2*gap
 split=round(h*.64)
 return {'fetch':(x,y,left,split-gap),'cava':(x,y+split,left,h-split),'lyrics':(x+left+gap,y+round(h*.20),mid,round(h*.48)), 'pixel':(rx,y,rw,split-gap),'matrix':(x+w-round(w*.11),y+split,round(w*.11),h-split)}
def commands():
 return {'fetch':['bash','-c','fastfetch --config "$1"; exec "${SHELL:-/bin/bash}" -i','studio',str(H/'.config/rice-studio-portable/terminals/cyanframe-fastfetch.jsonc')], 'cava':['cava','-p',str(D/'cava.conf')], 'lyrics':['lyrics','--color-source','fixed:#c5e2de','--word-by-word','--single-voice','--no-visualizer'], 'pixel':['python3',str(D/'pixel-video.py')], 'matrix':['cmatrix','-b','-C','cyan','-u','5']}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--dry-run',action='store_true');ap.add_argument('--close',action='store_true');args=ap.parse_args()
 lockpath=H/'.local/state/rice-studio-portable/cyanframe-dashboard.lock';lockpath.parent.mkdir(parents=True,exist_ok=True)
 with lockpath.open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  clients=query('clients')
  if args.close:
   for c in clients:
    if c.get('class','').startswith('rice-studio-cyanframe-dashboard-'):
     # Address-scoped close; no other Kitty windows are affected.
     os.kill(int(c['pid']),signal.SIGTERM)
   return
  ws=query('activeworkspace');m=next(m for m in query('monitors') if m['id']==ws['monitorID']);rect=rects(m);cmds=commands()
  if args.dry_run:print(json.dumps({'workspace':ws['id'],'monitor':m['name'],'rects':rect,'commands':cmds},indent=2));return
  for kind,cmd in cmds.items():
   executable=cmd[0]
   if not shutil.which(executable):print('Optional dashboard tool missing: '+executable)
  if not (D/'assets/bad-apple.mp4').is_file():raise RuntimeError('Bad Apple video asset is missing')
  existing={c.get('class'):c for c in clients};pending={}
  for kind,cmd in cmds.items():
   if not shutil.which(cmd[0]):continue
   cls='rice-studio-cyanframe-dashboard-'+kind;pending[cls]=rect[kind]
   if cls in existing:continue
   # Silent workspace rule avoids stealing focus or switching monitors.
   launch=['kitty','--config',str(H/'.config/rice-studio-portable/terminals/cyanframe.conf'),'--class',cls,'--title','Cyanframe · '+kind,'--override','font_size='+('9' if kind=='fetch' else '11'),*cmd]
   env=os.environ.copy();env.pop('NO_COLOR',None)
   subprocess.Popen(launch,cwd=H,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
  deadline=time.monotonic()+8
  while pending and time.monotonic()<deadline:
   for c in query('clients'):
    cls=c.get('class')
    if cls not in pending:continue
    x,y,w,h=pending.pop(cls);a=json.dumps('address:'+c['address'])
    code=f'hl.dispatch(hl.dsp.window.move({{window={a},workspace={ws["id"]},silent=true}}));'
    if not c.get('floating'):code+=f'hl.dispatch(hl.dsp.window.float({{window={a},action="set"}}));'
    code+=f'hl.dispatch(hl.dsp.window.resize({{window={a},x={w},y={h},relative=false}}));hl.dispatch(hl.dsp.window.move({{window={a},x={x},y={y},relative=false}}))'
    subprocess.run(['hyprctl','eval',code],check=True,stdout=subprocess.DEVNULL)
   if pending:time.sleep(.1)
  if pending:raise RuntimeError('Could not open: '+', '.join(pending))
  print('Cyanframe Dashboard opened on '+m['name']+' · workspace '+str(ws['id']))
if __name__=='__main__':main()
