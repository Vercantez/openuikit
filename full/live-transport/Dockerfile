ARG SWIFT_BASE
FROM ${SWIFT_BASE}

ARG SUPPORT_COMMIT
ARG SUPPORT_TREE
ARG SUPPORT_ARCHIVE_SHA256

LABEL org.opencontainers.image.revision="${SUPPORT_COMMIT}" \
      org.opencontainers.image.source-tree="${SUPPORT_TREE}" \
      org.opencontainers.image.source-archive-sha256="${SUPPORT_ARCHIVE_SHA256}" \
      org.opencontainers.image.title="Portable UIKit Mach-O live display host"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        imagemagick \
        libsdl2-dev \
        novnc \
        pkg-config \
        websockify \
        x11-utils \
        x11vnc \
        xdotool \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

COPY full/live-transport /opt/openui-live/source
RUN /opt/openui-live/source/build_linux_sdl_host.sh \
        --output-root /opt/openui-live/host \
    && chmod 0755 /opt/openui-live/source/container_entrypoint.sh \
    && test ! -e /opt/openui-live/source-provenance.tsv

COPY source-provenance.tsv /opt/openui-live/source-provenance.tsv

EXPOSE 6080
ENTRYPOINT ["/opt/openui-live/source/container_entrypoint.sh"]
