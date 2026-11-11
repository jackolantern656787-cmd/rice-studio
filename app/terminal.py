from pathlib import Path
import json
import os
import shutil

home = Path.home()
config = home / '.config/rice-studio-portable'
state = home / '.local/state/rice-studio-portable/current'
key = state.read_text().strip() if state.exists() else 'main'
profile = json.loads((config / 'profiles.json').read_text()).get(key, {})
terminal = profile.get('terminal', 'main')
if key == 'main' or terminal == 'main':
    os.execvp('kitty', ['kitty'])
folder = config / 'terminals'
args = ['kitty', '--config', str(folder / (terminal + '.conf'))]
fetch = folder / (terminal + '-fastfetch.jsonc')
starship = folder / (terminal + '-starship.toml')
if fetch.is_file() and shutil.which('fastfetch'):
    args += ['bash', '-c', 'fastfetch --config "$1"; exec "${SHELL:-/bin/bash}" -i', 'studio', str(fetch)]
if starship.is_file():
    os.environ['STARSHIP_CONFIG'] = str(starship)
os.execvp('kitty', args)
