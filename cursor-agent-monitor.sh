#!/bin/bash

# Real-time monitoring wrapper for cursor-agent

# Configuration
TIMEOUT=300  # Maximum time to wait
POLL_INTERVAL=1  # How often to check (seconds)

# Create a temporary file for accumulating output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE" EXIT

echo "Starting cursor-agent with monitoring..."

# Function to find the worker process PID
find_worker_pid() {
    # Look for the worker-server process that contains cursor-agent path
    ps -eo pid,command | grep -E "cursor-agent.*worker-server" | grep -v grep | awk '{print $1}' | head -1
}

# Function to terminate both cursor-agent and worker processes
terminate_processes() {
    local reason="$1"
    echo "$reason"
    
    # Update worker PID if we haven't found it yet
    if [ -z "$WORKER_PID" ]; then
        WORKER_PID=$(find_worker_pid)
    fi
    
    # Terminate main process
    if kill -0 $CURSOR_PID 2>/dev/null; then
        echo "Terminating cursor-agent process ($CURSOR_PID)..."
        kill -TERM $CURSOR_PID 2>/dev/null
        sleep 1
        kill -KILL $CURSOR_PID 2>/dev/null
    fi
    
    # Terminate worker process
    if [ -n "$WORKER_PID" ] && kill -0 $WORKER_PID 2>/dev/null; then
        echo "Terminating worker process ($WORKER_PID)..."
        kill -TERM $WORKER_PID 2>/dev/null
        sleep 1
        kill -KILL $WORKER_PID 2>/dev/null
    fi
}

# Start cursor-agent with output going to both stdout and our temp file
cursor-agent "$@" 2>&1 | tee "$OUTPUT_FILE" &
CURSOR_PID=$!

echo "Cursor-agent PID: $CURSOR_PID"

# Find the worker process PID (may take a moment to start)
echo "Looking for worker process..."
sleep 2
WORKER_PID=$(find_worker_pid)
if [ -n "$WORKER_PID" ]; then
    echo "Worker process PID: $WORKER_PID"
else
    echo "Warning: Worker process not found initially, will search during monitoring"
fi

# Simple monitoring approach
start_time=$(date +%s)
found_result=false

while true; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    # Check if process is still running
    if ! kill -0 $CURSOR_PID 2>/dev/null; then
        echo "Process $CURSOR_PID has ended naturally"
        # Give a moment for file to be fully written
        sleep 0.3
        break
    fi
    
    # Check timeout
    if [ $elapsed -gt $TIMEOUT ]; then
        terminate_processes "Timeout reached ($TIMEOUT seconds), terminating processes..."
        break
    fi
    
    # Check for completion markers in output
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        if grep -q '"type":"result","subtype":"success"' "$OUTPUT_FILE" 2>/dev/null || \
           grep -q '"type":"result","subtype":"error"' "$OUTPUT_FILE" 2>/dev/null; then
            found_result=true
            terminate_processes "Found completion marker, terminating processes..."
            break
        fi
    fi
    
    sleep $POLL_INTERVAL
done

# Wait a bit more for any final output
sleep 0.5

echo ""
if [ "$found_result" = true ]; then
    echo "✓ Cursor-agent completed successfully and both processes were terminated."
else
    echo "✓ Cursor-agent processes ended."
fi
