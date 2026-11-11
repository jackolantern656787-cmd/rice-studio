"""Isolated Hyprland adapter. Original desktop daemons/configs are never replaced."""
from pathlib import Path
import os,json,subprocess,shutil,time,tempfile,fcntl,re
HOME=Path(os.environ.get('RICE_STUDIO_HOME',str(Path.home())))
CONFIG=HOME/'.config/rice-studio-portable';STATE=HOME/'.local/state/rice-studio-portable';APP=HOME/'.local/share/rice-studio-portable'
OPTIONS=('general:gaps_in','general:gaps_out','decoration:rounding','general:border_size','general:col.active_border')
def read(path,default=None):
 try:return json.loads(Path(path).read_text())
 except FileNotFoundError:return {} if default is None else default
def atomic(path,data):
 path=Path(path);path.parent.mkdir(parents=True,exist_ok=True)
 fd,tmp=tempfile.mkstemp(dir=path.parent)
 try:
  with os.fdopen(fd,'w') as f:json.dump(data,f,indent=2);f.write('\n');f.flush();os.fsync(f.fileno())
  os.chmod(tmp,0o600);os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def run(args):
 result=subprocess.run(args,capture_output=True,text=True,check=True,timeout=15)
 out=result.stdout.strip()
 if out.lower().startswith(('error','unknown request','keyword can')):raise RuntimeError(out)
 return out

def capture_original():
 # Read compositor values before Studio applies anything. Do not copy arbitrary configs.
 options={}
 for name in OPTIONS:
  d=json.loads(run(['hyprctl','getoption',name,'-j']))
  for field in ('int','float','str','css','gradient'):
   if field in d:
    value=d[field]
    if field=='gradient':value=' '.join('rgba('+v[2:]+v[:2]+')' if re.fullmatch('[a-fA-F0-9]{8}',v) else v for v in value.split())
    options[name]=value;break
  else:raise RuntimeError('Cannot capture compositor option '+name)
 return {'desktop':'main','options':options,'theme':{},'wallpapers':{},'terminal':'main','bar':'main','launcher_theme':'original','window_style':'original'}
def ensure_main():
 STATE.mkdir(parents=True,exist_ok=True,mode=0o700)
 with (STATE/'baseline.lock').open('a') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  path=STATE/'original-main.json'
  if path.exists():
   data=read(path)
   if not isinstance(data.get('options'),dict) or not all(k in data['options'] for k in OPTIONS):raise ValueError('Original Main is incomplete; refusing to replace it.')
   return data
  data=capture_original();data['serp_bar']=serp_bar();atomic(path,data);return data

def registry():
 result = {'main': ('Original bar', 'Personal Main'), 'studio': ('Studio panel', 'Native panel')}
 for folder in sorted((APP / 'themes/bars').glob('*')):
  if (folder / 'config.jsonc').is_file():
   result[folder.name] = (folder.name.replace('-', ' ').title(), 'Bundled Waybar')
 if (APP / 'themes/extras/serashell/shell.qml').is_file():
  result['serashell'] = ('Serashell', 'Native Quickshell panel')
 return result


def serp_bar(value=None):
 shell = HOME / '.local/share/serpantinum/src/quickshell/Shell.qml'
 if not shell.is_file():
  return None
 args = ['quickshell', '-p', str(shell), 'ipc', 'call', 'barSwitcher']
 try:
  output = run(args + (['status'] if value is None else ['setHidden', 'true' if value else 'false']))
 except (OSError, RuntimeError, subprocess.SubprocessError):
  return None
 return output.splitlines()[-1].strip() if output.strip() else None


def wait_for_bar(profile):
 bar = profile.get('bar')
 if not profile.get('rice') or bar in ('studio', 'main', None):
  return
 config = APP / ('themes/extras/serashell/shell.qml' if bar == 'serashell' else f'themes/bars/{bar}/config.jsonc')
 deadline = time.monotonic() + 8
 while time.monotonic() < deadline:
  layers = json.loads(run(['hyprctl', 'layers', '-j']))
  if layers:
   found = []
   for monitor in layers.values():
    ready = False
    for level in monitor.get('levels', {}).values():
     for item in level:
      try:
       command = Path('/proc', str(item['pid']), 'cmdline').read_bytes().split(b'\0')
      except (OSError, KeyError):
       continue
      if os.fsencode(config) in command:
       ready = True
       break
    found.append(ready)
   if all(found):
    return
  time.sleep(.2)
 raise RuntimeError(f'The {bar} bar did not appear on all outputs.')
def snapshot():
 # Read exact runtime values for timed rollback, including an intermediate Studio theme.
 data=capture_original();data['desktop']=(STATE/'current').read_text().strip() if (STATE/'current').exists() else 'main'
 data['serp_bar']=serp_bar()
 return data

def set_options(options):
 version=run(['hyprctl','version'])
 # Hyprland Lua API is used when present. Older releases use the keyword API.
 match=re.search(r'Hyprland (\d+)\.(\d+)',version)
 lua=bool(match and tuple(map(int,match.groups()))>=(0,57)) or (HOME/'.config/hypr/hyprland.lua').exists()
 if lua:
  groups={}
  for name,value in options.items():
   group,key=name.split(':',1)
   if 'gaps_' in key and isinstance(value,str):
    parts=[int(v) for v in value.split()]
    if len(parts)==1:parts=parts*4
    elif len(parts)==2:parts=parts*2
    elif len(parts)==3:parts=[parts[0],parts[1],parts[2],parts[1]]
    if len(parts)!=4:raise ValueError('Unsupported saved gap format')
    value=dict(zip(('top','right','bottom','left'),parts))
   if key=='col.active_border' and isinstance(value,str) and 'deg' in value:
    parts=value.split();value={'colors':parts[:-1],'angle':float(parts[-1].removesuffix('deg'))}
   groups.setdefault(group,{})[key]=value
  def encode(v):
   if isinstance(v,list):return '{'+','.join(encode(x) for x in v)+'}'
   if isinstance(v,dict):return '{'+','.join('['+json.dumps(k)+']='+encode(x) for k,x in v.items())+'}'
   return json.dumps(v)
  run(['hyprctl','eval','hl.config('+encode(groups)+')'])
 else:
  for name,value in options.items():run(['hyprctl','keyword',name,str(value)])

def start_components():
 subprocess.run(['quickshell','-n','-d','-p',str(APP/'desktop.qml')],capture_output=True,check=True,timeout=10)
 subprocess.run(['quickshell','-n','-d','-p',str(APP/'widgets.qml')],capture_output=True,check=True,timeout=10)

def write_current(key):
 path=STATE/'current';fd,tmp=tempfile.mkstemp(dir=STATE)
 try:
  with os.fdopen(fd,'w') as f:f.write(key+'\n')
  os.replace(tmp,path)
 finally:
  if os.path.exists(tmp):os.unlink(tmp)
def apply_desktop(key):
 main=ensure_main();profiles=read(CONFIG/'profiles.json')
 if key not in profiles:raise ValueError('Unknown preset')
 before=snapshot()
 try:
  if key=='main':set_options(main['options'])
  else:
   p=profiles[key]
   t=p['theme']
   style=p.get('window_style','standard')
   frames={
    'phosphor':(0,1,'38463bff'),
    'dark-cattpuccin':(16,3,'bac2deff'),
    'stillwater':(0,2,'c87c70ff'),
    'cold-front':(3,2,'64b6eeff'),
    'honeyveil':(10,3,'c4b58cff'),
    'teigu':(8,2,'68656bff'),
    'tideglass':(3,1,'8998b999'),
    'cyanframe':(8,2,'bbd8dcaa'),
    'viegphunt':(2,2,'cdd6f4aa'),
    'serashell':(14,2,'4b3d43ee'),
   }
   rounding,border,color=frames.get(style,(t['borderRadius'],2,t['colors']['blue'].lstrip('#')+'ff'))
   # A bundled bar reserves its own space. The fallback panel does not.
   gaps_in,gaps_out={'viegphunt':(2,5),'serashell':(5,8)}.get(style,(6,8))
   if not p.get('rice') or p.get('bar')=='studio':gaps_out=38
   set_options({'general:gaps_in':gaps_in,'general:gaps_out':gaps_out,
                'decoration:rounding':rounding,'general:border_size':border,
                'general:col.active_border':'rgba('+color+')'})
  write_current(key);start_components()
  if key == 'main' or profiles[key].get('bar') == 'main':
   serp_bar(main.get('serp_bar') == 'hidden')
  else:
   wait_for_bar(profiles[key])
   if serp_bar() == 'main':
    serp_bar(True)
 except Exception:
  restore_snapshot(before);raise

def restore_snapshot(data):
 if not isinstance(data.get('options'),dict):raise ValueError('Missing compositor snapshot')
 set_options(data['options'])
 write_current(data.get('desktop','main'))
 serp_bar(data.get('serp_bar') == 'hidden')
 start_components()
