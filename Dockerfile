FROM python:3.13.3-slim-bookworm@sha256:549df749715caa7da8649af1fbf5c0096838a0d69c544dc53c3b3864bfeda4e3

# Misc dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install build-essential curl python3-dev pipx xz-utils

# Node.js and NPM
WORKDIR /tmp
ENV NODE_VERSION=22.10.0 \
    NODE_PLATFORM=linux-x64
RUN curl -O https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && curl -O https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt \
    && grep node-v${NODE_VERSION}-${NODE_PLATFORM}.tar.gz SHASUMS256.txt | sha256sum -c \
    && tar -C /usr --strip-components=1 -xzf node-v${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && node --version \
    && npm --version

# s6-overlay
WORKDIR /tmp
ENV S6_OVERLAY_VERSION=3.2.0.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-noarch.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-x86_64.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# IRRd
USER root
RUN adduser --gecos '' --disabled-password irrd \
    && mkdir -p /opt/irrd \
    && chown -R irrd:irrd /opt/irrd
USER irrd
WORKDIR /opt/irrd
ENV PIPX_BIN_DIR=/opt/irrd/bin
RUN pip install psycopg2-binary==2.9.10 \
    && pip install pyyaml==6.0.2 \
    && pipx ensurepath \
    && pipx install irrd==4.4.4
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.sh /opt/irrd/init-irrd.sh
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.py /opt/irrd/init-irrd.py

# IRR Explorer
USER root
RUN adduser --gecos '' --disabled-password irrexplorer \
    && mkdir -p /opt/irrexplorer \
    && chown -R irrexplorer:irrexplorer /opt/irrexplorer \
    && npm install --global yarn
USER irrexplorer
WORKDIR /opt/irrexplorer
ENV PIPX_BIN_DIR=/opt/irrexplorer/bin
ENV IRRE_SOURCE_SHA1SUM=56402efa8deb8b7fb865d88a5f9895c52f79a1fe
ADD --chown=irrexplorer:irrexplorer https://github.com/NLNOG/irrexplorer/archive/db76b42d96e5baea47548248d7d3b9528bcc63da.tar.gz /tmp/irrexplorer.tar.gz
RUN echo "${IRRE_SOURCE_SHA1SUM}  /tmp/irrexplorer.tar.gz" | sha1sum -c - \
    && tar -xz --strip-components=1 --file="/tmp/irrexplorer.tar.gz" \
    && pip install python-dotenv==1.0.1 \
    && pipx ensurepath \
    && pipx install poetry==2.1.1 \
    && /opt/irrexplorer/bin/poetry install
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.sh /opt/irrexplorer/init-irrexplorer.sh
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.py /opt/irrexplorer/init-irrexplorer.py

# Supercronic
USER root
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64
RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

# Cleanup
USER root
RUN apt-get --yes --autoremove remove build-essential curl xz-utils

# Set expose ports and entrypoint
EXPOSE 43/tcp
EXPOSE 8000/tcp
ENTRYPOINT ["/init"]

LABEL org.opencontainers.image.authors="MattKobayashi <matthew@kobayashi.au>"
