#!/usr/bin/env python3
"""Silent, transparent, block-cell playback of the local Bad Apple video."""
from pathlib import Path
import os,shutil,signal,subprocess,sys,time
from PIL import Image

def main():
 child=None
 def stop(*_):raise KeyboardInterrupt
 signal.signal(signal.SIGTERM,stop);signal.signal(signal.SIGHUP,stop)
 try:
  child=subprocess.Popen(['ffmpeg','-loglevel','error','-stream_loop','-1','-i',str(Path(__file__).with_name('assets')/'bad-apple.mp4'),'-an','-vf','fps=15,scale=96:72','-pix_fmt','gray','-f','rawvideo','-'],stdout=subprocess.PIPE,stderr=subprocess.DEVNULL)
  sys.stdout.write('\033[?1049h\033[?25l\033[2J');sys.stdout.flush();start=time.monotonic();frame=0
  while True:
   raw=child.stdout.read(96*72)
   if len(raw)!=96*72:break
   cols,rows=shutil.get_terminal_size();w=min(96,max(2,cols-2));height=min(max(2,(rows-2)*2),round(w*.75));w=min(w,round(height/.75));height-=height%2
   im=Image.frombytes('L',(96,72),raw).resize((w,height),Image.Resampling.NEAREST);px=im.load();out=['\033[H\033[38;2;205;231;228m']
   ox=max(0,(cols-w)//2);oy=max(0,(rows-height//2)//2)
   for y in range(rows-1):
    out.append(' '*ox)
    for x in range(w):
     yy=(y-oy)*2
     a=0<=yy<height and px[x,yy]>100;b=0<=yy+1<height and px[x,yy+1]>100
     out.append((' ','▀','▄','█')[int(a)+int(b)*2])
    out.append('\033[K\r\n')
   out.append('\033[0m\033[K');sys.stdout.write(''.join(out));sys.stdout.flush();frame+=1
   delay=start+frame/15-time.monotonic()
   if delay>0:time.sleep(delay)
 except KeyboardInterrupt:pass
 finally:
  if child is not None:
   child.terminate()
   try:child.wait(timeout=2)
   except subprocess.TimeoutExpired:child.kill();child.wait()
  sys.stdout.write('\033[0m\033[?25h\033[?1049l');sys.stdout.flush()
if __name__=='__main__':main()
