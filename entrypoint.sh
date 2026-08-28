#!/bin/bash
set -e

MAX_WAIT=120
ELAPSED=0

# Create and secure all HiddenServiceDir paths before starting anon
grep "^HiddenServiceDir" /etc/anon/anonrc | awk '{print $2}' | while read -r dir; do
    mkdir -p "$dir"
    chmod 700 "$dir"
done

echo "[agent-anon] Starting Anon Network client..."
rm -f /var/lib/anon/state
rm -f /var/lib/anon/cached-*
anon -f /etc/anon/anonrc &
ANON_PID=$!

# Check if any hidden services are configured in anonrc
if grep -q "^HiddenServiceDir" /etc/anon/anonrc; then
    echo "[agent-anon] Waiting for hidden services to be ready..."

    while true; do
        ALL_READY=true
        while read -r dir; do
            if [ ! -f "${dir}/hostname" ]; then
                ALL_READY=false
                break
            fi
        done < <(grep "^HiddenServiceDir" /etc/anon/anonrc | awk '{print $2}')

        $ALL_READY && break

        sleep 2
        ELAPSED=$((ELAPSED + 2))
        if [ $ELAPSED -ge $MAX_WAIT ]; then
            echo "[agent-anon] ERROR: hidden services not ready after ${MAX_WAIT}s"
            exit 1
        fi
    done

    echo "[agent-anon] ================================================"
    grep "^HiddenServiceDir" /etc/anon/anonrc | awk '{print $2}' | while read -r dir; do
        SERVICE=$(basename "$dir")
        ADDRESS=$(cat "${dir}/hostname")
        echo "[agent-anon] $SERVICE → $ADDRESS"
    done
    echo "[agent-anon] ================================================"
else
    echo "[agent-anon] ================================================"
    echo "[agent-anon] SOCKS5 proxy ready on port 9050"
    echo "[agent-anon] ================================================"
fi

wait $ANON_PID
