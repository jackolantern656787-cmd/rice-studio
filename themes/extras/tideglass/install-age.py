from pathlib import Path
from datetime import datetime,timezone
import re
try:
 with Path('/var/log/pacman.log').open() as f:
  for line in f:
   if ' installed filesystem ' in line:
    stamp=re.match(r'\[([^]]+)\]',line)[1]
    start=datetime.fromisoformat(stamp)
    print(str(max(0,(datetime.now(timezone.utc)-start).days))+' days (first filesystem install in pacman log)')
    break
  else:print('Unavailable: install record not retained')
except (OSError,ValueError):print('Unavailable')
