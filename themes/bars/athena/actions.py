#!/usr/bin/env python3
"""Mechabar desktop actions. Power operations require a second explicit selection."""
import os,subprocess,sys
from pathlib import Path

def picker(rows,title):
 env=os.environ.copy();env['FZF_DEFAULT_OPTS']='';env['FZF_DEFAULT_OPTS_FILE']='/dev/null'
 result=subprocess.run(['fzf','--no-input','--no-sort','--height=14','--layout=reverse','--border=sharp','--border-label='+title,'--header=Enter selects • Esc cancels','--info=hidden'],input='\n'.join(rows)+'\n',text=True,stdout=subprocess.PIPE,env=env)
 return result.stdout.strip()if result.returncode==0 else None

def power_menu():
 options=['Lock','Logout','Suspend','Reboot','Shutdown']
 choice=picker(options,' POWER MENU ')
 if choice not in options:return 0
 if choice!='Lock':
  confirm=picker(['Cancel','Confirm '+choice],' CONFIRM '+choice.upper()+' ')
  if confirm!='Confirm '+choice:return 0
 command={'Lock':'lock','Logout':'exit','Suspend':'suspend','Reboot':'reboot','Shutdown':'poweroff'}[choice]
 return subprocess.run([str(Path.home()/'.local/bin/serpantinum'),command]).returncode

def temperature():
 # Resolve the AMD CPU sensor on every read; hwmon numbers may change at boot.
 for name in Path('/sys/class/hwmon').glob('hwmon*/name'):
  try:
   if name.read_text().strip()!='k10temp':continue
   inputs=sorted(name.parent.glob('temp*_input'))
   for sensor in inputs:
    label=sensor.with_name(sensor.name.replace('_input','_label'))
    if label.exists()and label.read_text().strip()in ('Tctl','Tdie'):
     return float(sensor.read_text())/1000
   if inputs:return float(inputs[0].read_text())/1000
  except (OSError,ValueError):continue
 return None

def temperature_json():
 import json
 value=temperature()
 if value is None:print(json.dumps({'text':'󱃃 N/A','tooltip':'CPU sensor unavailable','class':'unavailable'}));return 0
 print(json.dumps({'text':f'󱃃 {value:.0f}°C','tooltip':f'AMD CPU package: {value:.1f}°C\nClick: system monitor • right-click: GPU monitor','class':'critical'if value>=90 else 'normal'}));return 0

def main():
 action=sys.argv[1]if len(sys.argv)>1 else ''
 if action=='power':return power_menu()
 if action=='temperature':return temperature_json()
 print('Usage: actions.py power|temperature',file=sys.stderr);return 2
if __name__=='__main__':sys.exit(main())
