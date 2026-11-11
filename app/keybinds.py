"""Opt-in main-PC shortcut overlay for native Hyprland Lua configs."""
import argparse
import json
import subprocess
from pathlib import Path

from kitty_integration import atomic_text


def apply(install):
    home = Path.home()
    root = home / '.local/share/rice-studio-portable'
    path = home / '.config/hypr/hyprland.lua'
    if not path.is_file():
        if install:
            raise ValueError('The main-PC shortcut pack requires a native Hyprland Lua config.')
        return
    path = path.resolve()
    if not path.is_relative_to(home):
        raise ValueError('The Hyprland config points outside your home.')
    text = path.read_text()
    source = json.dumps(str(root / 'integrations/main-pc-keybinds.lua'))
    block = f'\n-- Rice Studio main PC shortcuts\ndofile({source})\n-- End Rice Studio main PC shortcuts\n'
    if install:
        result = text if block in text else text + block
    else:
        result = text.replace(block, '', 1)
    if result == text:
        return
    atomic_text(path, result)
    try:
        subprocess.run(['hyprctl', 'reload'], check=True, capture_output=True, text=True, timeout=10)
        errors = subprocess.check_output(['hyprctl', 'configerrors'], text=True, timeout=10)
        if errors.strip():
            raise RuntimeError(errors.strip())
    except Exception:
        atomic_text(path, text)
        subprocess.run(['hyprctl', 'reload'], capture_output=True, timeout=10)
        raise


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--install', action='store_true')
    modes.add_argument('--restore', action='store_true')
    try:
        apply(parser.parse_args().install)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error))
