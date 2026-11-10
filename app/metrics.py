#!/usr/bin/env python3
import json,subprocess
from pathlib import Path
m={row.split(':')[0]:int(row.split()[1]) for row in Path('/proc/meminfo').read_text().splitlines()}
c=list(map(int,Path('/proc/stat').read_text().splitlines()[0].split()[1:9]));used=m['MemTotal']-m['MemAvailable']
try:
 p=subprocess.run(['playerctl','metadata','--format','{{artist}} — {{title}}'],capture_output=True,text=True,timeout=2);music=p.stdout.strip() if p.returncode==0 else ''
except (OSError,subprocess.TimeoutExpired):music=''
print(json.dumps(dict(total=sum(c),idle=c[3]+c[4],ram=used/m['MemTotal']*100,detail=f'{used/1048576:.1f} / {m["MemTotal"]/1048576:.1f} GiB',music=music)))
