"""Install theme assets with paths resolved for the receiving account."""
import json
import shutil
from pathlib import Path

SOURCE = Path(__file__).resolve().parent / 'themes'
MEDIA = {'.png', '.jpg', '.jpeg', '.webp', '.mp4', '.ttf'}


def prepare(stage, app, config, state, profiles):
    replacements = {
        '@STUDIO_APP@': str(app),
        '@STUDIO_CONFIG@': str(config),
        '@STUDIO_STATE@': str(state),
    }

    def render(text):
        for placeholder, destination in replacements.items():
            text = text.replace(placeholder, destination)
        return text

    for source in SOURCE.rglob('*'):
        if not source.is_file():
            continue
        relative = source.relative_to(SOURCE)
        if relative.name == 'profiles.json' or '__pycache__' in relative.parts:
            continue
        destination = stage / 'app' / 'themes' / relative
        if relative.parts[0] == 'terminals':
            destination = stage / 'config' / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if source.suffix in MEDIA:
            shutil.copyfile(source, destination)
        else:
            destination.write_text(render(source.read_text()))
        destination.chmod(source.stat().st_mode & 0o777)

    packed = json.loads(render((SOURCE / 'profiles.json').read_text()))
    for key, profile in packed.items():
        profile['rice'] = key
        bar = {'hancore': 'hancore-monochrome'}.get(profile['bar'], profile['bar'])
        profile['bar'] = bar
    profiles.update(packed)
