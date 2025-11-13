FROM python:3.13.9-slim-trixie@sha256:85dfbf1b566b7addfe645faea9938e81a0a01a83580b0ea05fb23706357d77fb

# Misc dependencies
RUN apt-get update \
    && apt-get --no-install-recommends --yes install \
    build-essential \
    cargo \
    curl \
    jq \
    libpq-dev \
    pipx \
    python3-dev \
    xz-utils

WORKDIR /tmp

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

# s6-overlay
# renovate: datasource=github-releases packageName=just-containers/s6-overlay
ARG S6_OVERLAY_VERSION="v3.2.1.0"
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-noarch.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz.sha256 /tmp
RUN echo "$(cat s6-overlay-x86_64.tar.xz.sha256)" | sha256sum -c - \
    && tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
COPY s6-rc.d/ /etc/s6-overlay/s6-rc.d/

# IRRd
# renovate: datasource=pypi depName=irrd versioning=pep440
ARG IRRD_VERSION="4.4.4"
USER root
RUN adduser --gecos '' --disabled-password irrd \
    && mkdir -p /opt/irrd \
    && chown -R irrd:irrd /opt/irrd
USER irrd
WORKDIR /opt/irrd
COPY --chown=irrd:irrd --chmod=600 requirements-irrd.txt /opt/irrd/requirements.txt
ENV PIPX_BIN_DIR=/opt/irrd/bin
RUN pip install --requirement requirements.txt \
    && pipx ensurepath \
    && pipx install irrd==${IRRD_VERSION}
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.sh /opt/irrd/init-irrd.sh
COPY --chown=irrd:irrd --chmod=700 ./scripts/init-irrd.py /opt/irrd/init-irrd.py

# IRR Explorer
# renovate: datasource=pypi depName=poetry versioning=pep440
ARG POETRY_VERSION="2.1.3"
USER root
RUN adduser --gecos '' --disabled-password irrexplorer \
    && mkdir -p /opt/irrexplorer \
    && chown -R irrexplorer:irrexplorer /opt/irrexplorer \
    && npm install --global yarn
USER irrexplorer
WORKDIR /opt/irrexplorer
COPY --chown=irrexplorer:irrexplorer --chmod=600 requirements-irrexplorer.txt /opt/irrexplorer/requirements.txt
ENV PIPX_BIN_DIR=/opt/irrexplorer/bin
ENV IRRE_SOURCE_SHA1SUM=afdb4d0fd9e1c24ed816e45e5030f01d60e26781
ADD --chown=irrexplorer:irrexplorer https://github.com/NLNOG/irrexplorer/archive/aeb6f6bf6ba62c95ce196726149886b4aadfb333.tar.gz /tmp/irrexplorer.tar.gz
RUN echo "${IRRE_SOURCE_SHA1SUM}  /tmp/irrexplorer.tar.gz" | sha1sum -c - \
    && tar -xz --strip-components=1 --file="/tmp/irrexplorer.tar.gz" \
    && pip install --requirement requirements.txt \
    && pipx ensurepath \
    && pipx install poetry==${POETRY_VERSION} \
    && /opt/irrexplorer/bin/poetry install
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.sh /opt/irrexplorer/init-irrexplorer.sh
COPY --chown=irrexplorer:irrexplorer --chmod=700 ./scripts/init-irrexplorer.py /opt/irrexplorer/init-irrexplorer.py
USER root

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

# Cleanup
RUN apt-get --yes --autoremove remove \
    build-essential \
    cargo \
    curl \
    jq \
    xz-utils \
    && apt-get clean

# Set expose ports and entrypoint
EXPOSE 43/tcp
EXPOSE 8000/tcp
ENTRYPOINT ["/init"]

LABEL org.opencontainers.image.authors="MattKobayashi <matthew@kobayashi.au>"
