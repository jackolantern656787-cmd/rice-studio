"""Apply preset-specific window geometry to new windows."""
import json
import re
import subprocess


def apply(run, rice):
    version = run(['hyprctl', 'version'])
    match = re.search(r'Hyprland (\d+)\.(\d+)', version)
    if not match or tuple(map(int, match.groups())) < (0, 57):
        return
    code = '''
if _G.riceStudioTideglassTerminal then
    _G.riceStudioTideglassTerminal:set_enabled(false)
end
'''
    if rice == 'tideglass':
        monitors = json.loads(run(['hyprctl', 'monitors', '-j']))
        width, height = 1200, 700
        for monitor in monitors:
            w, h = monitor['width'], monitor['height']
            if monitor.get('transform', 0) % 2:
                w, h = h, w
            left, top, right, bottom = monitor.get('reserved', (0, 0, 0, 0))
            scale = monitor.get('scale', 1)
            width = min(width, max(320, int(w / scale) - left - right - 24))
            height = min(height, max(200, int(h / scale) - top - bottom - 24))
        code += f'''
if not _G.riceStudioTideglassTerminal then
_G.riceStudioTideglassTerminal = hl.window_rule({{
    name="rice-studio-tideglass-terminal",
    match={{class="^(kitty|tideglass-demo)$"}},
    float=true, center=true, size={{{width},{height}}}
}})
end
_G.riceStudioTideglassTerminal:set_enabled(true)
'''
    try:
        run(['hyprctl', 'eval', code])
    except subprocess.CalledProcessError as error:
        message = (error.stdout or '') + (error.stderr or '')
        if any(word in message.lower() for word in ('legacy', 'unknown request', 'not supported')):
            return
        raise
