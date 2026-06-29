#!/usr/bin/env bash

set -euo pipefail

# Create the .love package using Python's built-in ZIP support.
rm -f web/game.love

PYTHON_BIN="$(command -v python3 || command -v python)"

"$PYTHON_BIN" - <<'PYTHON_SCRIPT'
from pathlib import Path
import zipfile

root = Path.cwd()
output_file = root / "web" / "game.love"

game_items = [
    "main.lua",
    "conf.lua",
    "assets",
    "modules",
]

with zipfile.ZipFile(
    output_file,
    "w",
    compression=zipfile.ZIP_DEFLATED,
) as archive:
    for item_name in game_items:
        item_path = root / item_name

        if item_path.is_file():
            archive.write(
                item_path,
                item_path.relative_to(root).as_posix(),
            )

        elif item_path.is_dir():
            for file_path in item_path.rglob("*"):
                if file_path.is_file():
                    archive.write(
                        file_path,
                        file_path.relative_to(root).as_posix(),
                    )

print(f"Created {output_file}")
PYTHON_SCRIPT