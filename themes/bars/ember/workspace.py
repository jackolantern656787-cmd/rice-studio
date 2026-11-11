#!/usr/bin/env python3
import json,subprocess,sys,time,fcntl,os,tempfile
from pathlib import Path
folder=Path.home()/'.cache/bar-switcher';folder.mkdir(parents=True,exist_ok=True);cache=folder/'beige-workspace.json'
try:
 with (folder/'beige-workspace.lock').open('a')as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  try:data=json.loads(cache.read_text())
  except (OSError,ValueError):data={}
  if time.time()-data.get('time',0)>.5:
   p=subprocess.run(['hyprctl','activeworkspace','-j'],text=True,capture_output=True,timeout=2,check=True)
   data={'time':time.time(),'id':json.loads(p.stdout)['id']}
   fd,name=tempfile.mkstemp(dir=folder)
   with os.fdopen(fd,'w')as f:json.dump(data,f)
   os.replace(name,cache)
 active=int(data.get('id',0))
except (OSError,ValueError,KeyError,subprocess.SubprocessError):active=0
number=int(sys.argv[1]);print(json.dumps({'text':str(number),'class':'active'if number==active else'inactive','tooltip':f'Workspace {number}'}))
