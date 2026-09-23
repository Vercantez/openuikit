#!/bin/zsh
# CASpringAnimation(perceptualDuration:bounce:) coefficients and
# settlingDuration on Apple QuartzCore (macOS host; no simulator needed).
# The iOS 26.1 default row is cross-checked by ../nnwmiscprobe.
set -e
D=${0:A:h}
OUT=${TMPDIR:-/tmp}/springsettleprobe
swiftc -O "$D/main.swift" -o "$OUT"
"$OUT"
