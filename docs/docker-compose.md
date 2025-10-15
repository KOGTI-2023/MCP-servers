# Docker Compose development environment

This repository now ships with a Docker based workflow that provisions all
runtime dependencies for the reference MCP servers.  The goal is to make it
simple to develop or experiment with the servers from editors such as Cursor or
VS Code without having to install Node.js, Python, or `uv` locally.

## Prerequisites

- Docker Desktop or Docker Engine 24+
- Docker Compose v2 (bundled with recent Docker releases)

## Getting started

1. Build the toolbox container. On Linux hosts, export `UID`, `GID`, and
   optionally `USERNAME` beforehand so the non-root user inside the image matches
   your local account and bind-mounted files remain writable:

   ```bash
   export UID=$(id -u)   # Linux only; harmless elsewhere
   export GID=$(id -g)
   export USERNAME=${USER:-dev}
   docker compose build
   ```

2. Launch the long-lived development container:

   ```bash
   docker compose up -d
   ```

   The container is started with a `sleep infinity` command so that editors can
   attach to it (e.g. VS Code "Attach to Container") and tools such as Cursor
   can spawn MCP servers inside it on demand.  A Docker healthcheck waits for
   both Node.js and `uv` to be ready before reporting the container as healthy,
   which keeps editor integrations from attempting to execute MCP servers too
   early.

3. Install the JavaScript workspace dependencies once inside the container:

   ```bash
   docker compose exec dev npm install
   docker compose exec dev npm run build --workspaces
   ```

4. Install Python dependencies for the `uv-based servers` (run each command once):

   ```bash
   docker compose exec dev bash -lc "cd src/fetch && uv sync --frozen"
   docker compose exec dev bash -lc "cd src/git && uv sync --frozen"
   docker compose exec dev bash -lc "cd src/time && uv sync --frozen"
   ```

After the first sync the named Docker volumes declared in
`docker-compose.yml` keep the virtual environments and `node_modules` folders
isolated from your working tree.

## Running MCP servers inside the container

All servers can be executed via `docker compose exec` which preserves standard
input/output so MCP clients can communicate over stdio.  Example commands:

| Server | Command |
| ------ | ------- |
| Everything (stdio) | `docker compose exec -T dev node src/everything/dist/index.js stdio` |
| Everything (SSE) | `docker compose exec -T dev node src/everything/dist/index.js sse` |
| Filesystem | `docker compose exec -T dev node src/filesystem/dist/index.js /workspace/MCP-servers` |
| Memory | `docker compose exec -T dev node src/memory/dist/index.js` |
| Sequential Thinking | `docker compose exec -T dev node src/sequentialthinking/dist/index.js` |
| Fetch | `docker compose exec -T dev uv run --project src/fetch mcp-server-fetch` |
| Git | `docker compose exec -T dev uv run --project src/git mcp-server-git` |
| Time | `docker compose exec -T dev uv run --project src/time mcp-server-time` |

You can replace `-T` with `-it` while experimenting manually.  MCP clients such
as Cursor typically require the non-interactive `-T` flag.

## Cursor (Cline) configuration

Cursor's `cline_mcp_settings.json` file can point at the Docker Compose service
so the editor spawns the servers inside the container.  The snippet below wires
up the most common reference servers.  Adjust the filesystem path argument to
match the directories you want to expose to the AI assistant.

```json
{
  "mcpServers": {
    "everything": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "node",
        "src/everything/dist/index.js",
        "stdio"
      ]
    },
    "filesystem": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "node",
        "src/filesystem/dist/index.js",
        "/workspace/MCP-servers"
      ]
    },
    "memory": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "node",
        "src/memory/dist/index.js"
      ],
      "env": {
        "MEMORY_FILE_PATH": "/workspace/MCP-servers/.mcp/memory.json"
      }
    },
    "sequential-thinking": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "node",
        "src/sequentialthinking/dist/index.js"
      ]
    },
    "fetch": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "uv",
        "run",
        "--project",
        "src/fetch",
        "mcp-server-fetch"
      ]
    },
    "git": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "uv",
        "run",
        "--project",
        "src/git",
        "mcp-server-git"
      ]
    },
    "time": {
      "command": "docker",
      "args": [
        "compose",
        "exec",
        "-T",
        "dev",
        "uv",
        "run",
        "--project",
        "src/time",
        "mcp-server-time"
      ]
    }
  }
}
```

Create the optional `.mcp` directory referenced by the memory server with:

```bash
docker compose exec dev mkdir -p /workspace/MCP-servers/.mcp
```

Feel free to tailor the configuration to match your workflow—for example by
adding additional environment variables or exposing other directories through
the filesystem server.
