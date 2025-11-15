# HUD Research Engineer Challenge

Containerized Gogs Git service with VNC/noVNC access.

## Components

- Gogs 0.12.11 (port 3000)
- VNC server (port 5901)
- noVNC web interface (port 6080)
- Firefox ESR
- SQLite database
- Fluxbox window manager

Admin user: `engineer` / `engineer123`

## Quick Start

### Build the Container

```bash
docker buildx build --platform linux/amd64 -t gogs-challenge .
```

### Run the Container

```bash
docker run --platform linux/amd64 -p 6080:6080 --name engineer-submission gogs-challenge
```

### Access

- noVNC: http://localhost:6080
- Gogs: http://localhost:3000 (via Firefox in VNC)

Login: `engineer` / `engineer123`

## Architecture

- Base: Debian 12 Slim
- VNC: TigerVNC (display :1, port 5901)
- Web VNC: noVNC + websockify (port 6080)
- Database: SQLite3


## Helper Scripts

### gogs_login

Verifies admin user exists.

```bash
docker exec gogs-challenge gogs_login
```

Exit codes: 0 (success), 1 (failure)

### gogs_pull_data

Backs up database and repositories to `/gogs/backup/`.

```bash
docker exec gogs-challenge gogs_pull_data
```

### gogs_push_data

Restores data from backup directory.

```bash
docker exec gogs-challenge gogs_push_data
```

## Configuration

### Gogs

Configuration: `gogs/custom/conf/app.ini`

- Offline mode enabled
- SSH disabled
- Registration disabled
- Database: `/gogs/data/gogs.db`
- Repositories: `/gogs/data/repositories`

### VNC

- Display: `:1`
- Port: `5901`
- Resolution: `1280x800`
- Depth: `24-bit`
- Security: None

## First-Time Setup

On first run:

1. Initializes SQLite database
2. Creates admin user (`engineer`)
3. Starts Gogs web service
4. Launches VNC server
5. Starts noVNC

Takes ~8-10 seconds.

## Troubleshooting

Check logs:
```bash
docker logs gogs-challenge
```

Access shell:
```bash
docker exec -it gogs-challenge bash
```

Verify admin user:
```bash
docker exec gogs-challenge gogs_login
```
