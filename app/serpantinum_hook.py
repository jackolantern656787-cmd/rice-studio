"""Opt-in bar switch hook for the compatible stock Serpantinum QML layout."""
import argparse
import hashlib
import re
import time
from pathlib import Path

import control

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


def install_hook(shell=None):
    shell = shell or control.serp_shell()
    if shell is None:
        raise ValueError('No Serpantinum shell found. Start Serpantinum first.')
    root = shell.parent
    bar = next((p for p in (root/'bar/Bar.qml', root/'bar/bar.qml') if p.is_file()), None)
    if bar is None:
        raise ValueError(f'Could not locate the Serpantinum bar QML next to {shell}.')
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
    components = list(re.finditer(r'\bBar\s*\{\s*\}', with_hook))
    if len(components) != 1:
        raise ValueError('Could not find the stock Bar component in ' + str(shell))
    with_hook = replace_once(with_hook, components[0][0], 'Bar { externalBarHidden: ' + root_id + '.externalBarHidden }')

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
    control.atomic(BACKUP, {'root': str(root), 'files': {
        str(path.relative_to(root)): {'original': original[path], 'patched': digest(text)}
        for path, text in updated.items()
    }})
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
    root = Path(saved.get('root', control.HOME / '.local/share/serpantinum/src/quickshell'))
    files = saved.get('files', saved)
    paths = {root / name: item for name, item in files.items()}
    for path, item in paths.items():
        if not path.resolve().is_relative_to(root.resolve()) or digest(path.read_text()) != item['patched']:
            raise ValueError('Serpantinum files changed since installing the hook. Backup retained at ' + str(BACKUP))
    control.serp_bar(False)
    for path, item in paths.items():
        write(path, item['original'])
    BACKUP.unlink()
    print('Original Serpantinum QML restored.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--install', action='store_true')
    mode.add_argument('--restore', action='store_true')
    parser.add_argument('--hide', action='store_true', help='Hide the bar after installing the hook')
    args = parser.parse_args()
    try:
        if args.install:
            install_hook()
            if args.hide:
                for _ in range(12):
                    if control.serp_bar() in ('main','hidden'):
                        control.serp_bar(True)
                        if control.serp_bar() == 'hidden':
                            print('Serpantinum bar hidden.')
                            break
                    time.sleep(.25)
                else:
                    raise ValueError('Bar hook saved, but the running shell did not load it. Restart Serpantinum, then rerun this command.')
        else:
            restore_hook()
    except (OSError, ValueError) as error:
        raise SystemExit(str(error))
