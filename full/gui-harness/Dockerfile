# syntax=docker/dockerfile:1.7

ARG SWIFT_BASE=swift@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc
FROM ${SWIFT_BASE}

ARG DEBIAN_FRONTEND=noninteractive
ARG SOURCE_COMMIT
ARG SOURCE_TREE
ARG SOURCE_ARCHIVE_SHA256
ARG SOURCE_TRACKED_FILES
ARG PRODUCT=openhost
ARG DISABLE_CMO=1

LABEL org.opencontainers.image.title="Open platform Linux GUI evaluation harness" \
      org.opencontainers.image.revision="${SOURCE_COMMIT}" \
      org.opencontainers.image.source-tree="${SOURCE_TREE}" \
      org.opencontainers.image.source-archive-sha256="${SOURCE_ARCHIVE_SHA256}" \
      org.opencontainers.image.source-tracked-files="${SOURCE_TRACKED_FILES}" \
      org.opencontainers.image.product="${PRODUCT}" \
      org.opencontainers.image.gui-contract="xvfb-x11vnc-novnc-v1"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fonts-dejavu-core \
        imagemagick \
        libsdl2-dev \
        novnc \
        websockify \
        x11-utils \
        x11vnc \
        xdotool \
        xvfb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/application
COPY source/ ./
COPY source-provenance.tsv /opt/openplatform/source-provenance.tsv
COPY container_entrypoint.sh /usr/local/bin/openplatform-gui-entrypoint

# The host creates source/ with `git archive COMMIT`, never by copying a
# working tree. Recheck the independently supplied identity inside the image
# before SwiftPM is allowed to create any products.
RUN test "$(awk -F '\t' '$1 == "commit" { print $2 }' /opt/openplatform/source-provenance.tsv)" = "${SOURCE_COMMIT}" \
    && test "$(awk -F '\t' '$1 == "tree" { print $2 }' /opt/openplatform/source-provenance.tsv)" = "${SOURCE_TREE}" \
    && test "$(awk -F '\t' '$1 == "archive-sha256" { print $2 }' /opt/openplatform/source-provenance.tsv)" = "${SOURCE_ARCHIVE_SHA256}" \
    && test "$(awk -F '\t' '$1 == "tracked-files" { print $2 }' /opt/openplatform/source-provenance.tsv)" = "${SOURCE_TRACKED_FILES}" \
    && test -f Package.swift \
    && rm -rf .build \
    && case "${DISABLE_CMO}" in \
         1) swift build -c release --product "${PRODUCT}" -Xswiftc -disable-cmo ;; \
         0) swift build -c release --product "${PRODUCT}" ;; \
         *) echo "DISABLE_CMO must be 0 or 1" >&2; exit 2 ;; \
       esac \
    && test -x ".build/release/${PRODUCT}"

# OpenUIKit accepts a font directory at runtime. These are redistributable
# Linux fonts supplied only through that documented host configuration hook.
RUN mkdir -p /opt/openplatform/fonts \
    && ln -s /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf /opt/openplatform/fonts/SFNS.ttf \
    && ln -s /usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf /opt/openplatform/fonts/SFNSMono.ttf \
    && ln -s /usr/share/fonts/truetype/dejavu/DejaVuSans-Oblique.ttf /opt/openplatform/fonts/SFNSItalic.ttf \
    && dpkg-query -W libsdl2-2.0-0 novnc websockify x11vnc xvfb \
         > /opt/openplatform/display-packages.tsv \
    && chmod 0755 /usr/local/bin/openplatform-gui-entrypoint

EXPOSE 6080
ENTRYPOINT ["/usr/local/bin/openplatform-gui-entrypoint"]
