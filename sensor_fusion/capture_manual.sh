#!/bin/bash

# Manual Sensor Data Capture Script
# Simulates Sensor Logger app data format

echo "=== Manual Sensor Data Capture ==="
echo "Target: http://10.0.0.146:8080/data"
echo ""

# Simulate iPhone accelerometer data
echo "Sending iPhone accelerometer data..."
curl -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "time": 1640995200000000000,
           "sensor": "accelerometer", 
           "x": 0.123, "y": -0.456, "z": 9.81,
           "deviceId": "iPhone-11-1",
           "platform": "iOS"
         },
         {
           "time": 1640995200000100000,
           "sensor": "accelerometer", 
           "x": 0.125, "y": -0.458, "z": 9.82,
           "deviceId": "iPhone-11-1",
           "platform": "iOS"
         }
       ]
     }'

echo ""
echo ""

# Simulate Samsung accelerometer data  
echo "Sending Samsung accelerometer data..."
curl -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "time": 1640995200000000000,
           "sensor": "accelerometer", 
           "x": -0.123, "y": 0.456, "z": -9.81,
           "deviceId": "Samsung-S10e-1",
           "platform": "Android"
         },
         {
           "time": 1640995200000100000,
           "sensor": "accelerometer", 
           "x": -0.125, "y": 0.458, "z": -9.82,
           "deviceId": "Samsung-S10e-1", 
           "platform": "Android"
         }
       ]
     }'

echo ""
echo ""

# Simulate gyroscope data
echo "Sending gyroscope data..."
curl -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "time": 1640995200000000000,
           "sensor": "gyroscope",
           "x": 0.01, "y": 0.02, "z": -0.03,
           "deviceId": "iPhone-11-1",
           "platform": "iOS"
         }
       ]
     }'

echo ""
echo "=== Capture Complete ==="
echo "Check the server output to verify data reception"
