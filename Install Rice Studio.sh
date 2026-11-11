#!/bin/sh
# Run from a file manager after extracting the release archive.
set -eu
cd -- "$(dirname -- "$0")"
if ! command -v kitty >/dev/null 2>&1; then
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --text='Rice Studio needs Kitty to install and display its themed terminals.'
  else
    printf '%s\n' 'Rice Studio needs Kitty to install and display its themed terminals.' >&2
  fi
  exit 1
fi
exec kitty --title 'Install Rice Studio' --hold sh -c '
  if python3 install.py --install; then
    "$HOME/.local/bin/rice-studio"
    printf "\nRice Studio is ready. Close this window and choose a theme in the app.\n"
  fi
'
