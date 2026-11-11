#!/usr/bin/env python3
import json,subprocess,sys
n=int(sys.argv[1]);active=0;occupied=False
try:
 active=json.loads(subprocess.check_output(['hyprctl','activeworkspace','-j'],text=True,timeout=2))['id']
 occupied=any(w['id']==n and w.get('windows',0)>0 for w in json.loads(subprocess.check_output(['hyprctl','workspaces','-j'],text=True,timeout=2)))
except Exception:pass
print(json.dumps({'text':'󰮯' if n==active else ('󰊠' if occupied else '●'),'class':'active' if n==active else ('occupied' if occupied else 'empty'),'tooltip':'Workspace '+str(n)}))
