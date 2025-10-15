# Development container for MCP servers repo
# Provides Node.js and Python tooling required by the mixed-language workspaces.

FROM ghcr.io/astral-sh/uv:python3.12-bookworm

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USER_NAME=dev

USER root

# Install Node.js 22.x and supporting build tooling
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        ca-certificates \
        curl \
        git \
        git-lfs \
        gnupg \
        unzip \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && git lfs install --system \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user that matches the host UID/GID so mounted files remain writable.
RUN groupadd --gid "${GROUP_ID}" "${USER_NAME}" \
    && useradd --uid "${USER_ID}" --gid "${GROUP_ID}" --create-home "${USER_NAME}" \
    && mkdir -p /workspace/MCP-servers \
    && chown -R "${USER_NAME}":"${USER_NAME}" /workspace

WORKDIR /workspace/MCP-servers

# Copy dependency manifests first so editors benefit from cached layers if they bake dependencies into the image.
COPY package.json package-lock.json ./
COPY src/fetch/pyproject.toml src/fetch/uv.lock /tmp/uv-manifests/fetch/
COPY src/git/pyproject.toml src/git/uv.lock /tmp/uv-manifests/git/
COPY src/time/pyproject.toml src/time/uv.lock /tmp/uv-manifests/time/

USER "${USER_NAME}"

ENV HOME="/home/${USER_NAME}" \
    UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=0 \
    NODE_ENV=development \
    PATH="/workspace/MCP-servers/node_modules/.bin:${PATH}"

CMD ["sleep", "infinity"]
