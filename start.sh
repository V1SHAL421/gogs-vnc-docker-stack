#!/usr/bin/env bash
set -euo pipefail

GOGS_HOME="/gogs"
DB_FILE="$GOGS_HOME/data/gogs.db"

ADMIN_USER="engineer"
ADMIN_PASS="engineer123"
ADMIN_EMAIL="engineer@example.com"

VNC_DISPLAY=":1"
VNC_GEOMETRY="1280x800"
VNC_DEPTH="24"
VNC_PORT="5901"      # 5900 + display number
NOVNC_PORT="6080"

cd "$GOGS_HOME"

# Ensure Gogs uses our custom config
export GOGS_CUSTOM="$GOGS_HOME/custom"

###############################################################################
# (1) FIRST-BOOT SETUP
###############################################################################
if [ ! -f "$DB_FILE" ]; then
    echo "[INIT] No database found. Performing first-time setup..."

    ./gogs web &
    TEMP_GOGS_PID=$!

    echo "[INIT] Waiting for Gogs to initialize..."
    sleep 8

    echo "[INIT] Creating admin user..."
    ./gogs admin create-user \
        --name "$ADMIN_USER" \
        --password "$ADMIN_PASS" \
        --email "$ADMIN_EMAIL" \
        --admin || true

    echo "[INIT] Shutting down temporary Gogs server..."
    if kill -0 "$TEMP_GOGS_PID" 2>/dev/null; then
        kill "$TEMP_GOGS_PID" 2>/dev/null || true
        wait "$TEMP_GOGS_PID" 2>/dev/null || true
    fi

    echo "[INIT] First-time setup complete."
else
    echo "[INIT] Database already exists. Skipping initialization."
fi

###############################################################################
# (2) START GOGS (MAIN INSTANCE, BACKGROUND)
###############################################################################
echo "[START] Starting Gogs..."
./gogs web &
GOGS_PID=$!

###############################################################################
# (3) START VNC SERVER ON :1 (PORT 5901)
###############################################################################
echo "[START] Starting VNC server on display ${VNC_DISPLAY} (port ${VNC_PORT})..."
vncserver "${VNC_DISPLAY}" \
    -geometry "${VNC_GEOMETRY}" \
    -depth "${VNC_DEPTH}" \
    -SecurityTypes None

###############################################################################
# (4) START noVNC + websockify ON PORT 6080 (FOREGROUND)
###############################################################################
echo "[START] Starting noVNC on port ${NOVNC_PORT}, proxying to VNC port ${VNC_PORT}..."
NOVNC_CMD=(websockify --web /usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}")

###############################################################################
# (5) CLEAN SHUTDOWN / SIGNAL HANDLING
###############################################################################
cleanup() {
    echo "[STOP] Caught signal, shutting down services..."

    echo "[STOP] Stopping noVNC/websockify..."
    pkill -f "websockify.*${NOVNC_PORT}" 2>/dev/null || true

    echo "[STOP] Stopping VNC server..."
    vncserver -kill "${VNC_DISPLAY}" 2>/dev/null || true

    echo "[STOP] Stopping Gogs..."
    kill "${GOGS_PID}" 2>/dev/null || true

    exit 0
}

trap cleanup SIGTERM SIGINT

echo "[READY] Gogs running on http://localhost:3000 (inside container)"
echo "[READY] noVNC available at http://localhost:${NOVNC_PORT}"

# Run noVNC in the foreground; container lifetime is tied to this.
"${NOVNC_CMD[@]}"
echo "[EXIT] noVNC/websockify exited; shutting down."
cleanup
