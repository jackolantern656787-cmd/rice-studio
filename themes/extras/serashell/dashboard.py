#!/usr/bin/env python3
"""Serashell dashboard: real tools, current monitor, repeatable placement."""
from pathlib import Path
import argparse,fcntl,json,os,shlex,shutil,signal,subprocess,time
H=Path.home();D=H/'.local/share/rice-studio-portable/themes/extras/serashell'
def query(kind):return json.loads(subprocess.check_output(['hyprctl',kind,'-j'],text=True,timeout=5))
def rects(m):
 w,h=m['width'],m['height']
 if m.get('transform',0)%2:w,h=h,w
 scale=m.get('scale',1);w=round(w/scale);h=round(h/scale)
 l,t,r,b=m.get('reserved',[0,0,0,0]);x=m['x']+l;y=m['y']+t;w-=l+r;h-=t+b
 gap=10;x+=gap;y+=gap;w-=2*gap;h-=2*gap
 return {'fetch':(x,y,round(w*.58),round(h*.52)), 'pipes':(x+round(w*.64),y+round(h*.03),round(w*.36),round(h*.45)), 'cava':(x+round(w*.10),y+round(h*.61),round(w*.60),round(h*.35))}
def commands():
 return {'fetch':['bash','-c','fastfetch --config "$1"; exec "${SHELL:-/bin/bash}" -i','studio',str(H/'.config/rice-studio-portable/terminals/serashell-fastfetch.jsonc')], 'cava':['cava','-p',str(D/'cava.conf')], 'pipes':['bash',str(D/'pipes.sh'),'-p','5','-t','2','-c','7','-f','40','-r','3000']}
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--dry-run',action='store_true');ap.add_argument('--close',action='store_true');args=ap.parse_args()
 lockpath=H/'.local/state/rice-studio-portable/serashell-dashboard.lock';lockpath.parent.mkdir(parents=True,exist_ok=True)
 with lockpath.open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  clients=query('clients')
  if args.close:
   for c in clients:
    if c.get('class','').startswith('serashell-dashboard-'):
     # Address-scoped close; no other Kitty windows are affected.
     os.kill(int(c['pid']),signal.SIGTERM)
   return
  ws=query('activeworkspace');m=next(m for m in query('monitors') if m['id']==ws['monitorID']);rect=rects(m);cmds=commands()
  if args.dry_run:print(json.dumps({'workspace':ws['id'],'monitor':m['name'],'rects':rect,'commands':cmds},indent=2));return
  for kind,cmd in cmds.items():
   executable=cmd[0]
   if not shutil.which(executable):raise RuntimeError('Missing dashboard tool: '+executable)
  existing={c.get('class'):c for c in clients};pending={}
  for kind,cmd in cmds.items():
   cls='serashell-dashboard-'+kind;pending[cls]=rect[kind]
   if cls in existing:continue
   # Silent workspace rule avoids stealing focus or switching monitors.
   launch=['kitty','--start-as','normal','--config',str(H/'.config/rice-studio-portable/terminals/serashell.conf'),'--class',cls,'--title','Serashell · '+kind,'--override','font_size='+('12' if kind=='fetch' else '12'),*cmd]
   env=os.environ.copy();env.pop('NO_COLOR',None);env['TERM_PROFILE']='serashell'
   subprocess.Popen(launch,cwd=H,env=env,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
  deadline=time.monotonic()+8
  while pending and time.monotonic()<deadline:
   for c in query('clients'):
    cls=c.get('class')
    if cls not in pending:continue
    x,y,w,h=pending.pop(cls);a=json.dumps('address:'+c['address'])
    code=(f'hl.dispatch(hl.dsp.window.fullscreen({{window={a},mode="maximized",action="unset"}}));' if c.get('fullscreen')==1 else '')
    code+=f'hl.dispatch(hl.dsp.window.move({{window={a},workspace={ws["id"]},silent=true}}));'
    if not c.get('floating'):code+=f'hl.dispatch(hl.dsp.window.float({{window={a},action="set"}}));'
    code+=f'hl.dispatch(hl.dsp.window.resize({{window={a},x={w},y={h},relative=false}}));hl.dispatch(hl.dsp.window.move({{window={a},x={x},y={y},relative=false}}))'
    subprocess.run(['hyprctl','eval',code],check=True,stdout=subprocess.DEVNULL)
   if pending:time.sleep(.1)
  if pending:raise RuntimeError('Could not open: '+', '.join(pending))
  print('Serashell Dashboard opened on '+m['name']+' · workspace '+str(ws['id']))
if __name__=='__main__':main()
