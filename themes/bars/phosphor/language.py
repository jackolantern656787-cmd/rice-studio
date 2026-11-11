#!/usr/bin/env python3
import json,subprocess
try:
 data=json.loads(subprocess.check_output(['hyprctl','devices','-j'],text=True,timeout=2));keys=data.get('keyboards',[]);keyboard=next((k for k in keys if k.get('main')),keys[0]if keys else{});layout=keyboard.get('active_keymap','English (US)');print(json.dumps({'text':layout,'tooltip':'Keyboard layout • click: settings'}))
except (OSError,ValueError,subprocess.SubprocessError):print(json.dumps({'text':'keyboard —'}))
