#!/bin/bash

# Test Data Capture Script
# PURPOSE: Test sensor data capture from iPhone and Samsung devices
# SCOPE: Complete testing workflow for Ada server

set -e

echo "=== Sensor Data Capture Test ==="
echo "Testing Ada server data capture functionality..."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Function to test server availability
test_server() {
    echo "Testing server availability..."
    
    if curl -s http://localhost:8080/ >/dev/null 2>&1; then
        echo "✓ Server is running on localhost:8080"
        return 0
    else
        echo "✗ Server is not responding on localhost:8080"
        return 1
    fi
}

# Function to start Ada server
start_ada_server() {
    echo "Starting Ada server..."
    
    if [ -f "bin/sensor_fusion" ]; then
        echo "Starting full AWS server..."
        ./bin/sensor_fusion &
        SERVER_PID=$!
        echo "Server PID: $SERVER_PID"
    elif [ -f "bin/simple_sensor_fusion" ]; then
        echo "Starting simplified server (demo mode)..."
        ./bin/simple_sensor_fusion
        echo "Simplified server completed"
        return 0
    else
        echo "✗ No server binary found. Run ./build_aws_server.sh first"
        return 1
    fi
    
    # Wait for server to start
    sleep 2
    
    if test_server; then
        echo "✓ Server started successfully"
        return 0
    else
        echo "✗ Server failed to start"
        if [ ! -z "$SERVER_PID" ]; then
            kill $SERVER_PID 2>/dev/null || true
        fi
        return 1
    fi
}

# Function to stop server
stop_server() {
    if [ ! -z "$SERVER_PID" ]; then
        echo "Stopping server (PID: $SERVER_PID)..."
        kill $SERVER_PID 2>/dev/null || true
        wait $SERVER_PID 2>/dev/null || true
        echo "Server stopped"
    fi
}

# Function to run data capture tests
run_data_tests() {
    echo "Running data capture tests..."
    
    # Check if Python is available
    if ! command -v python3 >/dev/null 2>&1; then
        echo "✗ Python3 not found. Cannot run data tests."
        return 1
    fi
    
    # Check if requests module is available
    if ! python3 -c "import requests" 2>/dev/null 2>&1; then
        echo "Installing requests module..."
        pip3 install requests || {
            echo "✗ Failed to install requests. Please install manually:"
            echo "  pip3 install requests"
            return 1
        }
    fi
    
    # Run the test script
    if [ -f "test_data_capture.py" ]; then
        echo "Running sensor data capture tests..."
        python3 test_data_capture.py
    else
        echo "✗ test_data_capture.py not found"
        return 1
    fi
}

# Function to check generated files
check_output() {
    echo ""
    echo "Checking generated CSV files..."
    
    csv_files=($(ls -1 *.csv 2>/dev/null | head -5))
    
    if [ ${#csv_files[@]} -eq 0 ]; then
        echo "✗ No CSV files found"
        return 1
    else
        echo "✓ Found CSV files:"
        for file in "${csv_files[@]}"; do
            echo "  - $file ($(wc -l < "$file") lines)"
            echo "    First few lines:"
            head -3 "$file" | sed 's/^/      /'
        done
        return 0
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --start-only    Start server and keep it running"
    echo "  --test-only     Test data capture (server must be running)"
    echo "  --check-only    Check output files only"
    echo "  --python        Use Python server instead of Ada"
    echo "  --help          Show this help"
    echo ""
    echo "Default: Full test cycle (start server, test data, check output)"
}

# Main function
main() {
    local mode="full"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --start-only)
                mode="start"
                shift
                ;;
            --test-only)
                mode="test"
                shift
                ;;
            --check-only)
                mode="check"
                shift
                ;;
            --python)
                mode="python"
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    echo "Test mode: $mode"
    echo ""
    
    case $mode in
        "start")
            start_ada_server
            if [ $? -eq 0 ] && [ ! -z "$SERVER_PID" ]; then
                echo ""
                echo "Server is running. Press Ctrl+C to stop."
                echo "Test with: python3 test_data_capture.py"
                trap stop_server EXIT
                wait $SERVER_PID
            fi
            ;;
        "test")
            if test_server; then
                run_data_tests
                check_output
            else
                echo "✗ Server not available. Start server first:"
                echo "  $0 --start-only"
                exit 1
            fi
            ;;
        "check")
            check_output
            ;;
        "python")
            echo "Using Python server for data capture..."
            if [ -f "verify_phones_8080.py" ]; then
                python3 verify_phones_8080.py &
                PYTHON_PID=$!
                sleep 2
                run_data_tests
                check_output
                kill $PYTHON_PID 2>/dev/null || true
            else
                echo "✗ verify_phones_8080.py not found"
                exit 1
            fi
            ;;
        "full")
            echo "Starting full test cycle..."
            
            # Trap to clean up server on exit
            trap stop_server EXIT
            
            if start_ada_server; then
                echo ""
                echo "Server started, running data tests..."
                run_data_tests
                check_output
                echo ""
                echo "✓ Full test cycle completed successfully!"
            else
                echo "✗ Failed to start server"
                exit 1
            fi
            ;;
    esac
    
    echo ""
    echo "=== Test Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Review the generated CSV files"
    echo "2. Use the data for sensor fusion analysis"
    echo "3. Run the strapped experiment with real devices"
    echo ""
}

# Set up trap for cleanup
SERVER_PID=""

# Run main function
main "$@"
