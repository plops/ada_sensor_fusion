#!/bin/bash

# Real-time sensor data simulation
# This shows the exact format Sensor Logger should send

echo "=== Real-time Sensor Data Test ==="
echo "Format: JSON with payload array containing sensor readings"
echo ""

# Send a single reading with detailed output
echo "Sending test data with detailed format..."
curl -v -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "time": 1640995200000000000,
           "sensor": "accelerometer", 
           "x": 0.123, "y": -0.456, "z": 9.81,
           "deviceId": "Test-Device-1",
           "platform": "iOS"
         }
       ]
     }' 2>&1 | grep -E "(> POST|< HTTP|Content-Length|bytes)"

echo ""
echo "To capture from real phones, ensure:"
echo "1. Sensor Logger app HTTP Push URL: http://10.0.0.146:8080/data"
echo "2. 'Standardise Units & Frames' is OFF in app settings"
echo "3. Both phones are connected to the same WiFi network"
echo ""
echo "Then start recording on both phones simultaneously."
