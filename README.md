# Cursor Agent Monitor

A real-time monitoring wrapper for `cursor-agent` that provides intelligent process management and automatic termination when tasks complete.

## Features

- **Real-time monitoring**: Tracks cursor-agent execution in real-time
- **Intelligent completion detection**: Automatically detects when cursor-agent completes tasks by monitoring JSON output for success/error markers
- **Timeout protection**: Prevents hung processes with configurable timeout (default: 30 seconds)
- **Clean termination**: Gracefully terminates cursor-agent when completion is detected
- **Live output**: Shows cursor-agent output in real-time while monitoring

## How It Works

The script wraps `cursor-agent` and monitors its output for completion markers:
- `"type":"result","subtype":"success"` - Task completed successfully
- `"type":"result","subtype":"error"` - Task completed with error

When these markers are detected, the script automatically terminates cursor-agent, preventing it from continuing to run indefinitely.

## Usage

```bash
./cursor-agent-monitor.sh [cursor-agent options] "your prompt"
```

### Example

```bash
./cursor-agent-monitor.sh --model sonnet-4 -p --output-format json "write a python function that calculates the median of an array"
```

This command will:
1. Start cursor-agent with the specified options
2. Monitor the output in real-time
3. Automatically terminate when the snake game is complete
4. Show monitoring status every second

### Configuration

You can modify these variables at the top of the script:

```bash
TIMEOUT=30        # Maximum time to wait (seconds)
POLL_INTERVAL=1   # How often to check for completion (seconds)
```

## Output

The script provides clear feedback:

```
Starting cursor-agent with monitoring...
Cursor-agent PID: 12345
Monitoring... (5s elapsed)
Monitoring... (10s elapsed)
Found completion marker, terminating process...

✓ Cursor-agent completed successfully and was terminated.
```

## Requirements

- `cursor-agent` must be installed and available in PATH
- Bash shell
- Standard Unix utilities (`kill`, `grep`, `tee`, `mktemp`)

## Why Use This?

Without monitoring, `cursor-agent` may continue running indefinitely even after completing tasks. This wrapper ensures:
- Efficient resource usage
- Predictable execution times
- Clean process termination
- Better integration with automation scripts

## Installation

1. Make the script executable:
   ```bash
   chmod +x cursor-agent-monitor.sh
   ```

2. Optionally, add to your PATH for global access:
   ```bash
   cp cursor-agent-monitor.sh /usr/local/bin/cursor-agent-monitor
   ```

## License

This script is provided as-is for monitoring cursor-agent processes.
