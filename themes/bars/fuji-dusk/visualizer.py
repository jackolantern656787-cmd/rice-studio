#!/usr/bin/env python3
"""Translate local Cava raw frames into a Waybar text stream."""
import json,signal,subprocess
from pathlib import Path
child=None
def stop(*_):
 if child is not None:child.terminate()
 raise SystemExit(0)
signal.signal(signal.SIGTERM,stop);signal.signal(signal.SIGINT,stop)
try:
 child=subprocess.Popen(['cava','-p',str(Path(__file__).with_name('cava.conf'))],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True)
 for line in child.stdout:
  try:values=[max(0,min(4,int(v))) for v in line.strip().split(';') if v]
  except ValueError:continue
  print(json.dumps({'text':''.join(' ▁▃▅█'[v]for v in values)if any(values)else'','tooltip':'Audio visualizer'}),flush=True)
finally:
 if child is not None and child.poll()is None:child.terminate();child.wait()
