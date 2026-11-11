#!/usr/bin/env python3
"""Display Serpantinum's existing weather cache without any network request."""
import json,time
from pathlib import Path
try:
 p=Path.home()/'.cache/serpantinum/weather/weather.json';data=json.loads(p.read_text())
 temperature=str(data.get('current_temp_formatted',data.get('current_temp','—')))
 if not any(c in temperature for c in ('°','C','F')):temperature+='°'+str(data.get('unit_sym','C'))
 icon=str(data.get('current_icon','󰖐'))
 stale=time.time()-p.stat().st_mtime>3600
 print(json.dumps({'text':icon+' '+temperature,'tooltip':'Desktop weather • click to open calendar'+('\nLast available reading'if stale else''),'class':'stale'if stale else'normal'}))
except (OSError,ValueError,TypeError):print(json.dumps({'text':'󰖐 —°C','tooltip':'Desktop weather cache unavailable','class':'unavailable'}))
