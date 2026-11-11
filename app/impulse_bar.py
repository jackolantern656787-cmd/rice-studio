"""Close and restore Illogical Impulse's bar via its scoped Quickshell IPC."""
import json
import os
import subprocess
from pathlib import Path

from kitty_integration import atomic_text

NAMESPACES = {'quickshell:bar', 'quickshell:verticalBar'}


def candidates(home):
    config = Path(os.environ.get('XDG_CONFIG_HOME') or home / '.config') / 'quickshell'
    named = config / 'ii/shell.qml'
    if named.is_file():
        yield named
    if (config / 'shell.qml').is_file() and any(
        (config / module).is_file() for module in ('modules/bar/Bar.qml', 'modules/ii/bar/Bar.qml')
    ):
        yield config / 'shell.qml'


def action(run, shell, method):
    try:
        run(['quickshell', '-p', str(shell), 'ipc', 'call', 'bar', method])
    except (OSError, RuntimeError, subprocess.SubprocessError):
        return False
    return True


def visible(run):
    layers = json.loads(run(['hyprctl', 'layers', '-j']))
    return any(item.get('namespace') in NAMESPACES
               for monitor in layers.values()
               for level in monitor.get('levels', {}).values()
               for item in level)


def owner(state):
    path = state / 'impulse-bar.json'
    try:
        saved = json.loads(path.read_text())
    except FileNotFoundError:
        return None
    if saved.get('session') == os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', ''):
        return saved.get('path')
    return None


def hide(home, state, run):
    shells = list(candidates(home))
    if not shells or not visible(run):
        return
    path = state / 'impulse-bar.json'
    prior = path.read_text() if path.exists() else None
    for shell in shells:
        # Record first so the independent rollback can recover the bar.
        atomic_text(path, json.dumps({
            'path': str(shell), 'session': os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', ''),
        }))
        if action(run, shell, 'close'):
            return
        if prior is None:
            path.unlink(missing_ok=True)
        else:
            atomic_text(path, prior)


def restore(home, state, run):
    path = owner(state)
    if not path:
        return
    if any(str(candidate) == path for candidate in candidates(home)) and action(run, path, 'open'):
        (state / 'impulse-bar.json').unlink(missing_ok=True)
