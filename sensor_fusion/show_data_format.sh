#!/bin/bash

# Simple data viewer that mimics the Python debug output
# This shows the same format as the Python server for comparison

echo "=== Sensor Data Viewer (Ada-compatible format) ==="
echo "Target: http://10.0.0.146:8080/data"
echo ""

# Show expected data format based on Python capture
echo "Expected data structure from phones:"
echo "{"
echo '  "payload": ['
echo "    {"
echo '      "name": "accelerometer",'
echo '      "values": {'
echo '        "x": -0.016247443854808807,'
echo '        "y": 0.006116135977208614,'
echo '        "z": -0.15204334259033203'
echo "      },"
echo '      "accuracy": 3,'
echo '      "time": 1774655729321004800'
echo "    },"
echo "    ... (1016 items per batch)"
echo "  ]"
echo "}"
echo ""

echo "Key differences from expected plan format:"
echo "1. No 'deviceId' or 'platform' fields"
echo "2. Sensor name is 'name' not 'sensor'"  
echo "3. Values nested under 'values' object"
echo "4. Much larger payload (1016 items vs 2-3 expected)"
echo ""

echo "To update Ada server for this format:"
echo "1. Parse 'name' instead of 'sensor'"
echo "2. Extract values from nested 'values' object"
echo "3. Handle large payloads efficiently"
echo "4. Add device identification from other sources"
echo ""

# Test with sample data
echo "Testing with sample data..."
curl -s -X POST http://10.0.0.146:8080/data \
     -H "Content-Type: application/json" \
     -d '{
       "payload": [
         {
           "name": "accelerometer",
           "values": {"x": 0.123, "y": -0.456, "z": 9.81},
           "accuracy": 3,
           "time": 1774655729321004800
         }
       ]
     }' > /dev/null

echo "Test sent to server. Check server output for details."
