#!/bin/bash

# Simple test to show what Sensor Logger data format looks like
echo "Testing JSON parsing with expected Sensor Logger format..."

curl -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "time": 1640995200000000000,
           "sensor": "accelerometer", 
           "x": 0.123, "y": -0.456, "z": 9.81,
           "deviceId": "iPhone-12-1",
           "platform": "iOS"
         },
         {
           "time": 1640995200000000000,
           "sensor": "gyroscope",
           "x": 0.01, "y": 0.02, "z": -0.03,
           "deviceId": "iPhone-12-1", 
           "platform": "iOS"
         }
       ]
     }'

echo ""
echo "If you see 'Data received successfully', the connection works."
echo "The server should show the actual JSON content above."
