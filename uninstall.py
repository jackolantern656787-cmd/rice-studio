#!/usr/bin/env python3
"""Restore Main first, then remove only unchanged files installed by this project."""
from pathlib import Path
import argparse,json,hashlib,subprocess,sys,os

def uninstall(home,restore=True):
 home=Path(home).resolve();state=home/'.local/state/rice-studio-portable';app=home/'.local/share/rice-studio-portable';manifest=state/'installation.json'
 if not manifest.exists():raise RuntimeError('No portable installation found.')
 if restore:
  sys.path.insert(0,str(app));import core
  core.finish_preview(False)
  adapter=core.control()
  adapter.apply_desktop('main')
  from window_mode import restore as restore_window_mode
  restore_window_mode(adapter)
  from launcher import stop
  from main_pc import apply as apply_main_pc
  stop(app)
  apply_main_pc(False)
  if (state/'serpantinum-bar-hook.json').exists():
   from serpantinum_hook import restore_hook
   restore_hook()
  for config in (app/'qt/shell.qml',app/'desktop.qml',app/'widgets.qml'):
   subprocess.run(['quickshell','-p',str(config),'kill'],capture_output=True,timeout=10)
 sys.path.insert(0,str(app))
 from kitty_integration import uninstall as remove_kitty_include
 remove_kitty_include(home)
 data=json.loads(manifest.read_text());kept=[]
 for name,digest in data['files'].items():
  path=home/name
  if path.is_symlink():kept.append(name);continue
  if not path.resolve().is_relative_to(home):raise ValueError('Invalid manifest path')
  if path.is_file():
   if hashlib.sha256(path.read_bytes()).hexdigest()==digest:path.unlink()
   else:kept.append(name)
 # Baseline, captures, checkpoint history and modified user files deliberately remain.
 manifest.unlink();print('Removed unchanged installed files. Kept modified files:',len(kept));print('Recovery data and captures retained:',state)
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--uninstall',action='store_true',required=True);p.parse_args()
 if os.geteuid()==0:raise SystemExit('Run without sudo.')
 try:uninstall(Path.home())
 except Exception as exc:raise SystemExit('Uninstall stopped without discarding recovery data: '+str(exc))
