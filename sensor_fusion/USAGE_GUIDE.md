# Ada Sensor Fusion - Usage Guide

## 🚀 Quick Start Commands

### 1. Start the HTTP Server (Receives Phone Data)
```bash
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion
gprbuild -P ultra_simple.gpr
./bin/ultra_simple_server
```
**What it does**: Starts HTTP server on port 8080 to receive JSON from phones
**Expected output**: Server listening messages and received data confirmations

### 2. Test with Real Phone Data (Analyze Captured Data)
```bash
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion
gprbuild -P quick_phone_test.gpr
./bin/quick_phone_test
```
**What it does**: Analyzes the 1,507 sensor readings from your strapped phones
**Expected output**: Device counts, sensor type breakdown, data validation

### 3. Run Complete System Demo
```bash
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion
gprbuild -P fusion_demo.gpr
./bin/fusion_demo
```
**What it does**: Shows complete system status and architecture overview
**Expected output**: All 5 implementation steps marked as COMPLETED

### 4. Test Sensor Fusion Algorithms
```bash
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion
gprbuild -P simple_test.gpr
./bin/simple_alignment_test
```
**What it does**: Demonstrates Step 4 multi-device alignment algorithms
**Expected output**: Linear interpolation, time grid generation, SLERP concepts

### 5. Validate Multi-Device Data Processing
```bash
cd /home/kiel/stage/ada_sensor_fusion/sensor_fusion
gprbuild -P strapped_phones_test.gpr
./bin/strapped_phones_test
```
**What it does**: Processes real CSV data from strapped iPhone and Samsung
**Expected output**: Device separation, sensor analysis, relative rotation

## 📱 Testing with Real Phones

### Option A: Use Existing Data (Recommended)
Your strapped phone data is already captured in `phone_data_20260329_205511.csv`
- Run `quick_phone_test` to analyze this data
- No phones needed for this test

### Option B: Live Phone Testing
1. **Start Server**: `./bin/ultra_simple_server`
2. **Configure Sensor Logger App** on your phones:
   - Server URL: `http://YOUR_IP:8080`
   - Data format: JSON
   - Sensors: Accelerometer, Gyroscope, Magnetometer
3. **Start Data Collection** on both phones
4. **Wiggle Phones Together** like you did before

## 🔧 Recommended Testing Sequence

### 1. First Time - Validate System
```bash
./bin/fusion_demo          # See system status
./bin/simple_alignment_test  # Test fusion algorithms  
./bin/quick_phone_test      # Check real data
```

### 2. Production - Live Data Collection
```bash
./bin/ultra_simple_server   # Terminal 1: Start server
# Then send phone data to http://localhost:8080
```

### 3. Analysis - Post-Collection
```bash
./bin/strapped_phones_test  # Analyze captured data
./bin/quick_phone_test      # Quick validation
```

## 📊 What Each Program Shows

### `ultra_simple_server`
- **Purpose**: HTTP server for live phone data
- **Use**: When collecting new sensor data
- **Output**: Real-time data reception confirmations

### `fusion_demo`  
- **Purpose**: System status overview
- **Use**: Verify all components are working
- **Output**: 5 implementation steps, architecture diagram

### `quick_phone_test`
- **Purpose**: Fast analysis of captured data
- **Use**: Validate phone data was captured correctly
- **Output**: Device counts, sensor type breakdown

### `simple_alignment_test`
- **Purpose**: Demonstrate fusion algorithms
- **Use**: Understand the mathematical foundations
- **Output**: Interpolation examples, time grids, SLERP concepts

### `strapped_phones_test`
- **Purpose**: Deep analysis of multi-device data
- **Use**: Validate strapped phone fusion capabilities
- **Output**: Device separation, relative rotation analysis

## 🎯 Quick Verification Commands

### Verify Everything Works (2 commands)
```bash
./bin/fusion_demo         # Check system status
./bin/quick_phone_test    # Validate real data
```

### Full System Test (4 commands)  
```bash
./bin/fusion_demo         # System overview
./bin/simple_alignment_test # Algorithm test
./bin/quick_phone_test    # Real data check
./bin/strapped_phones_test # Deep analysis
```

## 📁 Data Files Location

Your captured sensor data is in:
- `phone_data_20260329_205511.csv` - Main strapped phone data (1,507 records)
- Multiple CSV files with timestamps for different capture sessions

## 🔍 Expected Outputs

### Successful Run Indicators:
- ✅ All steps marked "COMPLETED" in fusion_demo
- ✅ Device counts showing > 0 in quick_phone_test  
- ✅ No compilation errors
- ✅ CSV files being read successfully

### Troubleshooting:
- **Connection refused**: Server not running - start ultra_simple_server first
- **File not found**: Wrong directory - ensure you're in sensor_fusion folder
- **Compilation errors**: Run `gprbuild` first to build executables

## 🎮 Start Here

**For immediate results**: Run these 2 commands:
```bash
./bin/fusion_demo
./bin/quick_phone_test
```

**For live testing**: Start with:
```bash
./bin/ultra_simple_server
```

This will show you the complete Ada sensor fusion system in action!
