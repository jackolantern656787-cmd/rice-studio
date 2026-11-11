#!/usr/bin/env python3
"""Stream real local Cava audio frames; terminate the child with the panel."""
from pathlib import Path
import subprocess,json,signal,sys
child=None
def stop(*_):
 if child is not None:child.terminate()
 raise SystemExit(0)
signal.signal(signal.SIGTERM,stop);signal.signal(signal.SIGINT,stop)
try:
 child=subprocess.Popen(['cava','-p',str(Path(__file__).with_name('spectrum.conf'))],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL,text=True)
 for line in child.stdout:
  try:values=[max(0,min(20,int(v))) for v in line.strip().split(';') if v]
  except ValueError:continue
  if values:print(json.dumps(values),flush=True)
finally:
 if child is not None and child.poll() is None:child.terminate();child.wait()
