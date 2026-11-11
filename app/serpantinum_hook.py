"""Opt-in bar switch hook for the compatible stock Serpantinum QML layout."""
import argparse
import hashlib
import re
from pathlib import Path

import control

ROOT = control.HOME / '.local/share/serpantinum/src/quickshell'
BACKUP = control.STATE / 'serpantinum-bar-hook.json'
HOOK = '''
    property bool externalBarHidden: false
    IpcHandler {
        target: "barSwitcher"
        function setHidden(value: string): void {
            studioShell.externalBarHidden = value === "true";
        }
        function status(): string {
            return studioShell.externalBarHidden ? "hidden" : "main";
        }
    }
'''


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise ValueError('Unrecognized Serpantinum layout. No changes written.')
    return text.replace(old, new, 1)


def digest(text):
    return hashlib.sha256(text.encode()).hexdigest()


def install_hook():
    shell = ROOT / 'Shell.qml'
    bar = ROOT / 'bar/Bar.qml'
    original = {path: path.read_text() for path in (shell, bar)}
    if 'target: "barSwitcher"' in original[shell]:
        print('Serpantinum already has the bar switch hook.')
        return
    if BACKUP.exists():
        raise ValueError('A previous hook backup exists. Restore it before reinstalling.')
    # The upstream ShellRoot may already have an id. Bind the hook to that id.
    match = re.search(r'ShellRoot\s*\{\s*id:\s*(\w+)', original[shell])
    if match:
        root_id = match[1]
        head = match[0]
        with_hook = replace_once(original[shell], head, head + '\n' + HOOK.replace('studioShell', root_id))
    else:
        root_id = 'studioShell'
        with_hook = replace_once(original[shell], 'ShellRoot {', 'ShellRoot {\n    id: studioShell\n' + HOOK)
    if 'import Quickshell.Io' not in with_hook:
        with_hook = 'import Quickshell.Io\n' + with_hook
    with_hook = replace_once(with_hook, 'Bar {}', 'Bar { externalBarHidden: ' + root_id + '.externalBarHidden }')

    match = re.search(r'Variants\s*\{\s*id:\s*(\w+)', original[bar])
    if not match:
        raise ValueError('Unrecognized Serpantinum bar layout. No changes written.')
    bar_id = match[1]
    patched_bar = replace_once(original[bar], match[0], match[0] + '\n    property bool externalBarHidden: false')
    patched_bar = replace_once(patched_bar, 'visible: barConfigReady && !shouldHideForRedact',
                               f'visible: barConfigReady && !shouldHideForRedact && !{bar_id}.externalBarHidden')
    patched_bar = replace_once(patched_bar, 'exclusiveZone: (!barConfigReady',
                               f'exclusiveZone: ({bar_id}.externalBarHidden || !barConfigReady')
    updated = {bar: patched_bar, shell: with_hook}
    control.atomic(BACKUP, {str(path.relative_to(ROOT)): {'original': original[path], 'patched': digest(text)}
                            for path, text in updated.items()})
    changed = []
    try:
        for path, text in updated.items():
            write(path, text)
            changed.append(path)
    except Exception:
        for path in reversed(changed):
            write(path, original[path])
        BACKUP.unlink()
        raise
    print('Bar hook installed. Restart Serpantinum if it does not reload automatically.')


def write(path, text):
    import os
    import tempfile
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        os.chmod(name, path.stat().st_mode & 0o777)
        os.replace(name, path)
    finally:
        Path(name).unlink(missing_ok=True)


def restore_hook():
    saved = control.read(BACKUP)
    if not saved:
        return
    for name in ('Shell.qml', 'bar/Bar.qml'):
        if digest((ROOT / name).read_text()) != saved[name]['patched']:
            raise ValueError('Serpantinum files changed since installing the hook. Backup retained at ' + str(BACKUP))
    control.serp_bar(False)
    for name in ('Shell.qml', 'bar/Bar.qml'):
        write(ROOT / name, saved[name]['original'])
    BACKUP.unlink()
    print('Original Serpantinum QML restored.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--install', action='store_true')
    mode.add_argument('--restore', action='store_true')
    try:
        install_hook() if parser.parse_args().install else restore_hook()
    except (OSError, ValueError) as error:
        raise SystemExit(str(error))
