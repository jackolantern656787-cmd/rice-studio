#!/usr/bin/env python3
"""Local launcher data. Never scans file contents or runs a search string."""
import json,subprocess,sys
from pathlib import Path
mode=sys.argv[1] if len(sys.argv)>1 else 'windows'
if mode=='windows':
 try:
  rows=json.loads(subprocess.check_output(['hyprctl','clients','-j'],text=True,timeout=3))
  rows=[{'name':r.get('title') or r.get('class'),'detail':r.get('class',''),'value':r['address']} for r in rows if r.get('mapped')]
 except Exception:rows=[]
else:
 rows=[{'name':p.name,'detail':'Folder' if p.is_dir() else 'File','value':str(p)} for p in sorted(Path.home().iterdir(),key=lambda p:(not p.is_dir(),p.name.lower())) if not p.name.startswith('.')]
print(json.dumps(rows))
