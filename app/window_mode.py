"""Session-scoped Hyprland layout and floating mode."""
import fcntl
import json
import subprocess

MODES = ('tiling', 'floating', 'scrolling')


def layout(control):
    value = json.loads(control.run(['hyprctl', 'getoption', 'general:layout', '-j'])).get('str')
    if not isinstance(value, str) or not value:
        raise RuntimeError('Could not read the Hyprland layout.')
    return value


def session_id():
    import os
    return os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')


def saved(control):
    state = control.read(control.STATE / 'window-mode.json')
    return state if state.get('session') == session_id() else {}


def status(control):
    actual = layout(control)
    state = saved(control)
    if state.get('mode') == 'floating':
        try:
            control.run(['hyprctl', 'eval', 'assert(_G.riceStudioFloatingRule and _G.riceStudioFloatingRule:is_enabled(), "Studio floating rule missing")'])
        except (RuntimeError, OSError, subprocess.SubprocessError):
            pass
        else:
            return 'floating'
    return 'scrolling' if actual == 'scrolling' else 'tiling'


def floating_rule(control, enabled):
    create = '''
if not _G.riceStudioFloatingRule then
    _G.riceStudioFloatingRule = hl.window_rule({
        name="rice-studio-portable-float", match={class=".*",float=false}, float=true
    })
end
''' if enabled else ''
    value = 'true' if enabled else 'false'
    code = create + f'if _G.riceStudioFloatingRule then _G.riceStudioFloatingRule:set_enabled({value}) end'
    control.run(['hyprctl', 'eval', code])


def change_floating(control, client, floating):
    address = json.dumps('address:' + client['address'])
    action = 'set' if floating else 'unset'
    control.run(['hyprctl', 'eval',
                 f'hl.dispatch(hl.dsp.window.float({{window={address}, action="{action}"}}))'])


def identity(client):
    return [client['address'], client.get('pid'), client.get('initialClass', client.get('class'))]


def eligible(client):
    return (client.get('mapped', True) and not client.get('pinned')
            and not client.get('fullscreen') and client.get('workspace', {}).get('id', 0) >= 0)


def switch(control, mode):
    if mode not in MODES:
        raise ValueError('Choose Tiling, Floating, or Scrolling.')
    control.STATE.mkdir(parents=True, exist_ok=True)
    with (control.STATE / 'window-mode.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return _switch(control, mode)


def _switch(control, mode):
    state = saved(control)
    before = layout(control)
    previous = status(control)
    if mode == previous and not (state.get('mode') == 'floating' and mode != 'floating'):
        return mode
    if mode == 'scrolling':
        option = json.loads(control.run(['hyprctl', 'getoption', 'scrolling:column_width', '-j']))
        if 'float' not in option:
            raise RuntimeError('This Hyprland build does not support the native scrolling layout.')
    clients = json.loads(control.run(['hyprctl', 'clients', '-j']))
    previous_floating = state.get('mode') == 'floating'
    preserved = state.get('preserved', []) if previous_floating else [
        identity(client) for client in clients if client.get('floating')
    ]
    tiled = before if before != 'scrolling' else state.get('tiling_layout', 'dwindle')
    desired = 'scrolling' if mode == 'scrolling' else tiled if mode == 'tiling' else before
    changed = []
    try:
        if mode == 'floating' or previous_floating:
            floating_rule(control, mode == 'floating')
        if desired != before:
            control.set_options({'general:layout': desired})
            if layout(control) != desired:
                raise RuntimeError('Hyprland did not accept the requested layout.')
        for client in clients:
            if not eligible(client):
                continue
            if mode == 'floating' and not client.get('floating'):
                change_floating(control, client, True)
                changed.append(client)
            elif mode != 'floating' and previous_floating and client.get('floating') and identity(client) not in preserved:
                change_floating(control, client, False)
                changed.append(client)
        control.atomic(control.STATE / 'window-mode.json', {
            'session': session_id(), 'mode': mode, 'tiling_layout': tiled,
            'original_layout': state.get('original_layout', before),
            'preserved': preserved if mode == 'floating' else [],
        })
    except Exception:
        if mode == 'floating' or previous_floating:
            try:
                floating_rule(control, previous == 'floating')
            except Exception:
                pass
        if desired != before:
            control.set_options({'general:layout': before})
        for client in changed:
            change_floating(control, client, bool(client.get('floating')))
        raise
    return mode


def restore(control):
    original = saved(control).get('original_layout')
    if original:
        switch(control, 'scrolling' if original == 'scrolling' else 'tiling')
        if layout(control) != original:
            control.set_options({'general:layout': original})
