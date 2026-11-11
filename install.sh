#!/bin/sh
set -eu
cd -- "$(dirname -- "$0")"
if [ "${1:-}" = "--deps" ]; then
  printf '%s\n' 'This installs repository packages and performs the full system upgrade required by Arch.'
  exec sudo pacman -Syu --needed python python-pillow quickshell qt6-declarative qt6-multimedia qt6-imageformats qt6-svg kitty grim wf-recorder ffmpeg xdg-utils playerctl cmatrix waybar wofi cava fastfetch starship ttf-jetbrains-mono-nerd ttf-iosevka-nerd noto-fonts pavucontrol ttf-jetbrains-mono gsfonts
fi
exec python3 install.py "$@"
