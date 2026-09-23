# syntax=docker/dockerfile:1.7
# The interactive layer over the guest build image (openuikit-guest-env:arm64,
# .cursor/Dockerfile): an X server the guest host_full window opens on, a VNC
# server on that display and noVNC so a browser on the Mac can drive it.
# Built and tagged by scripts/ops/guest_interactive.sh; nothing here is a
# build input of the guest.
ARG BASE_IMAGE=openuikit-guest-env:arm64
FROM ${BASE_IMAGE}
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        novnc \
        websockify \
        x11vnc \
        xdotool \
    && rm -rf /var/lib/apt/lists/* \
    && test -f /usr/share/novnc/vnc.html \
    && command -v x11vnc websockify xdotool Xvfb
