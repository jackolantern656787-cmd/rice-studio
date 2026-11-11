#!/usr/bin/env python3
from pathlib import Path
m={x.split(':')[0]:int(x.split()[1]) for x in Path('/proc/meminfo').read_text().splitlines()}
print(str(round((m['MemTotal']-m['MemAvailable'])/1024))+' MiB')
