#!/usr/bin/env python3
"""Local-only Pixel panel data and explicit UI actions. Never stores payloads."""
import json,subprocess,sys
from pathlib import Path
H=Path.home(); SHELL=H/'.local/share/serpantinum/src/quickshell/Shell.qml'
def run(args):
 p=subprocess.run(list(map(str,args)),capture_output=True,text=True,timeout=12)
 if p.returncode: raise RuntimeError(p.stderr.strip() or 'Command failed')
 return p.stdout.strip()
def ipc(action,*args):return run(['quickshell','-p',SHELL,'ipc','call','pixelNotifications',action,*args])
def info(mode):
 if mode=='stats':
  fields={}
  for row in Path('/proc/meminfo').read_text().splitlines():
   k,v=row.split(':',1);fields[k]=int(v.strip().split()[0])
  total=fields['MemTotal'];used=total-fields['MemAvailable']
  cpu=list(map(int,Path('/proc/stat').read_text().splitlines()[0].split()[1:]))
  return dict(total=sum(cpu[:8]),idle=cpu[3]+cpu[4],ram=used/total*100,detail=f'{used/1048576:.1f} / {total/1048576:.1f} GiB · available memory excluded')
 if mode=='audio':
  default=run(['pactl','get-default-sink']);sinks=json.loads(run(['pactl','-f','json','list','sinks']))
  rows=[];volume=0;mute=False
  for sink in sinks:
   if sink['name']==default:
    volume=round(sum(float(v['value_percent'].strip('%')) for v in sink['volume'].values())/max(1,len(sink['volume'])));mute=sink['mute']
   rows.append(dict(label=sink.get('description',sink['name']),value=sink['name'],active=sink['name']==default))
  return dict(rows=rows,volume=min(volume,100),muted=mute)
 if mode=='network':
  # Terse UUID/type/state fields cannot contain escaped user-provided names.
  active=set(run(['nmcli','-g','UUID','connection','show','--active']).splitlines())
  rows=[]
  for line in run(['nmcli','-t','-f','UUID,TYPE','connection','show']).splitlines():
   uid,kind=line.split(':',1)
   if kind not in ('802-11-wireless','802-3-ethernet','wifi','ethernet'):continue
   name=run(['nmcli','-g','connection.id','connection','show','uuid',uid])
   rows.append(dict(label=name+' · '+('connected' if uid in active else kind),value=uid,active=uid in active))
  return dict(rows=rows,status=run(['nmcli','-t','-f','DEVICE,TYPE,STATE','device','status']),wifi=run(['nmcli','radio','wifi']))
 if mode=='notifications': return json.loads(ipc('snapshot').splitlines()[-1])
 raise ValueError('Unknown panel')
def action(kind,value=''):
 if kind=='volume':run(['pactl','set-sink-volume','@DEFAULT_SINK@',str(max(0,min(100,int(float(value)))))+'%'])
 elif kind=='mute':run(['pactl','set-sink-mute','@DEFAULT_SINK@','toggle'])
 elif kind=='output':
  sinks=json.loads(run(['pactl','-f','json','list','sinks']))
  if value not in [s['name'] for s in sinks]:raise ValueError('Output disconnected')
  run(['pactl','set-default-sink',value])
  for stream in json.loads(run(['pactl','-f','json','list','sink-inputs'])):run(['pactl','move-sink-input',str(stream['index']),value])
 elif kind=='connect':run(['nmcli','--wait','8','connection','up','uuid',value])
 elif kind=='wifi':run(['nmcli','radio','wifi',value if value in ('on','off') else 'off'])
 elif kind=='network-editor':subprocess.Popen(['kitty','--title','Network connections','-e','nmtui'],start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 elif kind=='dismiss':ipc('dismiss',str(int(value)))
 elif kind=='clear':ipc('clear')
 elif kind=='dnd':ipc('toggleDnd')
 else:raise ValueError('Unknown action')
 return {'ok':True}
if __name__=='__main__':
 try: result=action(*sys.argv[2:]) if sys.argv[1]=='action' else info(sys.argv[1]);print(json.dumps(result))
 except Exception as exc: print(json.dumps({'error':str(exc)}));sys.exit(1)
