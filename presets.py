"""Original portable palette studies. No third-party wallpapers or user dotfiles."""
from pathlib import Path
import json,math
PALETTES=[('monochrome','Monochrome','#101010','#dddddd'),('catppuccin','Catppuccin','#1e1e2e','#cba6f7'),('beige','Beige','#242321','#e5c890'),('phosphor','Phosphor','#070c0a','#a9b3aa'),('pixel','Pixel','#0d0c0c','#deded9'),('dark-grey','Dark Grey','#111111','#eeeeee'),('dark-cattpuccin','Dark Cattpuccin','#191925','#9399b2'),('fuji-dusk','Fuji Dusk','#1a2037','#9baedb'),('stillwater','Stillwater','#181e1c','#8c9b7b'),('cold-front','Cold Front','#263743','#64b6ee'),('honeyveil','Honeyveil','#1e1e2e','#f9e2af'),('teigu','Teigu','#151617','#969196'),('tideglass','Tideglass','#272e3f','#bca6da'),('cyanframe','Cyanframe','#172c32','#79c9d4'),('viegphunt','ViegPhunt','#1e1e2e','#f5c2e7'),('serashell','Serashell','#352b2d','#f1dbc2')]
def create(config):
 from PIL import Image,ImageDraw
 config=Path(config);walls=config/'wallpapers';walls.mkdir(parents=True,exist_ok=True);terms=config/'terminals';terms.mkdir(exist_ok=True)
 profiles={}
 for i,(key,title,base,accent) in enumerate([('main','Main','#17191d','#d6ab7d')]+PALETTES):
  wall=walls/(key+'.png')
  if not wall.exists():
   im=Image.new('RGB',(1600,900),base);d=ImageDraw.Draw(im)
   rgb=tuple(int(accent[j:j+2],16) for j in (1,3,5));dark=tuple(int(base[j:j+2],16) for j in (1,3,5));line=tuple(int(a*.22+b*.78) for a,b in zip(rgb,dark))
   for n in range(12):
    points=[(x,int(430+100*math.sin(x/340+n*.13+i*.18)+n*24)) for x in range(0,1601,8)];d.line(points,fill=line,width=2)
   for x in range(40,1600,48):
    for y in range(40,900,48):d.point((x,y),fill=line)
   d.ellipse((1110,180,1290,360),outline=accent,width=2);im.save(wall)
  colors={'base':base,'mantle':base,'crust':base,'text':'#eee7dc','surface0':'#303137','surface1':'#454650','blue':accent,'mauve':accent}
  profiles[key]={'label':title+' · '+('your original desktop' if key=='main' else 'portable palette study'),'terminal':key,'bar':'main' if key=='main' else 'studio','wallpaper':str(wall),'launcher_theme':'original','theme':{'name':title,'fontFamily':'JetBrains Mono','borderRadius':0 if key in ('pixel','phosphor','dark-grey') else 10,'colors':colors}}
  terminal=terms/(key+'.conf')
  if not terminal.exists():terminal.write_text('font_family JetBrains Mono\nfont_size 12\nbackground '+base+'\nforeground #eee7dc\ncursor '+accent+'\nselection_background '+accent+'\nselection_foreground '+base+'\n')
 return profiles
