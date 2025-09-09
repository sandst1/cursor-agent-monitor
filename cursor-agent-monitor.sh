#!/bin/bash

# Real-time monitoring wrapper for cursor-agent

# Configuration
TIMEOUT=300  # Maximum time to wait
POLL_INTERVAL=1  # How often to check (seconds)

# Create a temporary file for accumulating output
OUTPUT_FILE=$(mktemp)
trap "rm -f $OUTPUT_FILE" EXIT

echo "Starting cursor-agent with monitoring..."

# Start cursor-agent with output going to both stdout and our temp file
cursor-agent "$@" 2>&1 | tee "$OUTPUT_FILE" &
CURSOR_PID=$!

echo "Cursor-agent PID: $CURSOR_PID"

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
        echo "Timeout reached ($TIMEOUT seconds), killing process..."
        kill -TERM $CURSOR_PID 2>/dev/null
        sleep 1
        kill -KILL $CURSOR_PID 2>/dev/null
        break
    fi
    
    # Check for completion markers in output
    if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        if grep -q '"type":"result","subtype":"success"' "$OUTPUT_FILE" 2>/dev/null || \
           grep -q '"type":"result","subtype":"error"' "$OUTPUT_FILE" 2>/dev/null; then
            echo "Found completion marker, terminating process..."
            found_result=true
            kill -TERM $CURSOR_PID 2>/dev/null
            sleep 0.5
            kill -KILL $CURSOR_PID 2>/dev/null
            break
        fi
    fi
    
    echo "Monitoring... (${elapsed}s elapsed)"
    sleep $POLL_INTERVAL
done

# Wait a bit more for any final output
sleep 0.5

echo ""
if [ "$found_result" = true ]; then
    echo "✓ Cursor-agent completed successfully and was terminated."
else
    echo "✓ Cursor-agent process ended."
fi
