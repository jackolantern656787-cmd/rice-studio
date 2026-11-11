#!/usr/bin/env python3
import platform,json,subprocess,os,getpass
from pathlib import Path
cpu=next((s.split(':',1)[1].strip() for s in Path('/proc/cpuinfo').read_text().splitlines() if s.startswith('model name')),'Unknown')
board=Path('/sys/class/dmi/id/board_name').read_text().strip()
uptime=int(float(Path('/proc/uptime').read_text().split()[0]));uptime=f'{uptime//3600}h {(uptime//60)%60}m'
try:
 p=subprocess.run(['nvidia-smi','--query-gpu=name,driver_version','--format=csv,noheader'],capture_output=True,text=True,timeout=3);gpu,driver=[s.strip() for s in p.stdout.strip().split(',',1)]
except Exception:gpu='Graphics unavailable';driver='—'
print(json.dumps({'user':getpass.getuser(),'os':'Arch Linux x86_64','kernel':platform.release(),'cpu':cpu.replace('AMD ','').replace('Intel(R) ','').replace(' Processor',''),'board':board,'gpu':gpu,'driver':driver,'uptime':uptime,'shell':Path(os.environ.get('SHELL','bash')).name}))
