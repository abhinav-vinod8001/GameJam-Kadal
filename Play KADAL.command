#!/bin/zsh
cd -- "$(dirname -- "$0")"
if command -v godot >/dev/null 2>&1; then
  kadal_engine="$(command -v godot)"
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  kadal_engine=/Applications/Godot.app/Contents/MacOS/Godot
else
  print 'Open project.godot in Godot 4.3 or later, then press F5 to play.'
  read -r 'reply?Press Return to close.'
  exit 1
fi
# A fresh download needs fonts, audio, and global script classes imported once.
if [[ ! -f .godot/global_script_class_cache.cfg ]]; then
  print 'Preparing KADAL for its first launch…'
  "$kadal_engine" --headless --path "$PWD" --editor --import --quit || exit 1
fi
exec "$kadal_engine" --path "$PWD" "$@"
