#!/usr/bin/env bash
# Real integration gate. Lookalike modules under tests/agent/staging are not
# platform identity; see test_standalone_unit_fixtures.sh for those unit fixtures.
set -euo pipefail
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
exec bash "$SCRIPT_DIR/test_real_integration.sh"
