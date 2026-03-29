[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/plops/ada_sensor_fusion)

# Ada Sensor Fusion

A formally verified, multi-device sensor fusion engine written in **Ada/SPARK**. It receives raw sensor data streamed over HTTP from the [Sensor Logger](https://tszheichoi.com/sensorlogger) app (iOS & Android), normalizes cross-platform coordinate systems, and fuses orientation data using a provably correct Madgwick quaternion filter.

## Features

- **SPARK Formal Verification** — Safety-critical math (quaternion operations, interpolation, normalization) is proven free of runtime errors and functionally correct via GNATprove contracts
- **Multi-Device Fusion** — Simultaneously fuses data from iPhone and Android devices onto a uniform time grid
- **iOS / Android Normalization** — Automatically corrects coordinate system and unit disparities between platforms (e.g. g → m/s², axis inversion)
- **Madgwick Orientation Filter** — SPARK-verified quaternion filter integrating Accelerometer, Gyroscope, and Magnetometer
- **SLERP Interpolation** — Spherical linear quaternion interpolation for smooth multi-device time alignment
- **Real-Time HTTP Reception** — AWS Ada-based HTTP server (port 8080) receiving 1-second JSON batches from Sensor Logger
- **Bounded Memory** — No dynamic allocation; uses static ring buffers for predictable, provable memory usage
- **Validated on Real Data** — Tested with 1,507 live sensor readings from strapped iPhone 11 + Samsung S10e

---

## Architecture

```
Phones (Sensor Logger App)
        │  HTTP POST /data (JSON)
        ▼
┌──────────────────┐
│  HTTP Server     │  (Ada / AWS)
│  ultra_simple    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐     ┌──────────────────────┐
│ Platform         │────▶│ Sensor_Fusion_Engine │
│ Normalizer       │     │ (Madgwick, SPARK)    │
│ (SPARK)          │     └──────────┬───────────┘
└──────────────────┘                │
                                    ▼
                         ┌──────────────────────┐
                         │ Alignment Engine     │
                         │ (SLERP, SPARK)       │
                         └──────────────────────┘
```

---

## Project Structure

```
ada_sensor_fusion/
├── plan/                        # Project planning documents
│   ├── 02prompt.md
│   └── 03implementation_plan.md
├── scripts/
│   └── setup-sdk.sh             # Ada SDK environment setup
└── sensor_fusion/               # Main Ada/SPARK source
    ├── src/
    │   ├── sensors.ads/.adb             # SPARK pure data types & validation
    │   ├── math_library.ads/.adb        # Quaternion ops, Madgwick filter
    │   ├── platform_normalizer.ads/.adb # iOS/Android coordinate corrections
    │   ├── alignment_engine.ads/.adb    # Time sync & SLERP interpolation
    │   ├── sensor_fusion_engine.ads/.adb
    │   ├── phone_sensor_integration.ads/.adb
    │   └── ultra_simple_server.adb      # HTTP data ingestion server
    ├── build_aws_server.sh
    ├── BUILD_GUIDE.md
    └── USAGE_GUIDE.md
```

---

## Prerequisites

- **GNAT** Ada compiler (AdaCore Community Edition recommended)
- **GPRBuild**
- **Alire** (Ada Library Repository package manager)
- **GNATprove** (for SPARK verification)
- **Python 3** + `requests` (optional, for test scripts)

### Install System Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get install -y libgmp-dev libssl-dev gnat gprbuild make
```

**Fedora:**
```bash
sudo dnf install -y gmp-devel openssl-devel gcc-gnat gprbuild make
```

**Arch Linux:**
```bash
sudo pacman -S --needed gmp openssl gcc-ada gprbuild make
```

### Configure the Ada SDK

```bash
source scripts/setup-sdk.sh
# Or set your SDK path:
export ADA_SDK_PATH=/path/to/your/ada-sdk
source scripts/setup-sdk.sh
```

### Install Ada Dependencies via Alire

```bash
cd sensor_fusion
alr with aws gnatcoll
alr build
```

---

## Quick Start

### 1. Build the HTTP Server

```bash
cd sensor_fusion
gprbuild -P ultra_simple.gpr
./bin/ultra_simple_server
```

The server listens on **port 8080** for JSON POST requests from the Sensor Logger app.

### 2. Configure Sensor Logger

In the Sensor Logger app on your phone(s):
- Set **Server URL** to `http://<YOUR_IP>:8080`
- Enable sensors: Accelerometer, Gyroscope, Magnetometer
- Leave **"Standardise Units & Frames" OFF** (normalization is done in Ada)

### 3. Run Tests & Demos

```bash
# System status overview
gprbuild -P fusion_demo.gpr && ./bin/fusion_demo

# Analyze captured real-world data (1,507 readings included)
gprbuild -P quick_phone_test.gpr && ./bin/quick_phone_test

# Test fusion algorithms (interpolation, SLERP, time grids)
gprbuild -P simple_test.gpr && ./bin/simple_alignment_test

# Deep multi-device analysis (strapped phone validation)
gprbuild -P strapped_phones_test.gpr && ./bin/strapped_phones_test
```

---

## Core SPARK Packages

| Package | Description |
|---|---|
| `Sensors` | Bounded sensor data types (`Acceleration`, `Angular_Velocity`, etc.) with SPARK validation contracts |
| `Math_Library` | Quaternion arithmetic, Madgwick filter, safe sqrt/divide, delta-time utilities |
| `Platform_Normalizer` | Converts iOS (g units, left-handed) to Android (m/s², right-handed) coordinate frame |
| `Alignment_Engine` | Linear & SLERP quaternion interpolation, time grid generation, relative rotation computation |
| `Sensor_Fusion_Engine` | Multi-device orientation tracking (up to 10 simultaneous devices) |

### JSON Data Format

The HTTP server expects the following format from Sensor Logger:

```json
{
  "deviceId": "iPhone11-abc123",
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

Output is saved as CSV: `timestamp, platform, device_id, sensor_type, x, y, z`

---

## Formal Verification

SPARK is applied at two levels:

- **Silver (Absence of Run-Time Errors)** — universally applied; no division by zero, no buffer overflows, no numeric exceptions
- **Gold (Functional Correctness)** — applied to safety-critical math; e.g. `Normalize` is proven to return a unit quaternion, `Interpolate_Float` is proven to return exact endpoints at boundary timestamps

Run the prover with:

```bash
gnatprove -P sensor_fusion.gpr -j0
```

---

## Performance

| Metric | Value |
|---|---|
| Sensor batch latency | < 50 ms per 1-second window |
| Samples per window | ~100–120 per sensor |
| Orientation precision | Sub-degree |
| Max simultaneous devices | 10 |
| Memory model | Bounded static arrays, no heap allocation |

---

## Roadmap

1. **Extended Kalman Filter (EKF)** — 3D position tracking with GPS + Barometer, with SPARK-proven matrix inversion
2. **Web Dashboard** — Real-time orientation visualization
3. **Cloud Integration** — Remote multi-device data processing
4. **AUnit Test Suite** — Formal unit testing for non-linear trig functions abstracted from SPARK

---

## License

MIT License. Copyright (c) 2024 plops.

