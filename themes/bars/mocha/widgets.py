#!/usr/bin/env python3
"""Local uptime and Pomodoro widgets; no external timer package required."""
import fcntl,json,os,sys,tempfile,time
from pathlib import Path
DURATIONS={'work':25*60,'break':5*60}
def update(state,now,action):
 state=dict(state)
 if state.get('running'):
  state['remaining']=max(0,state['remaining']-(now-state['updated']))
  if state['remaining']<=0:
   state['phase']='break' if state['phase']=='work' else 'work'
   state['remaining']=DURATIONS[state['phase']];state['running']=False
 if action=='reset':state={'phase':'work','remaining':1500,'running':False}
 elif action=='toggle':state['running']=not state['running']
 state['updated']=now
 return state

def main():
 action=sys.argv[1] if len(sys.argv)>1 else 'show'
 if action=='uptime':
  seconds=float(Path('/proc/uptime').read_text().split()[0]);hours=int(seconds//3600)
  print(json.dumps({'text':f'↑ {hours//24}d {hours%24}h' if hours>=24 else f'↑ {hours}h {int(seconds%3600//60)}m','tooltip':'System uptime'}));return
 folder=Path.home()/'.local/state/bar-switcher/mocha';folder.mkdir(mode=0o700,parents=True,exist_ok=True)
 with (folder/'timer.lock').open('a')as lock:
  fcntl.flock(lock,fcntl.LOCK_EX);path=folder/'timer.json';now=time.time()
  try:state=json.loads(path.read_text())
  except (OSError,ValueError):state={'phase':'work','remaining':1500,'running':False,'updated':now}
  state=update(state,now,action)
  fd,name=tempfile.mkstemp(dir=folder)
  with os.fdopen(fd,'w')as f:json.dump(state,f)
  os.replace(name,path)
  minutes,seconds=divmod(int(state['remaining']+.999),60)
  icon='▶' if state['running'] else 'Ⅱ'
  print(json.dumps({'text':f'{icon} {minutes:02}:{seconds:02}','class':state['phase'] if state['running'] else 'paused','tooltip':f"{state['phase'].title()}: 25m work / 5m break\nClick: start/pause • right-click: reset\nNext phase waits for you to start it"}))
if __name__=='__main__':main()
