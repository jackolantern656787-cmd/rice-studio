#!/usr/bin/env python3
"""Optional reference layout, made of ordinary movable terminal windows."""
from pathlib import Path
import subprocess,json,time
h=Path.home();d=h/'.local/share/rice-studio-portable/themes/extras/tideglass'
def query(name):return json.loads(subprocess.check_output(['hyprctl',name,'-j']))
def main():
 ws=query('activeworkspace');m=next(m for m in query('monitors') if m['id']==ws['monitorID'])
 w,ht=m['width'],m['height']
 if m.get('transform',0)%2:w,ht=ht,w
 w=round(w/m['scale']);ht=round(ht/m['scale']);left,top,right,bottom=m.get('reserved',[0,0,0,0]);x=m['x']+left;y=m['y']+top;w-=left+right;ht-=top+bottom
 commands={'clock':['python3',str(d/'clock.py')],'tree':['env','RICE_REPORT_CONFIG='+str(d/'compact-fastfetch.jsonc'),'bash','-i'],'spectrum':['python3',str(d/'terminal-spectrum.py')]}
 rects={'clock':(x+8,y+8,round(w*.24),round(ht*.23)), 'tree':(x+w-round(w*.28)-8,y+8,round(w*.28),round(ht*.24)), 'spectrum':(x+8,y+ht-round(ht*.20)-8,w-16,round(ht*.20))}
 existing={c['class'] for c in query('clients')}
 pending={}
 for kind,cmd in commands.items():
  cls='tideglass-dashboard-'+kind
  if cls in existing:
   pending[cls]=rects[kind]
   continue
  subprocess.Popen(['kitty','--config',str(h/'.config/rice-studio-portable/terminals/tideglass.conf'),'--class',cls,'--override','font_size=11','--override','background_opacity=0.52','--override','background=#25333f',*cmd],cwd=h,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
  pending[cls]=rects[kind]
 deadline=time.monotonic()+6
 while pending and time.monotonic()<deadline:
  for c in query('clients'):
   if c.get('class') not in pending:continue
   x,y,w,ht=pending.pop(c['class']);selector=json.dumps('address:'+c['address'])
   code=f'hl.dispatch(hl.dsp.window.move({{window={selector},workspace={ws["id"]},silent=true}}));'
   if not c.get('floating'):code+=f'hl.dispatch(hl.dsp.window.float({{window={selector},action="set"}}));'
   code+=f'hl.dispatch(hl.dsp.window.resize({{window={selector},x={w},y={ht},relative=false}}));hl.dispatch(hl.dsp.window.move({{window={selector},x={x},y={y},relative=false}}))'
   subprocess.run(['hyprctl','eval',code],check=True,stdout=subprocess.DEVNULL)
  if pending:time.sleep(.1)
 if pending:raise RuntimeError('Could not open panels: '+', '.join(pending))
 print('Tideglass panels are on '+m['name']+', workspace '+str(ws['id'])+'.')
if __name__=='__main__':main()
