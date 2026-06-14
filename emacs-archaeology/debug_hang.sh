#!/usr/bin/env bash

# Exit on error
set -e

# Target binary and arguments
TARGET="./src/emacs_oracle"
ARGS="-batch -eval (message \"hello\")"
LOG_DIR="debug_logs"

mkdir -p "$LOG_DIR"
echo "=== Starting Holomacs Hang Debugger ==="
echo "Logs will be written to the '$LOG_DIR' directory."

# Step 1: Run with valgrind (with a timeout)
echo "1. Running with Valgrind (5s timeout)..."
set +e
timeout 5 valgrind --tool=memcheck --leak-check=full --log-file="$LOG_DIR/valgrind.log" $TARGET -batch -eval "(message \"hello\")" > "$LOG_DIR/valgrind_stdout.log" 2>&1
VALGRIND_STATUS=$?
set -e
echo "Valgrind completed/timed out with exit code: $VALGRIND_STATUS"

# Step 2: Start the process in the background to analyze the hang
echo "2. Launching target process in the background..."
$TARGET -batch -eval "(message \"hello\")" > "$LOG_DIR/target_stdout.log" 2>&1 &
PID=$!
echo "Target process started with PID: $PID"

# Sleep a bit to let it settle into its hang state
sleep 2

# Check if the process is still alive
if kill -0 $PID 2>/dev/null; then
    echo "Process is still running (hung). Analyzing..."

    # Step 3: Attach strace to see if it is looping on system calls
    echo "3. Attaching strace for 3 seconds..."
    set +e
    timeout 3 strace -p $PID -f -o "$LOG_DIR/strace_attach.log"
    set -e
    echo "strace attach finished."

    # Step 4: Attach GDB to get a backtrace of the hang
    echo "4. Attaching GDB to capture backtrace..."
    set +e
    gdb -p $PID -batch \
        -ex "set height 0" \
        -ex "thread apply all bt full" \
        -ex "detach" \
        -ex "quit" > "$LOG_DIR/gdb_backtrace.log" 2>&1
    set -e
    echo "GDB backtrace captured."

    # Step 5: Clean up and kill the process
    echo "5. Killing the hung process (PID: $PID)..."
    kill -9 $PID 2>/dev/null || true
    echo "Hung process terminated."
else
    echo "Target process exited prematurely. Check '$LOG_DIR/target_stdout.log'."
fi

echo "=== Debug Analysis Complete ==="
echo "Check the following files in '$LOG_DIR':"
ls -la "$LOG_DIR"
