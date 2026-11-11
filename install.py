#!/usr/bin/env python3
"""User-local, opt-in installer. No sudo, downloads, shell changes or dotfile replacement."""
from pathlib import Path
import argparse,datetime,hashlib,importlib.util,json,os,shutil,sys,tempfile
ROOT=Path(__file__).resolve().parent
REQUIRED=('hyprctl','quickshell','kitty','ffmpeg','grim','wf-recorder','xdg-open','waybar')
def load(path,name):
 spec=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m

def install(home,check=False,check_deps=True):
 home=Path(home).resolve();app=home/'.local/share/rice-studio-portable';config=home/'.config/rice-studio-portable';state=home/'.local/state/rice-studio-portable';manifest=state/'installation.json'
 missing=[name for name in REQUIRED if shutil.which(name) is None]
 try:import PIL
 except ImportError:missing.append('python-pillow')
 if check_deps and missing:raise RuntimeError('Missing dependencies: '+', '.join(missing)+'. See ./install.sh --deps.')
 owned=json.loads(manifest.read_text()) if manifest.exists() else {'files':{}}
 destinations=[home/'.local/bin'/p.name for p in (ROOT/'bin').iterdir() if p.is_file()]
 desktop=home/'.local/share/applications/rice-studio.desktop';destinations.append(desktop)
 for dest in destinations:
  if dest.exists() and str(dest.relative_to(home)) not in owned['files']:raise RuntimeError('Existing file preserved: '+str(dest)+'. Use a separate account for the portable edition.')
 if app.exists() and not manifest.exists():raise RuntimeError('Unrecognized app directory preserved: '+str(app))
 if config.exists() and not manifest.exists():raise RuntimeError('Unrecognized preset directory preserved: '+str(config))
 if check:
  print('Preflight passed. No files changed. Install will capture personal Main before applying any theme.');return
 # Snapshot read-only compositor values before creating/installing any desktop components.
 old=os.environ.get('RICE_STUDIO_HOME');os.environ['RICE_STUDIO_HOME']=str(home)
 try:control=load(ROOT/'app/control.py','install_control');control.ensure_main()
 finally:
  if old is None:os.environ.pop('RICE_STUDIO_HOME',None)
  else:os.environ['RICE_STUDIO_HOME']=old
 state.mkdir(parents=True,exist_ok=True,mode=0o700)
 stage=Path(tempfile.mkdtemp(prefix='stage-',dir=state));written=[];prior={};kitty_previous=None
 try:
  shutil.copytree(ROOT/'app',stage/'app',ignore=shutil.ignore_patterns('__pycache__','*.pyc'))
  p=load(ROOT/'presets.py','install_presets');profiles=p.create(stage/'config')
  for item in profiles.values():item['wallpaper']=str(config/'wallpapers'/Path(item['wallpaper']).name)
  previous_defaults=json.loads(json.dumps(profiles))
  pack=load(ROOT/'theme_pack.py','install_theme_pack')
  pack.prepare(stage,app,config,state,profiles)
  previous_profiles=config/'profiles.json'
  if previous_profiles.exists():
   for key, item in json.loads(previous_profiles.read_text()).items():
    if item != previous_defaults.get(key):
     profiles[key]=item
  generated={'profiles.json':profiles,'widgets.json':{},'main.json':{'theme':profiles['main']['theme']}}
  for name,value in generated.items():(stage/'config'/name).write_text(json.dumps(value,indent=2)+'\n')
  shutil.copytree(ROOT/'app/integrations/lock',stage/'config/lock-layouts')
  for source in (stage/'app').rglob('*'):
   if source.is_file():written.append((source,app/source.relative_to(stage/'app')))
  for source in (stage/'config').rglob('*'):
   if source.is_file():
    dest=config/source.relative_to(stage/'config')
    relative=str(dest.relative_to(home))
    unchanged=dest.is_file() and owned['files'].get(relative)==hashlib.sha256(dest.read_bytes()).hexdigest()
    if not dest.exists() or (dest.name=='profiles.json' and relative in owned['files']) or (unchanged and dest.parent==config/'terminals'):
     written.append((source,dest))
  for source in (ROOT/'bin').iterdir():
   if source.is_file():written.append((source,home/'.local/bin'/source.name))
  entry=stage/'rice-studio.desktop';entry.write_text('[Desktop Entry]\nType=Application\nName=Rice Studio\nComment=Local desktop workshop for Hyprland\nExec="'+str(home/'.local/bin/rice-studio')+'"\nIcon=preferences-desktop-theme\nTerminal=false\nCategories=Settings;DesktopSettings;\n')
  written.append((entry,desktop))
  # Preserve the entire previous managed app on upgrades. Never back up arbitrary home files.
  backup=state/'install-backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
  for source,dest in written:
   if dest.exists():
    prev=backup/dest.relative_to(home);prev.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,prev);prior[dest]=prev
   else:prior[dest]=None
   dest.parent.mkdir(parents=True,exist_ok=True)
   fd,temp=tempfile.mkstemp(dir=dest.parent)
   try:
    with os.fdopen(fd,'wb') as out,source.open('rb') as src:shutil.copyfileobj(src,out)
    os.chmod(temp,0o700 if source.stat().st_mode & 0o111 else 0o600);os.replace(temp,dest)
   finally:
    if os.path.exists(temp):os.unlink(temp)
  files=dict(owned['files'])
  for _,dest in written:
   relative=str(dest.relative_to(home))
   previous=prior[dest]
   if dest.name=='profiles.json' and previous and files.get(relative)!=hashlib.sha256(previous.read_bytes()).hexdigest():
    continue
   files[relative]=hashlib.sha256(dest.read_bytes()).hexdigest()
  current=state/'current'
  if not current.exists():current.write_text('main\n')
  if not (state/'bar-override.json').exists():control.atomic(state/'bar-override.json',{})
  kitty=load(ROOT/'app/kitty_integration.py','install_kitty')
  kitty_path=kitty.kitty_config(home)
  kitty_previous=(kitty_path,kitty_path.read_text() if kitty_path.exists() else None)
  kitty.sync(current.read_text().strip(),profiles,config,state,app)
  kitty.install(home)
  control.atomic(manifest,{'schema':1,'version':'0.3.2-beta.1','files':files})
 except Exception:
  if kitty_previous:
   path,previous=kitty_previous
   if previous is None:path.unlink(missing_ok=True)
   else:kitty.atomic_text(path,previous)
  for dest,prev in reversed(list(prior.items())):
   if prev is None:dest.unlink(missing_ok=True)
   else:shutil.copy2(prev,dest)
  raise
 finally:shutil.rmtree(stage)
 print('Installed Rice Studio. Your original desktop remains active. Open ~/.local/bin/rice-studio.')
 print('Personal Main:',state/'original-main.json')

def main():
 parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True);group.add_argument('--check',action='store_true');group.add_argument('--install',action='store_true');args=parser.parse_args()
 if os.geteuid()==0:raise SystemExit('Run as your desktop user, without sudo.')
 try:install(Path.home(),args.check)
 except Exception as exc:raise SystemExit(str(exc))
if __name__=='__main__':main()
