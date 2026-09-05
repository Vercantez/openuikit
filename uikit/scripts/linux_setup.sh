#!/usr/bin/env bash
# linux_setup.sh — idempotent apt/pip for a Linux OpenUIKit agent.
#
# Linux trial 2026-09-05 (swift:6.2-noble): Tools/compare needs PIL + numpy
# (ModuleNotFoundError: PIL) and the image has no zsh, so the five agent
# scripts could not even parse. Run as root inside the container:
#   bash scripts/linux_setup.sh
# Dockerfile.linux-agent bakes the same steps in.
set -e
if [ "$(id -u)" -ne 0 ]; then
  echo "linux_setup.sh: run as root inside the container" >&2
  exit 2
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq --no-install-recommends \
  zsh python3-pil python3-numpy python3-pip libsdl2-dev pkg-config
python3 - <<'PY'
import PIL, numpy
print("linux_setup: PIL", PIL.__version__, "numpy", numpy.__version__)
PY
command -v zsh >/dev/null
zsh --version | head -1
echo "linux_setup: ok"
