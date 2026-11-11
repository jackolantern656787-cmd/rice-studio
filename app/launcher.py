"""Launch the bundled Zunder in its own socket and configuration directory."""
import json
import os
import platform

import subprocess
import time
from pathlib import Path

from kitty_integration import atomic_text


def launch(app, state, theme, accent):
    binary = app / 'integrations/zunder/zunder'
    if platform.machine() != 'x86_64':
        return False
    original_runtime = os.environ.get('XDG_RUNTIME_DIR')
    wayland = os.environ.get('WAYLAND_DISPLAY')
    if not original_runtime or not wayland:
        return False
    runtime = Path(original_runtime) / 'rice-zunder'
    runtime.mkdir(mode=0o700, exist_ok=True)
    hypr = runtime / 'hypr'
    if not hypr.exists() and not hypr.is_symlink():
        hypr.symlink_to(Path(original_runtime) / 'hypr')
    config_root = state / 'launcher-config'
    config = config_root / 'zunder'
    config.mkdir(parents=True, exist_ok=True, mode=0o700)
    env = dict(os.environ, XDG_RUNTIME_DIR=str(runtime),
               WAYLAND_DISPLAY=str(Path(original_runtime) / wayland),
               XDG_CONFIG_HOME=str(config_root))
    styles = app / 'themes/launchers'
    for style in styles.glob('*.css'):
        target = config / 'themes' / style.name
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            target.symlink_to(style)
    custom_style = config / 'style.css'
    if not custom_style.exists():
        custom_style.symlink_to(app / 'integrations/zunder/style.css')
    if not (styles / (theme + '.css')).is_file() and theme.startswith('rice-'):
        theme = 'graphite'
    config_path = config / 'config.toml'
    value = f'theme = {json.dumps(theme)}\naccent = {json.dumps(accent)}\nwidth = 820\n'
    if not config_path.exists() or config_path.read_text() != value:
        atomic_text(config_path, value)
        if (runtime / 'zunder.sock').exists():
            subprocess.run([str(binary), 'reload'], env=env, capture_output=True, timeout=4)
    try:
        socket = runtime / 'zunder.sock'
        if not socket.exists():
            server = subprocess.Popen([str(binary), 'server'], env=env,
                                      stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                                      stderr=subprocess.DEVNULL, start_new_session=True)
            deadline = time.monotonic() + 4
            while not socket.exists() and server.poll() is None and time.monotonic() < deadline:
                time.sleep(.05)
            if not socket.exists():
                if server.poll() is None:
                    server.terminate()
                return False
        result = subprocess.run([str(binary), 'toggle'], env=env, timeout=8)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0


def stop(app):
    runtime = os.environ.get('XDG_RUNTIME_DIR')
    if runtime and (Path(runtime) / 'rice-zunder/zunder.sock').exists():
        subprocess.run([str(app / 'integrations/zunder/zunder'), 'quit'],
                       env=dict(os.environ, XDG_RUNTIME_DIR=str(Path(runtime) / 'rice-zunder')),
                       capture_output=True, timeout=5)
