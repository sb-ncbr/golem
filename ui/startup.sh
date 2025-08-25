#!/bin/bash

UI_PORT=3000

if [[ -z "${UI_PORT}" ]]; then
    echo "UI_PORT environment variable is not set."
    exit 1
fi

cd build/web/

python3 -m http.server $UI_PORT