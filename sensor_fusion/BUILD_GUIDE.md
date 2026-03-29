# AWS Ada Server Build Guide

This guide explains how to build and run the Ada sensor fusion server for capturing data from iPhone and Samsung devices.

## Quick Start

### Option 1: Build and Test Automatically
```bash
# Build the server (will fallback to simplified version if AWS deps missing)
./build_aws_server.sh

# Test data capture
./test_capture.sh
```

### Option 2: Use Python Server (Recommended for Testing)
```bash
# Start Python server
python3 verify_phones_8080.py

# In another terminal, test data capture
python3 test_data_capture.py
```

## Build Scripts

### build_aws_server.sh
Main build script with multiple options:

```bash
# Auto mode: Try AWS build, fallback to simplified version
./build_aws_server.sh

# Force full AWS build (requires system dependencies)
./build_aws_server.sh --full

# Build simplified version only
./build_aws_server.sh --simple

# Clean build artifacts
./build_aws_server.sh --clean

# Show help
./build_aws_server.sh --help
```

### test_capture.sh
Test script for data capture:

```bash
# Full test cycle (start server, test data, check output)
./test_capture.sh

# Start server only and keep running
./test_capture.sh --start-only

# Test data capture only (server must be running)
./test_capture.sh --test-only

# Check generated output files only
./test_capture.sh --check-only

# Use Python server instead of Ada
./test_capture.sh --python
```

## System Dependencies

For full AWS Ada server, you need:

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y libgmp-dev libssl-dev gnat gprbuild make
```

### RHEL/CentOS:
```bash
sudo yum install -y gmp-devel openssl-devel gcc-gnat gprbuild make
```

### Fedora:
```bash
sudo dnf install -y gmp-devel openssl-devel gcc-gnat gprbuild make
```

### Arch Linux:
```bash
sudo pacman -S --needed gmp openssl gcc-ada gprbuild make
```

## Server Options

### 1. Full AWS Server
- **Location**: `bin/sensor_fusion`
- **Features**: Complete HTTP server with JSON parsing
- **Dependencies**: AWS Ada library, system crypto libraries
- **Status**: Requires dependency resolution

### 2. Simplified Server
- **Location**: `bin/simple_sensor_fusion`
- **Features**: Demo version, creates sample data
- **Dependencies**: GNAT compiler only
- **Status**: Always builds successfully

### 3. Python Server
- **Location**: `verify_phones_8080.py`
- **Features**: Full HTTP server, tested and working
- **Dependencies**: Python 3, requests library
- **Status**: Recommended for testing

## Data Capture Testing

### Test Data Format
The server expects JSON in this format:

```json
{
  "deviceId": "iPhone11-Test",
  "platform": "iOS",
  "payload": [
    {
      "ts": 1640995200000000000,
      "path": "accelerometer",
      "values": [0.1, 0.2, 9.8]
    }
  ]
}
```

### Running Tests
```bash
# Make sure server is running, then:
python3 test_data_capture.py
```

### Output Files
- **Format**: CSV files with timestamp, platform, device_id, sensor_type, x, y, z
- **Naming**: `iphone_[deviceid]_[timestamp].csv` or `samsung_[deviceid]_[timestamp].csv`
- **Location**: Current directory

## Troubleshooting

### AWS Build Fails
1. Install system dependencies (see above)
2. Try `./build_aws_server.sh --full`
3. If still fails, use simplified version or Python server

### Server Won't Start
1. Check port 8080 is free: `netstat -tlnp | grep :8080`
2. Kill conflicting processes
3. Try simplified version: `./bin/simple_sensor_fusion`

### Data Not Captured
1. Verify server is running: `curl http://localhost:8080/`
2. Check test script: `python3 test_data_capture.py`
3. Review server logs for JSON parsing errors

### Missing Dependencies
```bash
# Check what's missing
alr update
alr with --force

# Install Python dependencies
pip3 install requests
```

## Development Workflow

### For Strapped Experiment (Plan Step 1):
1. **Setup**: Use Python server for initial data collection
   ```bash
   python3 verify_phones_8080.py
   ```

2. **Data Collection**: Run strapped experiment with both phones
   - Install Sensor Logger app on iPhone 11 and Samsung S10e
   - Configure HTTP push to your machine IP:8080
   - Strap phones together and record for 60 seconds

3. **Analysis**: Check generated CSV files
   ```bash
   ./test_capture.sh --check-only
   ```

### For Ada Development:
1. **Build**: Try to get AWS server working
   ```bash
   ./build_aws_server.sh --full
   ```

2. **Test**: Verify data capture
   ```bash
   ./test_capture.sh
   ```

3. **Debug**: Check server output for parsing issues

## File Structure

```
sensor_fusion/
├── build_aws_server.sh     # Main build script
├── test_capture.sh         # Test data capture
├── test_data_capture.py    # Python test client
├── verify_phones_8080.py   # Python HTTP server
├── bin/
│   ├── sensor_fusion       # Full AWS server (if build succeeds)
│   └── simple_sensor_fusion # Simplified demo server
├── src/                    # Ada source code
├── *.csv                   # Generated sensor data files
└── sample_sensor_data.csv  # Example data file
```

## Next Steps

1. **Immediate**: Use Python server for strapped experiment data collection
2. **Short-term**: Resolve AWS dependencies for full Ada server
3. **Long-term**: Implement sensor fusion algorithms in Ada/SPARK

## Support

For issues:
1. Check this guide first
2. Run `./build_aws_server.sh --help` and `./test_capture.sh --help`
3. Review server output logs for specific error messages
