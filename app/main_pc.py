"""Install or restore the optional companion configs from the main PC."""
import argparse
import hashlib
import json
import shutil
from pathlib import Path

import keybinds
from kitty_integration import atomic_text


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def apply(install):
    home = Path.home()
    app = Path(__file__).resolve().parent
    source = app / 'integrations/desktop-files'
    state = home / '.local/state/rice-studio-portable/main-pc-config'
    manifest = state / 'manifest.json'
    if manifest.is_file():
        saved = json.loads(manifest.read_text())
    else:
        saved = {}
    if not install:
        keybinds.apply(False)
        retained = []
        for name, item in saved.items():
            target = home / name
            if not target.is_file() or target.is_symlink() or digest(target) != item['installed']:
                retained.append(name)
                continue
            original = state / 'original' / name
            if item['existed']:
                atomic_text(target, original.read_text())
            else:
                target.unlink()
        if retained:
            atomic_text(manifest, json.dumps({name: saved[name] for name in retained}, indent=2))
            print('Kept files edited since install. Their backups are in', state)
        else:
            manifest.unlink(missing_ok=True)
        return
    if saved:
        raise ValueError('The main-PC companion configs are already installed. Restore them before replacing them.')
    files = [path for path in source.rglob('*') if path.is_file() and not path.is_symlink()]
    for path in files:
        name = path.relative_to(source)
        target = home / name
        if target.is_symlink() or not target.resolve().is_relative_to(home):
            raise ValueError('The companion config points through an existing symlink: ' + str(name))
    keybinds.apply(True)
    changed = []
    try:
        for path in files:
            name = path.relative_to(source)
            target = home / name
            existed = target.is_file()
            original = state / 'original' / name
            if existed:
                original.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                shutil.copyfile(target, original)
            atomic_text(target, path.read_text())
            changed.append((target, original if existed else None))
            saved[str(name)] = {'existed': existed, 'installed': digest(target)}
        atomic_text(manifest, json.dumps(saved, indent=2))
    except Exception:
        for target, original in reversed(changed):
            if original is None:
                target.unlink(missing_ok=True)
            else:
                atomic_text(target, original.read_text())
        keybinds.apply(False)
        raise
    print('Installed the main-PC shortcuts, visuals, and companion configs. Backups:', state)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument('--install', action='store_true')
    modes.add_argument('--restore', action='store_true')
    try:
        apply(parser.parse_args().install)
    except (OSError, ValueError, RuntimeError) as error:
        raise SystemExit(str(error))
