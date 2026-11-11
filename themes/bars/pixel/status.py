#!/usr/bin/env python3
"""Local CPU/RAM gauges and current keyboard language for Graphite."""
import fcntl,json,os,subprocess,sys,tempfile,time
from pathlib import Path
mode=sys.argv[1]
if mode=='language':
 try:
  devices=json.loads(subprocess.check_output(['hyprctl','devices','-j'],text=True,timeout=2));keys=devices.get('keyboards',[])
  keyboard=next((k for k in keys if k.get('main')),keys[0] if keys else {})
  layout=keyboard.get('active_keymap','English');code='EN' if 'English'in layout else 'AR' if 'Arabic'in layout else layout[:2].upper()
  print(json.dumps({'text':code,'tooltip':layout+' • click: settings'}))
 except (OSError,ValueError,subprocess.SubprocessError):print(json.dumps({'text':'—','tooltip':'Keyboard information unavailable'}))
 raise SystemExit
if mode=='cpu':
 fields=list(map(int,Path('/proc/stat').read_text().splitlines()[0].split()[1:9]));total=sum(fields);idle=fields[3]+fields[4]
 folder=Path.home()/'.cache/bar-switcher';folder.mkdir(parents=True,exist_ok=True)
 with (folder/'graphite-cpu.lock').open('a')as lock:
  fcntl.flock(lock,fcntl.LOCK_EX);cache=folder/'graphite-cpu.json'
  try:old=json.loads(cache.read_text())
  except (OSError,ValueError):old={}
  value=old.get('value',0)
  if time.time()-old.get('time',0)>=1:
   delta=total-old.get('total',total)
   if delta>0:value=max(0,min(100,100*(1-(idle-old.get('idle',idle))/delta)))
   fd,name=tempfile.mkstemp(dir=folder)
   with os.fdopen(fd,'w')as f:json.dump({'total':total,'idle':idle,'value':value,'time':time.time()},f)
   os.replace(name,cache)
 tooltip=f'CPU usage: {value:.0f}% • click: system monitor'
else:
 info={line.split(':')[0]:int(line.split()[1])for line in Path('/proc/meminfo').read_text().splitlines()}
 value=100*(1-info['MemAvailable']/info['MemTotal']);tooltip=f"RAM: {(info['MemTotal']-info['MemAvailable'])/1048576:.1f}/{info['MemTotal']/1048576:.1f} GiB"
filled=round(value*8/100);bars='<span foreground="#bbbbbb">'+'▮'*filled+'</span><span foreground="#3e3e3e">'+'▮'*(8-filled)+'</span>'
print(json.dumps({'text':f'{mode} {bars} {value:.0f}%','tooltip':tooltip}))
