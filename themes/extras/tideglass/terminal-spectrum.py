#!/usr/bin/env python3
"""Real Cava audio drawn as solid bars inside a terminal."""
import json,os,shutil,signal,subprocess,sys
from pathlib import Path

def render(values,columns,rows):
 # Use full-cell blocks and eighth-cell caps, like Cava's terminal output.
 count=max(1,min(len(values),(columns-1)//3));levels=max(1,rows-1)
 bands=[max(values[i*len(values)//count:max(i*len(values)//count+1,(i+1)*len(values)//count)]) for i in range(count)]
 colors=[(166,164,220),(185,176,225),(214,193,233),(235,190,212),(216,111,154)]
 caps=' ▁▂▃▄▅▆▇█'
 out=['\033[H']
 for row in range(levels):
  level=levels-1-row
  color=colors[min(4,max(0,int(level/max(1,levels)*5)))]
  out.append('\033[38;2;%d;%d;%dm'%color)
  for i,v in enumerate(bands):
   pitch=max(1,(i+1)*(columns-1)//count-i*(columns-1)//count)
   fill=max(0,min(8,round((v/20*levels-level)*8)))
   out.append(caps[fill]*max(1,pitch-1)+' ')
  out.append('\033[K\r\n')
 out.append('\033[0m\033[K')
 return ''.join(out)
def main():
 if not sys.stdout.isatty():raise SystemExit('Run this visualizer inside a terminal.')
 child=None
 def stop(*_):raise KeyboardInterrupt
 signal.signal(signal.SIGTERM,stop)
 try:
  child=subprocess.Popen([sys.executable,str(Path(__file__).with_name('spectrum.py'))],stdout=subprocess.PIPE,text=True)
  sys.stdout.write('\033[?1049h\033[?25l\033[2J');sys.stdout.flush()
  for line in child.stdout:
   try:values=json.loads(line)
   except ValueError:continue
   if not values:continue
   cols,rows=shutil.get_terminal_size();sys.stdout.write(render(values,cols,rows));sys.stdout.flush()
 except KeyboardInterrupt:pass
 finally:
  if child is not None:
   child.terminate()
   try:child.wait(timeout=2)
   except subprocess.TimeoutExpired:child.kill();child.wait()
  sys.stdout.write('\033[0m\033[?25h\033[?1049l');sys.stdout.flush()
if __name__=='__main__':main()
