"""Connect ordinary Kitty launches to the current Studio terminal profile."""
import os
import re
import shlex
import tempfile
from pathlib import Path


def atomic_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
        if path.exists():
            os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def kitty_config(home):
    path = (home / '.config/kitty/kitty.conf').resolve()
    if not path.is_relative_to(home.resolve()):
        raise ValueError('Kitty config points outside your home. Use Studio Terminal or add the Studio include to your Kitty config.')
    return path


def include_block(home):
    path = home / '.local/state/rice-studio-portable/kitty-active.conf'
    return f'\n# Rice Studio terminal profile\ninclude {path}\n# End Rice Studio terminal profile\n'


def install(home):
    path = kitty_config(home)
    previous = path.read_text() if path.exists() else ''
    block = include_block(home)
    if block not in previous:
        atomic_text(path, previous + block)
    return path, previous


def uninstall(home):
    path = kitty_config(home)
    if path.exists():
        text = path.read_text()
        block = include_block(home)
        if block in text:
            atomic_text(path, text.replace(block, '', 1))


def sync(key, profiles, config, state, app):
    terminal = profiles.get(key, {}).get('terminal', 'main')
    text = ''
    if key != 'main' and terminal != 'main':
        if not re.fullmatch(r'[a-z0-9-]+', terminal):
            raise ValueError('Invalid Kitty profile name')
        directory = config / 'terminals'
        preset = directory / (terminal + '.conf')
        if not preset.is_file():
            raise FileNotFoundError(preset)
        text = f'include {preset}\n'
        if (directory / (terminal + '-fastfetch.jsonc')).is_file():
            startup = shlex.join([str(app / 'commands/terminal-shell'), terminal])
            text += f'shell {startup}\n'
    atomic_text(state / 'kitty-active.conf', text)
