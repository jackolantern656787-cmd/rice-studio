"""Open the original preset dashboard using local paths and hardware."""
import json
import os
import subprocess
import sys
from pathlib import Path

import control
from kitty_integration import atomic_text


def phosphor(app):
    files = app / 'integrations/phosphor'
    session = control.STATE / 'phosphor.session'
    monitor = app / 'commands/phosphor-monitor'
    atomic_text(session, (files / 'dashboard.session').read_text().replace('@PHOSPHOR_MONITOR@', str(monitor)))
    clients = json.loads(control.run(['hyprctl', 'clients', '-j']))
    used = {client.get('workspace', {}).get('id') for client in clients}
    workspace = next(number for number in range(6, 100) if number not in used)
    control.run(['hyprctl', 'eval', f'hl.dispatch(hl.dsp.workspace({workspace}))'])
    subprocess.Popen(['kitty','--config',str(control.CONFIG/'terminals/phosphor.conf'),
                      '--class','phosphor-terminal','--session',str(session)], start_new_session=True)
    subprocess.Popen(['pavucontrol','--tab=1'], env=dict(os.environ,GTK_THEME='Phosphor'), start_new_session=True)


if __name__ == '__main__':
    current = (control.STATE / 'current').read_text().strip()
    profiles = control.read(control.CONFIG / 'profiles.json')
    preset = sys.argv[1] if len(sys.argv)>1 else profiles.get(current,{}).get('rice',current)
    if preset not in {'phosphor','tideglass','cyanframe','serashell'}:
        raise SystemExit('Choose Phosphor, Tideglass, Cyanframe or Serashell.')
    if preset != profiles.get(current,{}).get('rice',current):
        control.apply_desktop(preset)
    if preset == 'phosphor':
        phosphor(control.APP)
    else:
        source = control.APP / 'themes/extras' / preset / 'dashboard.py'
        os.execv(sys.executable,[sys.executable,str(source),*sys.argv[2:]])
