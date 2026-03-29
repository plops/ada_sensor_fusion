#!/bin/bash

# Test Updated Ada Server with Port Conflict Detection
echo "=== Testing Updated Ada Server ==="
echo ""

# First, let's try to compile the updated version
echo "Attempting to compile updated Ada server..."
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion

# Try simple compilation test
echo "Testing syntax with gnatmake..."
gnatmake -c src/sensor_fusion.adb -gnat2022 -Isrc/ 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Syntax check passed"
else
    echo "✗ Syntax errors found - fix needed"
fi

echo ""
echo "Note: Full compilation still requires dependency resolution"
echo "The updated code includes:"
echo "- Port conflict detection"
echo "- Clear error messages" 
echo "- Process identification"
echo "- GNAT.OS_Lib integration"
