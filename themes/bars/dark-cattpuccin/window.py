#!/usr/bin/env python3
import json,subprocess
try:
 c=json.loads(subprocess.check_output(['hyprctl','activewindow','-j'],text=True,timeout=2));print(json.dumps({'text':c.get('class','Hyprland'),'tooltip':c.get('title','')}))
except Exception:print(json.dumps({'text':'Hyprland'}))
