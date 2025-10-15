# Development container for MCP servers repo
# Provides Node.js and Python tooling required by the mixed-language workspaces.

FROM ghcr.io/astral-sh/uv:python3.12-bookworm

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

WORKDIR /workspace

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=0 \
    NODE_ENV=development \
    PATH="/workspace/node_modules/.bin:${PATH}"

CMD ["sleep", "infinity"]
