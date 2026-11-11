#!/usr/bin/env python3
import json,subprocess
try:
 p=subprocess.run(['nvidia-smi','--query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total','--format=csv,noheader,nounits'],capture_output=True,text=True,timeout=3,check=True)
 name,usage,temp,used,total=[x.strip() for x in p.stdout.splitlines()[0].split(',')]
 print(json.dumps({'text':f'{usage}% {temp}°C','class':'critical' if float(usage)>=95 else 'normal','tooltip':f'{name}\nTemperature: {temp}°C\nVRAM: {used}/{total} MiB'}))
except (OSError,ValueError,IndexError,subprocess.SubprocessError):print(json.dumps({'text':' N/A','class':'unavailable','tooltip':'NVIDIA telemetry unavailable'}))
