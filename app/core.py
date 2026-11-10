"""Constrained preset editing, widget layouts and recovery checkpoints."""
from pathlib import Path
import os,json,tempfile,re,shutil,time,fcntl,importlib.util,subprocess,sys,uuid
HOME=Path(os.environ.get('RICE_STUDIO_HOME',str(Path.home())))
CONFIG=HOME/'.config/rice-studio-portable';STATE=HOME/'.local/state/rice-studio-portable';APP=HOME/'.local/share/rice-studio-portable'
FILES={'profiles':CONFIG/'profiles.json','widgets':CONFIG/'widgets.json'}
WIDGETS=('clock','calendar','cpu','ram','music','notes')
def read(path,default=None):
 try:return json.loads(Path(path).read_text())
 except FileNotFoundError:return {} if default is None else default
def atomic(path,data):
 path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
 fd,tmp=tempfile.mkstemp(dir=path.parent)
 try:
  with os.fdopen(fd,'w') as f:json.dump(data,f,indent=2);f.write('\n')
  os.chmod(tmp,0o600);os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def control():
 spec=importlib.util.spec_from_file_location('rice_control',APP/'control.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod
def checkpoint(label,desktop=False):
 STATE.mkdir(parents=True,exist_ok=True)
 ident=time.strftime('%Y%m%d-%H%M%S')+'-'+uuid.uuid4().hex[:6]
 data={'id':ident,'label':label,'created':time.time(),'files':{k:read(p,{}) for k,p in FILES.items()}}
 if desktop:data['desktop']=control().snapshot()
 path=STATE/'history'/(ident+'.json');atomic(path,data);return path
def validate_profile(p):
 if not p.get('label','').strip():raise ValueError('Give the preset a name.')
 wall=Path(p['wallpaper']).expanduser()
 if not wall.is_file():raise ValueError('Choose an existing wallpaper file.')
 if wall.suffix.lower() not in ('.png','.jpg','.jpeg','.webp','.mp4','.webm'):raise ValueError('Unsupported wallpaper format.')
 p['wallpaper']=str(wall)
 theme=p['theme'];theme['borderRadius']=max(0,min(40,int(theme['borderRadius'])))
 for key,val in theme['colors'].items():
  if not re.fullmatch('#[a-fA-F0-9]{6}',val):raise ValueError('Invalid color for '+key)
 return p
def save_profile(key,profile):
 data=read(FILES['profiles'])
 if key=='main':raise ValueError('Main is your recovery baseline. Use Duplicate to create an editable copy.')
 if key not in data:raise ValueError('Preset no longer exists')
 validate_profile(profile)
 if profile['bar'] not in control().registry():raise ValueError('Choose an installed bar')
 if profile['terminal']!='main' and not (CONFIG/'terminals'/(profile['terminal']+'.conf')).is_file():raise ValueError('Choose an installed terminal profile')
 checkpoint('Before editing '+key);data[key]=profile;atomic(FILES['profiles'],data)
def save_widgets(key,items):
 for item in items:
  if item['kind'] not in WIDGETS:raise ValueError('Unknown widget')
  for attr,lo,hi in [('x',0,16000),('y',0,16000),('width',180,1400),('height',100,1000)]:item[attr]=max(lo,min(hi,int(item[attr])))
  item['text']=item.get('text','')[:1000];item['enabled']=bool(item.get('enabled',True))
 checkpoint('Before widgets '+key);data=read(FILES['widgets']);data[key]=items;atomic(FILES['widgets'],data)
def restore_files(data):
 for key,value in data['files'].items():
  if key in FILES:atomic(FILES[key],value)
def restore(path):
 data=read(path);checkpoint('Before restoring '+data['label']);restore_files(data)
 if 'desktop' in data:control().restore_snapshot(data['desktop'])
def start_preview(key,seconds=30):
 pending=STATE/'pending.json';old=read(pending)
 if old.get('status') in ('starting','preview'):raise ValueError('Keep or revert the current preview first.')
 if key not in read(FILES['profiles']):raise ValueError('Unknown preset')
 path=checkpoint('Before preview '+key,True)
 info={'checkpoint':str(path),'key':key,'status':'starting','deadline':time.time()+90};atomic(pending,info)
 # Independent watchdog survives closing the GUI.
 subprocess.Popen([sys.executable,str(APP/'manager.py'),'--watch'],start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 try:
  control().apply_desktop(key)
  widgets=APP/'widgets.qml'
  subprocess.run(['quickshell','-n','-d','-p',str(widgets)],check=True,capture_output=True,timeout=10)
  info.update(status='preview',deadline=time.time()+seconds);atomic(pending,info)
 except Exception:
  finish_preview(False);raise
def finish_preview(keep):
 STATE.mkdir(parents=True,exist_ok=True)
 with (STATE/'preview.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX);p=STATE/'pending.json';data=read(p)
  if data.get('status') not in ('starting','preview'):return
  data['status']='keeping' if keep else 'reverting';atomic(p,data)
  try:
   if not keep:
    prior=read(data['checkpoint']);restore_files(prior);control().restore_snapshot(prior['desktop'])
   data['status']='kept' if keep else 'reverted'
  except Exception as exc:data['status']='recovery-failed';data['error']=str(exc);atomic(p,data);raise
  atomic(p,data)
def watchdog():
 while True:
  p=read(STATE/'pending.json')
  if p.get('status') not in ('starting','preview'):return
  if time.time()>=p['deadline']:finish_preview(False);return
  time.sleep(1)
