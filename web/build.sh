#!/usr/bin/env bash

set -euo pipefail

# Package the current game files for the browser player.
rm -f web/game.love

zip -qr web/game.love \
    main.lua \
    conf.lua \
    assets \
    modules