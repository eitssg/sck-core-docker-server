#!/bin/bash

# filepath: service.sh
# Service script to run FastAPI server with auto-restart capability

set -e

# Source environment variables
source /home/core/.env
source $VENV_PATH/bin/activate

# Change to the API directory
cd /home/core/sck/sck-core-api

# Set default values for environment variables
export HOST=${HOST:-"0.0.0.0"}
export PORT=${PORT:-8000}
export WORKERS=${WORKERS:-4}
export LOG_LEVEL=${LOG_LEVEL:-"info"}
export RELOAD=${RELOAD:-"false"}
export ACCESS_LOG=${ACCESS_LOG:-"true"}

# Log directory setup - UPDATED PATH
LOG_DIR="/opt/core/logs"
mkdir -p $LOG_DIR

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_DIR/service.log
}

# Function to start FastAPI server
start_server() {
    log_message "Starting FastAPI server..."
    log_message "Host: $HOST, Port: $PORT, Workers: $WORKERS"
    log_message "Log Level: $LOG_LEVEL, Reload: $RELOAD"
    
    # Determine if we're in development or production mode
    if [ "$RELOAD" = "true" ]; then
        # Development mode with auto-reload
        log_message "Starting in DEVELOPMENT mode with auto-reload"
        uvicorn main:app \
            --host $HOST \
            --port $PORT \
            --log-level $LOG_LEVEL \
            --reload \
            --reload-dir /home/core/sck \
            --access-log \
            2>&1 | tee -a $LOG_DIR/uvicorn.log
    else
        # Production mode with Gunicorn
        log_message "Starting in PRODUCTION mode with Gunicorn"
        gunicorn main:app \
            --bind $HOST:$PORT \
            --workers $WORKERS \
            --worker-class uvicorn.workers.UvicornWorker \
            --log-level $LOG_LEVEL \
            --access-logfile $LOG_DIR/access.log \
            --error-logfile $LOG_DIR/error.log \
            --log-file $LOG_DIR/gunicorn.log \
            --capture-output \
            --enable-stdio-inheritance \
            2>&1 | tee -a $LOG_DIR/service.log
    fi
}

# Function to handle graceful shutdown
cleanup() {
    log_message "Received shutdown signal, stopping FastAPI server..."
    kill -TERM $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    log_message "FastAPI server stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Main loop with auto-restart
RESTART_DELAY=5
MAX_RETRIES=10
RETRY_COUNT=0

log_message "FastAPI Service Manager starting..."
log_message "Auto-restart enabled with $RESTART_DELAY second delay"
log_message "Maximum retries: $MAX_RETRIES"

while true; do
    log_message "Starting FastAPI server (attempt $((RETRY_COUNT + 1)))"
    
    # Start server in background
    start_server &
    SERVER_PID=$!
    
    # Wait for the server process
    wait $SERVER_PID
    EXIT_CODE=$?
    
    log_message "FastAPI server exited with code: $EXIT_CODE"
    
    # If exit code is 0, it was a graceful shutdown
    if [ $EXIT_CODE -eq 0 ]; then
        log_message "Graceful shutdown detected, exiting service manager"
        break
    fi
    
    # Increment retry counter
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Check if we've exceeded max retries
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        log_message "Maximum retry attempts ($MAX_RETRIES) reached, giving up"
        exit 1
    fi
    
    # Log the restart attempt
    log_message "Server crashed (exit code: $EXIT_CODE), restarting in $RESTART_DELAY seconds..."
    log_message "Retry attempt: $RETRY_COUNT / $MAX_RETRIES"
    
    # Wait before restarting
    sleep $RESTART_DELAY
    
    # Exponential backoff: double the delay up to 60 seconds
    if [ $RESTART_DELAY -lt 60 ]; then
        RESTART_DELAY=$((RESTART_DELAY * 2))
    fi
done

log_message "FastAPI Service Manager exiting"