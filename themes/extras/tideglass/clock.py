#!/usr/bin/env python3
"""Small pixel clock rendered in a real terminal, with no desktop overlay."""
import datetime,shutil,signal,sys,time
FONT=['111101101101111','010110010010111','111001111100111','111001111001111','101101111001001','111100111001111','111100111101111','111001001001001','111101111101111','111101111001111']
def main():
 def stop(*_):raise KeyboardInterrupt
 signal.signal(signal.SIGTERM,stop)
 sys.stdout.write('\033[?1049h\033[?25l')
 try:
  while True:
   now=datetime.datetime.now();columns,rows=shutil.get_terminal_size();text=now.strftime('%H:%M');lines=[]
   for y in range(5):
    line=''
    for ch in text:
     bits=('010000010000000' if ch==':' else FONT[int(ch)])
     line+=''.join('██' if b=='1' else '  ' for b in bits[y*3:y*3+3])+'  '
    lines.append(line.rstrip())
   lines+=['',now.strftime('%Y-%m-%d').center(38)]
   out='\033[H\033[2J\033[38;2;190;187;240m'+'\n'*max(0,(rows-len(lines))//2)
   out+='\n'.join(' '*max(0,(columns-38)//2)+line for line in lines)
   sys.stdout.write(out);sys.stdout.flush();time.sleep(.5)
 except KeyboardInterrupt:pass
 finally:sys.stdout.write('\033[0m\033[?25h\033[?1049l');sys.stdout.flush()
if __name__=='__main__':main()
