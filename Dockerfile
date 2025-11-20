FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS irrd

# uv
COPY --from=ghcr.io/astral-sh/uv:0.9.11@sha256:5aa820129de0a600924f166aec9cb51613b15b68f1dcd2a02f31a500d2ede568 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    build-essential \
    ca-certificates \
    cargo \
    libffi-dev \
    libpq-dev \
    python3-dev

# Fix for datrie builds
# (https://github.com/pytries/datrie/issues/101)
ARG CFLAGS=-Wno-error=incompatible-pointer-types
ARG CXXFLAGS=-Wno-error=incompatible-pointer-types

# IRRd
WORKDIR /opt/irrd
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv/irrd/uv.lock,target=uv.lock \
    --mount=type=bind,source=uv/irrd/pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-dev


FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS irrexplorer

# uv
COPY --from=ghcr.io/astral-sh/uv:0.9.11@sha256:5aa820129de0a600924f166aec9cb51613b15b68f1dcd2a02f31a500d2ede568 /uv /uvx /bin/
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    build-essential \
    ca-certificates \
    curl

# Fix for py-radix builds
ARG CFLAGS=-Wno-error=incompatible-pointer-types
ARG CXXFLAGS=-Wno-error=incompatible-pointer-types

# Node.js and NPM
# renovate: datasource=github-releases packageName=nodejs/node
ARG NODE_VERSION="v20.19.5" \
    NODE_PLATFORM=linux-x64
RUN curl -O https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && curl -O https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt \
    && grep node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz SHASUMS256.txt | sha256sum -c \
    && tar -C /usr --strip-components=1 -xzf node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && echo "Node.js version: $(node --version)" \
    && echo "NPM version: $(npm --version)"

# IRR Explorer
WORKDIR /opt/irrexplorer
ARG IRRE_SHA1SUM=6448431c685ff056b293ddd732741468917e0013
ADD https://github.com/NLNOG/irrexplorer/archive/7d9d64c0d79a87d1f60a8fd03178a7d0afc4c9a2.tar.gz /tmp/irrexplorer.tar.gz
RUN echo "${IRRE_SHA1SUM}  /tmp/irrexplorer.tar.gz" | sha1sum -c - \
    && tar -xz --strip-components=1 --file="/tmp/irrexplorer.tar.gz"
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv/irrexplorer/uv.lock,target=uv.lock \
    --mount=type=bind,source=uv/irrexplorer/pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-dev
RUN /opt/irrexplorer/.venv/bin/poetry install


FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS nodejs

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    ca-certificates \
    curl

# Node.js and NPM
# renovate: datasource=github-releases packageName=nodejs/node
ARG NODE_VERSION="v20.19.5" \
    NODE_PLATFORM=linux-x64
RUN curl -O https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && curl -O https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt \
    && grep node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz SHASUMS256.txt | sha256sum -c \
    && tar -C /usr --strip-components=1 -xzf node-${NODE_VERSION}-${NODE_PLATFORM}.tar.gz \
    && echo "Node.js version: $(node --version)" \
    && echo "NPM version: $(npm --version)"


FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS s6overlay

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    ca-certificates \
    curl \
    xz-utils

# s6-overlay
# renovate: datasource=github-releases packageName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION="v3.2.1.0"
WORKDIR /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-noarch.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-x86_64.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/


FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016 AS supercronic

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    ca-certificates \
    curl \
    jq

# Supercronic
# renovate: datasource=github-releases packageName=aptible/supercronic
ARG SUPERCRONIC_VERSION="v0.2.39"
ARG SUPERCRONIC="supercronic-linux-amd64"
ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/${SUPERCRONIC}
RUN export SUPERCRONIC_SHA256SUM=$(curl -fsSL \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/repos/aptible/supercronic/releases \
    | jq -r '.[] | select(.name == $ENV.SUPERCRONIC_VERSION) | .assets[] | select(.name == $ENV.SUPERCRONIC) | .digest') \
    && echo "SHA256 digest from API: ${SUPERCRONIC_SHA256SUM}" \
    && curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA256SUM}  ${SUPERCRONIC}" | sed -e 's/^sha256://' | sha256sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic


FROM debian:trixie-slim@sha256:18764e98673c3baf1a6f8d960b5b5a1ec69092049522abac4e24a7726425b016

# Dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    adduser \
    libpq5 \
    && chmod 0655 /root

# Node.js and NPM
COPY --from=nodejs /usr/ /usr/
RUN echo "Node.js version: $(node --version)" \
    && echo "NPM version: $(npm --version)"

# s6-overlay
COPY --from=s6overlay /init /
COPY --from=s6overlay /command/ /command/
COPY --from=s6overlay /package/ /package/
COPY --from=s6overlay /etc/s6-overlay/ /etc/s6-overlay/

# Supercronic
COPY --from=supercronic /usr/local/bin/supercronic /usr/local/bin/supercronic

# IRRd
COPY --chown=irrd:irrd --from=irrd /root/.local/share/uv /root/.local/share/uv
RUN adduser --gecos '' --disabled-password irrd \
    && mkdir -p /opt/irrd \
    && chown -R irrd:irrd /opt/irrd
COPY --chown=irrd:irrd --from=irrd /opt/irrd /opt/irrd
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.sh /opt/irrd/init-irrd.sh
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.py /opt/irrd/init-irrd.py

# IRRexplorer
COPY --chown=irrexplorer:irrexplorer --from=irrexplorer /root/.local/share/uv /root/.local/share/uv
RUN adduser --gecos '' --disabled-password irrexplorer \
    && mkdir -p /opt/irrexplorer \
    && chown -R irrexplorer:irrexplorer /opt/irrexplorer \
    && npm install --global yarn
COPY --chown=irrexplorer:irrexplorer --from=irrexplorer /opt/irrexplorer /opt/irrexplorer
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.sh /opt/irrexplorer/init-irrexplorer.sh
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.py /opt/irrexplorer/init-irrexplorer.py

# Cleanup
RUN apt-get --yes remove \
    adduser \
    && apt-get clean

# Set expose ports and entrypoint
EXPOSE 43/tcp
EXPOSE 8000/tcp
ENTRYPOINT ["/init"]

LABEL org.opencontainers.image.authors="MattKobayashi <matthew@kobayashi.au>"
