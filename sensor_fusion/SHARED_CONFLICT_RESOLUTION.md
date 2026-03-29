# AWS shared.gpr Conflict Resolution Summary

## Problem: "stupid names like shared"

The error `shared.gpr:7:18: duplicate project name "shared"` occurs because:

1. **AWS Library** defines an abstract project named `Shared` (line 19 in AWS's shared.gpr)
2. **Alire/Build System** tries to import multiple projects that both reference "shared"
3. **GNAT Project System** sees this as a naming conflict

## Root Cause Analysis

```bash
# AWS defines this:
abstract project Shared is
   # ... AWS configuration
end Shared;

# When our project imports AWS, it conflicts with other "shared" projects
with "aws.gpr";  # This imports shared.gpr
# Other dependencies also try to import "shared"
```

## Solutions Implemented

### ✅ Solution 1: Minimal SPARK Build (Working)

**File**: `minimal_sensor_fusion.gpr`
**Status**: ✅ **SUCCESS**

```bash
# Build and test core SPARK components
gprbuild -p -P minimal_sensor_fusion.gpr -j0
./bin/sensor_fusion_minimal
```

**Results**:
- ✓ Sensor validation working
- ✓ Sensor type detection working  
- ✓ Platform detection working

### ✅ Solution 2: Conflict Resolution Scripts

**File**: `fix_shared_conflict.sh`
**Status**: ✅ **Complete**

Creates multiple workaround approaches:
- `local_shared.gpr` - Local shared configuration
- `custom_aws_config.gpr` - Custom AWS configuration
- `build_smart.sh` - Intelligent build script

### ✅ Solution 3: Updated JSON Parsing

**Files**: `http_listener.adb`, `sensors.adb`, `test_data_capture.py`
**Status**: ✅ **Complete**

Updated to handle real Sensor Logger JSON format:
```json
{
  "payload": [
    {
      "name": "accelerometer",
      "values": {"x": 0.1, "y": 0.2, "z": 9.8},
      "accuracy": 3,
      "time": 1640995200000000000
    }
  ]
}
```

## Recommended Development Workflow

### Phase 1: Core SPARK Development (Current)
```bash
# Work on SPARK components without AWS conflicts
./build_smart.sh  # Uses minimal build
./bin/sensor_fusion_minimal  # Test core functionality
```

### Phase 2: Add HTTP Server (Future)
Once core SPARK components are verified:
```bash
# Option A: Resolve AWS dependencies
./build_aws_server.sh --full

# Option B: Use Python server for data capture
python3 verify_phones_8080.py
python3 test_data_capture.py
```

### Phase 3: Integration (Future)
Combine working SPARK core with HTTP server.

## Technical Insights

### Why "shared" is problematic:
1. **Generic Name**: Many libraries use "shared" for common configuration
2. **GNAT Limitations**: Project names must be unique in the dependency tree
3. **Alire Complexity**: Package manager amplifies naming conflicts

### Better Naming Conventions:
- `aws_shared.gpr` instead of `shared.gpr`
- `sensor_fusion_shared.gpr` for our project
- Library-specific prefixes prevent conflicts

### Long-term Solutions:
1. **Library Updates**: AWS should rename to `aws_shared.gpr`
2. **Build System**: Use namespaced imports
3. **Package Management**: Better dependency isolation

## Current Status

- ✅ **Core SPARK Components**: Working and verified
- ✅ **JSON Parsing**: Updated for real Sensor Logger format  
- ✅ **Build Scripts**: Multiple workaround options available
- ⚠️ **AWS HTTP Server**: Blocked by dependency conflicts
- ✅ **Python Alternative**: Working for data capture

## Next Steps

1. **Immediate**: Use minimal build for SPARK development
2. **Short-term**: Use Python server for sensor data capture
3. **Long-term**: Resolve AWS dependencies or create custom HTTP server

The "shared" naming issue is indeed stupid, but we have working workarounds that allow development to continue!
