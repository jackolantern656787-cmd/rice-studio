#!/usr/bin/env python3
"""Finite local audio/network API. Passwords arrive on stdin, never in argv/logs."""
import json,math,subprocess,sys,re

def run(args,timeout=5,input=None):
 p=subprocess.run(args,input=input,text=True,capture_output=True,timeout=timeout)
 if p.returncode:raise RuntimeError('The device did not accept that change.')
 return p.stdout.strip()
def fields(line):
 result=[];s='';escaped=False
 for c in line:
  if escaped:s+=c;escaped=False
  elif c=='\\':escaped=True
  elif c==':':result.append(s);s=''
  else:s+=c
 result.append(s);return result

def devices():
 rows=[]
 for line in run(['nmcli','--colors','no','-t','-f','DEVICE,TYPE,STATE,CONNECTION','device','status']).splitlines():
  f=fields(line)
  if len(f)>=4:rows.append(dict(device=f[0],type=f[1],state=f[2],connection=f[3]))
 return rows

def networks():
 result={}
 for line in run(['nmcli','--colors','no','-t','-f','IN-USE,SSID,SIGNAL,SECURITY,DEVICE','device','wifi','list','--rescan','no']).splitlines():
  f=fields(line)
  if len(f)<5 or not f[1]:continue
  try:strength=int(f[2])
  except ValueError:continue
  row=dict(active=f[0]=='*',ssid=f[1],signal=strength,security=f[3],device=f[4])
  key=(f[1],f[4])
  if key not in result or row['active'] or strength>result[key]['signal']:result[key]=row
 return sorted(result.values(),key=lambda n:(not n['active'],-n['signal'],n['ssid'].lower()))

def streams():return json.loads(run(['pactl','-f','json','list','sink-inputs']))

def sinks():return json.loads(run(['pactl','-f','json','list','sinks']))
def output_label(s):
 desc=s.get('description',s['name'])
 if 'hdmi' in s['name'].lower():
  port=re.search(r'\((HDMI[^)]*)\)',desc,re.I)
  monitor=re.search(r'\[([^]]+)\]',desc)
  return ('NVIDIA' if 'GB205' in desc or 'NVIDIA' in desc else 'Display audio')+' · '+(port.group(1) if port else 'HDMI')+('\n'+monitor.group(1) if monitor else '')
 if 'Ryzen' in desc:return 'Motherboard · Ryzen HD Audio'
 return desc

def percent(sink):
 vals=[v.get('value',0)/65536*100 for v in sink.get('volume',{}).values()]
 return round(sum(vals)/len(vals)) if vals else 0

def snapshot(rescan=False):
 data=dict(volume=0,muted=False,micVolume=0,micMuted=False,micAvailable=False,apps=[],outputs=[],ports=[],devices=[],networks=[],wifiEnabled=False,wifiDevice='',audioError='',networkError='')
 try:
  default=run(['pactl','get-default-sink']);raw=sinks()
  for s in raw:
   data['outputs'].append(dict(name=s['name'],label=output_label(s),active=s['name']==default))
   if s['name']==default:
    data.update(volume=percent(s),muted=s.get('mute',False),outputLabel=s.get('description',s['name']))
    data['ports']=[dict(name=p['name'],label=p.get('description',p['name']),active=p['name']==s.get('active_port')) for p in s.get('ports',[]) if p.get('availability')!='not available']
  # Per-app rows are live playback streams. Exclude the companion's silent
  # wallpaper outputs, which do not identify an actual user application.
  data['apps']=[]
  for stream in streams():
   props=stream.get('properties',{})
   if not props.get('application.name') and props.get('node.name')=='quickshell' and props.get('media.name')=='quickshell':continue
   label=props.get('application.name') or props.get('application.process.binary') or props.get('media.name') or 'Application'
   data['apps'].append(dict(index=stream['index'],label=label,volume=percent(stream),muted=stream.get('mute',False),writable=stream.get('volume_writable',True) and stream.get('has_volume',True)))
  try:
   source=run(['pactl','get-default-source'])
   mic=next((s for s in json.loads(run(['pactl','-f','json','list','sources'])) if s['name']==source and not s['name'].endswith('.monitor')),None)
   if mic:data.update(micVolume=percent(mic),micMuted=mic.get('mute',False),micAvailable=True)
  except (RuntimeError,ValueError,subprocess.SubprocessError):pass
 except (OSError,ValueError,RuntimeError,subprocess.SubprocessError):data['audioError']='Audio controls are unavailable.'
 try:
  data['devices']=devices();wifi=next((d for d in data['devices'] if d['type']=='wifi'),None)
  data['wifiDevice']=wifi['device'] if wifi else ''
  data['wifiEnabled']=run(['nmcli','radio','wifi'])=='enabled'
  if rescan and wifi and data['wifiEnabled']:
   try:run(['nmcli','device','wifi','rescan','ifname',wifi['device']],timeout=12)
   except RuntimeError:pass
  if wifi and data['wifiEnabled']:data['networks']=networks()
 except (OSError,ValueError,RuntimeError,subprocess.SubprocessError):data['networkError']='Network controls are unavailable.'
 return data

def apply(req):
 action=req.get('action')
 if action=='volume':
  n=req.get('value')
  if isinstance(n,bool) or not isinstance(n,(int,float)) or not math.isfinite(n) or not 0<=n<=100:raise ValueError('Volume must be between 0 and 100.')
  run(['pactl','set-sink-volume','@DEFAULT_SINK@',str(round(n))+'%'])
 elif action=='mic-volume':
  n=req.get('value')
  if isinstance(n,bool) or not isinstance(n,(int,float)) or not math.isfinite(n) or not 0<=n<=100:raise ValueError('Volume must be between 0 and 100.')
  run(['pactl','set-source-volume','@DEFAULT_SOURCE@',str(round(n))+'%'])
 elif action=='mic-mute':run(['pactl','set-source-mute','@DEFAULT_SOURCE@','toggle'])
 elif action in ('app-volume','app-mute'):
  index=req.get('index')
  if type(index)is not int:raise ValueError('Invalid playback stream.')
  stream=next((s for s in streams() if s['index']==index),None)
  if stream is None:raise ValueError('That application stopped playing. The list will refresh.')
  if action=='app-mute':run(['pactl','set-sink-input-mute',str(index),'toggle'])
  else:
   n=req.get('value')
   if isinstance(n,bool) or not isinstance(n,(int,float)) or not math.isfinite(n) or not 0<=n<=100:raise ValueError('Volume must be between 0 and 100.')
   if not stream.get('volume_writable',True) or not stream.get('has_volume',True):raise ValueError('This application manages its own volume.')
   run(['pactl','set-sink-input-volume',str(index),str(round(n))+'%'])
 elif action=='mute':run(['pactl','set-sink-mute','@DEFAULT_SINK@','toggle'])
 elif action=='output':
  name=req.get('name');available=sinks()
  if name not in [s['name'] for s in available]:raise ValueError('That output is no longer available.')
  run(['pactl','set-default-sink',name])
  for stream in json.loads(run(['pactl','-f','json','list','sink-inputs'])):
   try:run(['pactl','move-sink-input',str(stream['index']),name])
   except RuntimeError:pass
 elif action=='port':
  default=run(['pactl','get-default-sink']);s=next(s for s in sinks() if s['name']==default)
  if req.get('name') not in [p['name'] for p in s.get('ports',[]) if p.get('availability')!='not available']:raise ValueError('That connector is no longer available.')
  run(['pactl','set-sink-port',default,req['name']])
 elif action=='radio':
  if type(req.get('enabled'))is not bool:raise ValueError('Invalid Wi-Fi setting.')
  run(['nmcli','radio','wifi','on' if req['enabled'] else 'off'])
 elif action in ('connect','disconnect'):
  device=req.get('device');ds=devices()
  if device not in [d['device'] for d in ds if d['type']=='wifi']:raise ValueError('Wi-Fi adapter is unavailable.')
  if action=='disconnect':run(['nmcli','--wait','20','device','disconnect',device],timeout=23)
  else:
   ssid=req.get('ssid');password=req.get('password','')
   if not isinstance(ssid,str) or not ssid or ssid.startswith('-') or len(ssid.encode())>32:raise ValueError('Invalid network name.')
   if not isinstance(password,str) or '\n' in password or '\r' in password or len(password)>256:raise ValueError('Invalid Wi-Fi password.')
   if not any(n['ssid']==ssid and n['device']==device for n in networks()):raise ValueError('Network is no longer visible. Refresh and try again.')
   # --ask reads the secret from stdin. It is not put on the command line.
   try:run(['nmcli','--ask','--wait','25','device','wifi','connect',ssid,'ifname',device],timeout=28,input=password+'\n')
   except (RuntimeError,subprocess.SubprocessError):raise RuntimeError('Could not connect. Check the password or refresh the network list.') from None
 else:raise ValueError('Unknown control action.')
 return dict(ok=True)

def main():
 mode=sys.argv[1] if len(sys.argv)>1 else 'snapshot'
 try:
  if mode in ('snapshot','scan'):result=snapshot(mode=='scan')
  elif mode=='apply':result=apply(json.loads(sys.stdin.readline(8192)))
  else:raise ValueError('Unknown request.')
 except (ValueError,RuntimeError) as exc:result={'error':str(exc)}
 except Exception:result={'error':'Could not complete the device request.'}
 print(json.dumps(result),flush=True)
if __name__=='__main__':main()
