"""Pick any bundled Waybar independently of the current desktop preset."""
import subprocess
import sys

import control


def main():
    bars = control.registry()
    if len(sys.argv) > 1 and sys.argv[1] == '--list':
        print('\n'.join(bars))
        return
    if len(sys.argv) > 1:
        key = sys.argv[1]
        if key == 'atif-mode':
            active = control.read(control.STATE / 'bar-override.json').get('bar')
            key = 'atif-v4y' if active == 'atif-v4y-dock' else 'atif-v4y-dock'
    else:
        rows = '\n'.join(f'{key}\t{info[0]}' for key, info in bars.items())
        selected = subprocess.run(['fzf', '--delimiter', '\t', '--with-nth', '2',
                                   '--prompt', 'Waybar › '], input=rows, text=True, capture_output=False,
                                  stdout=subprocess.PIPE)
        if selected.returncode:
            return
        key = selected.stdout.split('\t', 1)[0].strip()
    control.apply_bar(key)
    print('Bar:', bars[key][0])


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error))
