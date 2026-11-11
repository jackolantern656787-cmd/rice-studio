#!/usr/bin/env python3
"""Local wallpaper catalog and a checkpointed selection, no downloads."""
from pathlib import Path
import json,sys,hashlib,os,subprocess
from PIL import Image
H=Path.home();CONFIG=H/'.config/rice-studio-portable/profiles.json'
def catalog():
 roots=[H/'Pictures/Wallpapers',H/'.local/share/rice-studio-portable/themes'];files=[]
 for root in roots:
  if not root.exists():continue
  for p in sorted(root.rglob('*')):
   if len(files)>=600:break
   if p.is_symlink() or not p.is_file() or p.suffix.lower() not in ('.png','.jpg','.jpeg','.webp'):continue
   if root.name=='themes' and 'wallpapers' not in p.parts and not p.name.startswith('wallpaper'):continue
   files.append(p)
 # Deduplicate by resolved filename; preserve originals.
 rows=[];seen=set();cache=H/'.cache/rice-studio-portable/tideglass-wallpapers'
 for p in files:
  if str(p.resolve()) in seen:continue
  seen.add(str(p.resolve()))
  try:
   cache.mkdir(parents=True,exist_ok=True)
   thumb=cache/(hashlib.sha256((str(p)+str(p.stat().st_mtime_ns)).encode()).hexdigest()[:24]+'.png')
   if not thumb.exists():
    with Image.open(p) as im:
     im=im.convert('RGB');im.thumbnail((320,180));im.save(thumb)
   rows.append({'name':p.stem,'path':str(p),'preview':thumb.as_uri()})
  except (OSError,ValueError):pass
 return rows

def apply(path):
 if (H/'.local/state/rice-studio-portable/current').read_text().strip()!='tideglass':raise ValueError('Select Tideglass before changing its wallpaper.')
 rows=catalog()
 if path not in {r['path'] for r in rows}:raise ValueError('Select an image from the local wallpaper catalog.')
 sys.path.insert(0,str(H/'.local/share/rice-studio-portable'));import core
 data=core.read(CONFIG)
 core.checkpoint('Before changing Tideglass wallpaper')
 data['tideglass']['wallpaper']=path
 core.atomic(CONFIG,data)
 return {'ok':True,'path':path}
if __name__=='__main__':
 try:print(json.dumps(apply(sys.argv[2]) if len(sys.argv)>2 and sys.argv[1]=='apply' else {'rows':catalog()}))
 except Exception as e:print(json.dumps({'error':str(e)}));sys.exit(1)
