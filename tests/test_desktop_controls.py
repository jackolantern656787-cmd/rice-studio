from pathlib import Path
import json
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'app'))
import impulse_bar
import window_mode


class Adapter:
    def __init__(self, folder):
        self.HOME = Path(folder)
        self.STATE = self.HOME / 'state'
        self.calls = []
        self.layout = 'master'
        self.windows = [
            {'address': '0x11', 'pid': 1, 'floating': False},
            {'address': '0x22', 'pid': 2, 'floating': True},
            {'address': '0x33', 'pid': 3, 'floating': True, 'pinned': True},
        ]
        self.bar_visible = True

    def read(self, path):
        return json.loads(path.read_text()) if path.exists() else {}

    def atomic(self, path, value):
        path.write_text(json.dumps(value))

    def run(self, args):
        self.calls.append(args)
        if args[1:3] == ['getoption', 'general:layout']:
            return json.dumps({'str': self.layout})
        if args[1] == 'getoption':
            return '{"float": 0.5}'
        if args[1] == 'clients':
            return json.dumps(self.windows)
        if args[1] == 'layers':
            rows = [{'namespace': 'quickshell:bar'}] if self.bar_visible else []
            return json.dumps({'test': {'levels': {'2': rows}}})
        if args[0] == 'quickshell':
            self.bar_visible = args[-1] == 'open'
        return 'ok'

    def set_options(self, options):
        self.layout = options['general:layout']


class DesktopControls(unittest.TestCase):
    def test_floating_preserves_original_float_and_scrolling_restores_tiling_layout(self):
        with tempfile.TemporaryDirectory() as folder:
            control = Adapter(folder)
            self.assertEqual(window_mode.switch(control, 'floating'), 'floating')
            control.windows[0]['floating'] = True
            self.assertEqual(window_mode.switch(control, 'scrolling'), 'scrolling')
            self.assertEqual(control.layout, 'scrolling')
            dispatched = [args[-1] for args in control.calls if 'hl.dispatch' in args[-1]]
            self.assertEqual(len(dispatched), 2)
            self.assertTrue(all('0x11' in code for code in dispatched))
            window_mode.switch(control, 'tiling')
            self.assertEqual(control.layout, 'master')

    def test_ii_only_reopens_bar_studio_closed(self):
        with tempfile.TemporaryDirectory() as folder, patch.dict('os.environ', {'XDG_CONFIG_HOME': ''}):
            control = Adapter(folder)
            shell = control.HOME / '.config/quickshell/ii/shell.qml'
            shell.parent.mkdir(parents=True)
            shell.touch()
            impulse_bar.hide(control.HOME, control.STATE, control.run)
            self.assertFalse(control.bar_visible)
            self.assertEqual(impulse_bar.owner(control.STATE), str(shell))
            impulse_bar.restore(control.HOME, control.STATE, control.run)
            self.assertTrue(control.bar_visible)
            self.assertIsNone(impulse_bar.owner(control.STATE))
            control.bar_visible = False
            impulse_bar.hide(control.HOME, control.STATE, control.run)
            impulse_bar.restore(control.HOME, control.STATE, control.run)
            self.assertFalse(control.bar_visible)
