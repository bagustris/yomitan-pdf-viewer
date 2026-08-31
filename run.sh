#!/usr/bin/env bash

set -euo pipefail

exec python3 -m http.server --bind localhost 8000
