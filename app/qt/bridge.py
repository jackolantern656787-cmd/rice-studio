#!/usr/bin/env python3
"""Finite local JSON-lines API over a child-process pipe; no listening socket."""
from pathlib import Path
import sys,json,os,time,copy,subprocess,threading,concurrent.futures,contextlib,io,hashlib,shutil,signal
APP=Path(__file__).resolve().parent
sys.path.insert(0,str(APP.parent));import core
import window_mode as modes
OUT=sys.stdout;LOCK=threading.Lock()
def send(value):
 try:
  with LOCK:OUT.write(json.dumps(value,separators=(',',':'))+'\n');OUT.flush()
 except BrokenPipeError:pass
def current():
 try:return (core.STATE/'current').read_text().strip()
 except OSError:return 'main'
def history():
 result=[]
 for path in sorted((core.STATE/'history').glob('*.json'),reverse=True)[:150]:
  d=core.read(path);result.append({'id':path.stem,'label':d.get('label','Checkpoint'),'time':time.strftime('%d %b %Y · %H:%M',time.localtime(d.get('created',path.stat().st_mtime))),'desktop':bool(d.get('desktop'))})
 return result
def preview_url(value):
 path=Path(value)
 if not path.is_file():return ''
 if path.suffix.lower() in ('.png','.jpg','.jpeg'):return path.as_uri()
 if path.suffix.lower() in ('.mp4','.webm'):
  folder=core.HOME/'.cache/rice-studio/previews';folder.mkdir(parents=True,exist_ok=True,mode=0o700)
  target=folder/(hashlib.sha256((str(path)+str(path.stat().st_mtime_ns)).encode()).hexdigest()[:24]+'.png')
  if not target.exists():
   try:subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(path),'-frames:v','1','-vf','scale=1200:-2','-y',str(target)],capture_output=True,timeout=15,check=True)
   except (OSError,subprocess.SubprocessError):return ''
  return target.as_uri()
 if path.suffix.lower() not in ('.webp','.gif','.bmp','.tif','.tiff'):return ''
 # Qt image plugins differ across installations; preserve the original and
 # cache a lossless display copy for unsupported formats.
 from PIL import Image
 folder=core.HOME/'.cache/rice-studio/previews';folder.mkdir(parents=True,exist_ok=True,mode=0o700)
 target=folder/(hashlib.sha256((str(path)+str(path.stat().st_mtime_ns)).encode()).hexdigest()[:24]+'.png')
 if not target.exists():
  with Image.open(path) as im:im.convert('RGB').save(target)
 return target.as_uri()
def window_mode():
 try:return modes.status(core.control())
 except (OSError,RuntimeError,ValueError,subprocess.SubprocessError):return 'unavailable'
def bootstrap():
 profiles=core.read(core.FILES['profiles']);fallback=core.read(core.CONFIG/'main.json').get('theme',{});widgets=core.read(core.FILES['widgets']);rows=[]
 for key,p in profiles.items():
  item=copy.deepcopy(p);item.setdefault('theme',copy.deepcopy(fallback));rows.append({'key':key,'title':p['label'].split('·')[0].strip(),'description':p['label'].partition('·')[2].strip(),'profile':item,'image':preview_url(p.get('wallpaper','')), 'widgetCount':len(widgets.get(key,[]))})
 bars=[{'key':k,'label':v[0]} for k,v in core.control().registry().items()]
 terminals=['main']+sorted({p['terminal'] for p in profiles.values() if p.get('terminal') and p['terminal']!='main'})
 return {'notes':core.read(core.CONFIG/'studio-notes.json'),'media':media_library(),'health':health(),'windowMode':window_mode(),'profiles':rows,'bars':bars,'terminals':terminals,'widgets':widgets,'history':history(),'current':current(),'preferences':core.read(core.CONFIG/'studio-ui.json'),'pending':core.read(core.STATE/'pending.json'),'widgetTypes':list(core.WIDGETS)}
def keycheck(key):
 if key not in core.read(core.FILES['profiles']):raise ValueError('That preset no longer exists. Reload the collection.')
 return key
def media_library():
 result={}
 for key in core.read(core.FILES['profiles']):
  folder=core.STATE/'media'/key
  result[key]=[{'url':f.as_uri(),'name':f.name,'video':f.suffix=='.mp4'} for f in sorted(folder.glob('*'),reverse=True) if f.suffix in ('.png','.mp4')][:12]
 return result
def health():
 names=('quickshell','hyprctl','kitty','grim','wf-recorder','ffmpeg','nmcli','pactl','waybar','wofi','cava','fastfetch','starship')
 rows=[{'name':n,'ok':bool(shutil.which(n)),'detail':shutil.which(n) or 'Not installed'} for n in names]
 return rows
def capture_media(key,video=False):
 keycheck(key)
 if key!=current():raise ValueError('Capture the active rice only. Preview and Keep this preset first.')
 # Monitor names come from Hyprland, never from a shell command string.
 monitors=json.loads(subprocess.run(['hyprctl','monitors','-j'],capture_output=True,text=True,check=True,timeout=5).stdout)
 monitor=next((m['name'] for m in monitors if m.get('focused')),monitors[0]['name'])
 folder=core.STATE/'media'/key;folder.mkdir(parents=True,exist_ok=True,mode=0o700)
 target=folder/(time.strftime('%Y%m%d-%H%M%S')+'-'+core.uuid.uuid4().hex[:6]+('.mp4' if video else '.png'))
 try:
  if video:
   proc=subprocess.Popen(['wf-recorder','-o',monitor,'-r','30','-f',str(target)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   try:proc.wait(timeout=8)
   except subprocess.TimeoutExpired:
    proc.send_signal(signal.SIGINT)
    try:proc.wait(timeout=5)
    except subprocess.TimeoutExpired:proc.kill();proc.wait();raise RuntimeError('Recorder did not finish cleanly.')
   if proc.returncode not in (0,130,-signal.SIGINT):raise RuntimeError('Screen recording failed.')
  else:subprocess.run(['grim','-o',monitor,str(target)],check=True,capture_output=True,timeout=10)
  if not target.exists() or target.stat().st_size<100:raise RuntimeError('No capture was produced.')
  os.chmod(target,0o600)
 except Exception:
  target.unlink(missing_ok=True);raise
 return {'media':media_library()}
def handle(method,p):
 if method=='notes':
  key=keycheck(p['key']);before=core.read(core.CONFIG/'studio-notes.json');before[key]=str(p.get('text',''))[:4000];core.atomic(core.CONFIG/'studio-notes.json',before);return {'notes':before}
 if method=='import_media':
  key=keycheck(p['key']);source=Path(p['path']).expanduser().resolve()
  if not source.is_file() or source.suffix.lower() not in ('.png','.jpg','.jpeg','.webp','.mp4','.webm'):raise ValueError('Choose an image or video file.')
  if source.stat().st_size>250_000_000:raise ValueError('Choose a file smaller than 250 MB.')
  folder=core.STATE/'media'/key;folder.mkdir(parents=True,exist_ok=True,mode=0o700)
  target=folder/(time.strftime('%Y%m%d-%H%M%S')+'-'+core.uuid.uuid4().hex[:6]+('.mp4' if source.suffix.lower() in ('.mp4','.webm') else '.png'))
  try:
   if target.suffix=='.png':
    from PIL import Image
    with Image.open(source) as image:image.convert('RGB').save(target)
   else:subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(source),'-t','30','-an','-vf',"scale=w='trunc(min(1920,iw)/2)*2':h=-2",'-c:v','libx264','-preset','fast','-crf','23','-y',str(target)],capture_output=True,check=True,timeout=90)
   os.chmod(target,0o600)
  except Exception:target.unlink(missing_ok=True);raise
  return {'media':media_library()}
 if method=='capture':return capture_media(keycheck(p['key']),bool(p.get('video',False)))
 if method=='health':return {'health':health()}
 if method=='window_mode':return {'windowMode':modes.switch(core.control(),p.get('mode'))}
 if method=='bootstrap':return bootstrap()
 if method=='wallpaper_preview':return {'previewUrl':preview_url(p['path'])}
 if method=='status':return {'windowMode':window_mode(),'pending':core.read(core.STATE/'pending.json'),'current':current()}
 if method=='preferences':
  before=core.read(core.CONFIG/'studio-ui.json')
  for key in ('skip_welcome','reduce_motion'):
   if key in p:before[key]=bool(p[key])
  if 'favorites' in p:before['favorites']=[keycheck(k) for k in p['favorites'] if isinstance(k,str)][:100]
  core.atomic(core.CONFIG/'studio-ui.json',before);return before
 if method=='save_profile':
  core.save_profile(keycheck(p['key']),p['profile']);return bootstrap()
 if method=='duplicate':
  key=keycheck(p['key']);name=str(p.get('name','')).strip()[:90]
  if not name:raise ValueError('Give the new preset a name.')
  profiles=core.read(core.FILES['profiles']);item=copy.deepcopy(profiles[key]);item.setdefault('theme',copy.deepcopy(core.read(core.CONFIG/'main.json')['theme']));item['label']=name;new='custom-'+core.uuid.uuid4().hex[:8];core.checkpoint('Before duplicating '+key);profiles[new]=item;core.atomic(core.FILES['profiles'],profiles);result=bootstrap();result['selected']=new;return result
 if method=='save_widgets':
  core.save_widgets(keycheck(p['key']),p['items']);subprocess.run(['quickshell','-n','-d','-p',str(core.APP/'widgets.qml')],capture_output=True,check=True,timeout=10);return bootstrap()
 if method=='preview':core.start_preview(keycheck(p['key']));return {'pending':core.read(core.STATE/'pending.json'),'current':current()}
 if method in ('keep','revert'):core.finish_preview(method=='keep');return bootstrap()
 if method=='checkpoint':core.checkpoint(str(p.get('label','Manual checkpoint'))[:100],True);return {'history':history()}
 if method=='restore':
  ident=p.get('id','')
  if not core.re.fullmatch(r'[0-9]{8}-[0-9]{6}-[a-f0-9]{6}',ident):raise ValueError('Invalid checkpoint')
  path=core.STATE/'history'/(ident+'.json')
  if not path.is_file():raise ValueError('Checkpoint not found')
  core.restore(path);return bootstrap()
 if method=='rescue':
  core.control().apply_desktop('main');return bootstrap()
 if method=='open_config':
  profile=core.read(core.FILES['profiles'])[keycheck(p['key'])];kind=p['kind']
  if kind in core.FILES:path=core.FILES[kind]
  elif kind=='terminal':path=core.CONFIG/'terminals'/(profile['terminal']+'.conf')
  elif kind in ('bar','css'):
   bar=profile['bar']
   if bar not in core.control().registry() or bar in ('main','studio','serashell'):
    raise ValueError('This preset does not use a bundled Waybar file.')
   path=core.APP/'themes/bars'/bar/('style.css' if kind=='css' else 'config.jsonc')
  else:raise ValueError('Unknown config file')
  if not path.is_file():raise ValueError('This file does not exist yet.')
  subprocess.Popen(['xdg-open',str(path)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True);return {'ok':True}
 raise ValueError('Unsupported operation')
def execute(request):
 ident=request.get('id')
 try:
  # Existing rice helpers print human-readable messages. Keep the pipe JSON-only.
  with contextlib.redirect_stdout(io.StringIO()):result=handle(request['method'],request.get('params',{}))
  send({'id':ident,'ok':True,'result':result})
 except Exception as exc:send({'id':ident,'ok':False,'error':str(exc)})
def main():
 send({'event':'ready'})
 with concurrent.futures.ThreadPoolExecutor(max_workers=1) as pool:
  for line in sys.stdin:
   if len(line)>2_000_000:send({'ok':False,'error':'Request too large'});continue
   try:
    request=json.loads(line)
    if not isinstance(request,dict):raise ValueError('Invalid request')
    pool.submit(execute,request)
   except ValueError:send({'ok':False,'error':'Invalid JSON request'})
if __name__=='__main__':main()
