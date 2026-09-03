#!/usr/bin/env bash
# Per-agent start. The Cursor Build snapshot already contains evidence, the
# scratch corpus, x86 fixtures, and phase2 rung-a products. Do not rebuild.

set -euo pipefail

printf 'CURSOR_ENV_START_OK rebuild=0\n'
