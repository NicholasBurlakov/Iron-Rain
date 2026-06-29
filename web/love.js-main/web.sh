#!/usr/bin/env bash

set -euo pipefail

# Create the LÖVE package used by the browser player.
rm -f web/game.love

zip -qr web/game.love \
    main.lua \
    conf.lua \
    assets \
    modules