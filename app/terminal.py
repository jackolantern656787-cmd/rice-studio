from pathlib import Path
import json
import os
import shutil
import sys
import re

home = Path.home()
config = home / '.config/rice-studio-portable'
state = home / '.local/state/rice-studio-portable/current'
key = state.read_text().strip() if state.exists() else 'main'
profile = json.loads((config / 'profiles.json').read_text()).get(key, {})
terminal = sys.argv[1] if len(sys.argv)>1 else profile.get('terminal','main')
if terminal == '--list':
    print('main')
    print('\n'.join(path.stem for path in sorted((config / 'terminals').glob('*.conf')) if path.stem!='main'))
    raise SystemExit
if terminal == 'main':
    os.execvp('kitty', ['kitty'])
folder = config / 'terminals'
if not re.fullmatch(r'[a-z0-9-]+',terminal) or not (folder / (terminal + '.conf')).is_file():
    raise SystemExit('Unknown terminal profile. Use rice-studio-terminal --list.')
args = ['kitty', '--config', str(folder / (terminal + '.conf'))]
fetch = folder / (terminal + '-fastfetch.jsonc')
starship = folder / (terminal + '-starship.toml')
if fetch.is_file() and shutil.which('fastfetch'):
    args += ['bash', '-c', 'fastfetch --config "$1"; exec "${SHELL:-/bin/bash}" -i', 'studio', str(fetch)]
if starship.is_file():
    os.environ['STARSHIP_CONFIG'] = str(starship)
os.execvp('kitty', args)
