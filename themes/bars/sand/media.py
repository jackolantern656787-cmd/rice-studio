#!/usr/bin/env python3
import json,subprocess

def get(*args):
 try:return subprocess.check_output(['playerctl',*args],stderr=subprocess.DEVNULL,text=True,timeout=2).strip()
 except (OSError,subprocess.SubprocessError):return ''
def stamp(seconds):
 seconds=max(0,int(seconds));return f'{seconds//60:02}:{seconds%60:02}'
import sys
if sys.argv[1]=='title':
 title=get('metadata','title');artist=get('metadata','artist')
 print(json.dumps({'text':' '+(title[:15] if title else 'No media'),'tooltip':f'{artist}\n{title}'if title else'No active media player'}))
else:
 try:position=float(get('position')or 0);length=float(get('metadata','mpris:length')or 0)/1e6
 except ValueError:position=length=0
 icon=''if get('status')=='Playing'else'▶'
 print(json.dumps({'text':f'{icon} {stamp(position)}/{stamp(length)}','tooltip':'Click: play/pause • right-click: next • middle-click: previous'}))
