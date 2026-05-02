#!/bin/bash
# Wrapper around afk.sh that logs all output to <repo>/bin/.afk/logs/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOG_DIR="$(pwd)/bin/.afk/logs"
mkdir -p "$LOG_DIR"
RUN_LOG="$LOG_DIR/run_$(date +%Y%m%dT%H%M%S).log"

bash "$SCRIPT_DIR/afk.sh" "$@" 2>&1 | tee -a "$RUN_LOG"
