#!/usr/bin/env python3
from pathlib import Path
for n in Path('/sys/class/hwmon').glob('hwmon*/name'):
 try:
  if n.read_text().strip()!='k10temp':continue
  for f in sorted(n.parent.glob('temp*_input')):
   label=f.with_name(f.name.replace('_input','_label'))
   if not label.exists() or label.read_text().strip() in ('Tctl','Tdie'):print(f.read_text().strip());raise SystemExit
 except OSError:pass
print(0)
