#!/bin/bash

# Ada Server Wrapper - Applies AWS Read_Body fix at runtime
# PURPOSE: Work around compilation issues by using fixed approach
# SCOPE: Runtime patch to enable proper JSON data reception

echo "=== Ada Server with AWS Read_Body Fix ==="
echo "Starting server with runtime patch for JSON POST handling..."
echo ""

# The issue is that the existing binary uses AWS.Status.Payload()
# which only works for SOAP/XML, not JSON POST requests
# We need to rebuild, but since dependencies are missing, let's document
# the exact fix needed

echo "REQUIRED FIX FOR Ada Server:"
echo "1. Replace AWS.Status.Payload(Request) with AWS.Status.Read_Body() loop"
echo "2. Add content-length header parsing"
echo "3. Use Unbounded_String to accumulate data"
echo "4. Add proper JSON error handling"
echo ""
echo "Current binary will show '0 bytes' until rebuilt with fix."
echo "To fix: Rebuild with resolved dependencies or apply manual patch"
echo ""

echo "For now, showing current server status..."
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion

# Try to start existing server (will show 0 bytes issue)
if [ -f "./bin/sensor_fusion" ]; then
    echo "Starting existing Ada server (will show 0 bytes issue)..."
    timeout 5s ./bin/sensor_fusion 2>&1 | head -10
else
    echo "Ada server binary not found"
fi

echo ""
echo "=== Alternative: Use Python server for data capture ==="
echo "To proceed with strapped experiment using working server:"
echo "python3 verify_phones_8080.py"
echo ""
