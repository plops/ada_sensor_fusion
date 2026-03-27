Here is a comprehensive project plan designed for the implementation AI. It includes clear, step-by-step instructions, architectural blueprints, formal verification strategies, and necessary configurations for integrating Ada/SPARK with the Sensor Logger ecosystem.

---

# Sensor Fusion Project Plan (Ada/SPARK)

**To the Implementation AI:** You are tasked with developing a formally verified sensor fusion engine in Ada/SPARK. You will process raw data streamed via HTTP from the Sensor Logger app (iOS and Android), handle unit/coordinate disparities, and perform multi-sensor fusion. Safety, correctness (via SPARK proofs), and modular progression are your top priorities. If you are missing context on how to use a dependency, use the DeepWiki MCP to read the documentation from the repositories listed in `dependencies.md`. When calling compiler or spark proovers, use the threads of this computer (e.g. using option -j0).

## 0. Dependencies & Environment Setup

You will use Alire (Ada LIbrary REpository) to manage dependencies and build the project. 

**Instructions for Implementation AI:**
1. Create a file named `dependencies.md` in the project root with the following exact content. This will allow your DeepWiki MCP to fetch library documentation when needed:
```markdown
# dependencies.md
* Ada Web Server (HTTP I/O): `AdaCore/aws`
* GNAT Component Collection (JSON Parsing): `AdaCore/gnatcoll-core`
* Alire Package Manager: `alire-project/alire`
* SPARK 2014 Formal Verification: `AdaCore/spark2014`
```
2. Initialize the project using Alire: `alr init --bin sensor_fusion`
3. Add dependencies: `alr with aws gnatcoll`
4. Setup `gnatformat` for code formatting in your standard workflow.

---

## 1. Data Acquisition & Experiments (Pre-Implementation)

Before writing the fusion core, you must acquire real-world data and validate the hardware constraints.

**Actionable Steps:**
1. **App Configuration:** Install Sensor Logger on the iPhone 11 and Samsung S10e.
   * **IMPORTANT:** Leave "Standardise Units & Frames" **OFF**. We must prove our coordinate transformations in SPARK.
   * Enable HTTP Push in the settings. Target the IP of your development machine.
2. **Data Collection (The "Strapped" Experiment):** Strap both phones tightly together (screens facing the same way, tops aligned). Start recording on both simultaneously and move them in 3D space for 60 seconds.
3. **Baseline Analysis:** Write a temporary Python script to analyze the JSON dumps.
   * Determine exact median sampling rates for both devices (Expected: ~100Hz for Accelerometer/Gyro).
   * Note the `deviceId` and `platform` metadata for routing logic.

---

## 2. Technical Architecture Blueprint

The system is strictly divided into an **Impure (Ada)** I/O layer and a **Pure (SPARK)** mathematical core.

### A. Impure Layer (Ada)
* **HTTP_Listener:** Uses `AWS` to listen for `POST /data`. Parses JSON arrays.
* **Buffer_Manager:** Groups incoming 200ms HTTP streams into strictly ordered 1-second batch windows.
* **Platform_Normalizer:** Extracts `platform` metadata (iOS vs. Android) to tag the incoming structs for the SPARK layer.

### B. Pure Layer (SPARK)
* **Types & Constraints (`Sensors.Ads`):** Define subtypes with strict ranges (e.g., `type Acceleration is new Float range -100.0 .. 100.0;`). 
* **Math_Library:** Custom-built, formally verified 3D Vector and Quaternion operations.
* **Alignment_Engine:** Interpolates unsynchronized nanosecond-stamped data into a uniform time-series grid.
* **Fusion_Engine:** Implements Madgwick/Mahony or Kalman filter logic.

---

## 3. Step-by-Step Implementation Strategy

You must complete, format (`gnatformat`), compile, and prove each step before moving to the next.

### Step 1: Basic Data Reception and Validation (Ada + SPARK bounds)
* **Goal:** Receive JSON, parse it, and securely pass it to SPARK structs.
* **Task:** Implement the AWS HTTP server. Parse the Sensor Logger JSON payload. Extract nanosecond `time`, `sensor_name`, and `x, y, z`.
* **SPARK Element:** Define the target records in SPARK. Write a data validation function `Is_Valid_Reading (R : Sensor_Record) return Boolean` that ensures values are within physical bounds (e.g., no NaNs, sensible gravity bounds).
* **Validation:** Print out valid, parsed records to the console at 1-second intervals.

### Step 2: Single-Device Sensor Fusion
* **Goal:** Implement the core orientation filter (Accelerometer + Gyroscope + Magnetometer).
* **Task:** Write a SPARK-verified Quaternion-based fusion filter (e.g., Madgwick). Ensure nanosecond timestamps are converted to `delta_t` in seconds for integration.
* **SPARK Element:** Prove Absence of Run-Time Errors (AoRTE) for all matrix/quaternion math. Prove that the quaternion magnitude always equals `1.0` (within a defined floating-point `Epsilon`).
* **Validation:** Feed the raw sensors through your filter. Compare your computed Quaternion against the derived `Orientation` sensor provided in the Sensor Logger batch. Log the error margin.

### Step 3: Coordinate System Corrections & Validation
* **Goal:** Handle iOS vs. Android disparities based on the documentation.
* **Task:** Implement a pure SPARK function: `Normalize_Coordinates (Raw : Vector_3D; Platform : OS_Type) return Vector_3D`.
   * *Rule 1:* iOS Uncalibrated Accelerometer is in `g`. Multiply by `9.80665` to get `m/s^2`.
   * *Rule 2:* iOS Acceleration and Gravity axes must be inverted (`-x, -y, -z`) to match the Android (Right-Handed) inertial standard.
   * *Rule 3:* Handle iOS True North vs. Android Magnetic North yaw offset (estimate declination).
* **SPARK Element:** Define contracts ensuring that after `Normalize_Coordinates`, data from both platforms share the exact same physical range constraints.
* **Validation:** Replay the "Strapped" experiment data. Plot/compare the output; the normalized vectors from both phones must overlap perfectly.

### Step 4: Multi-Device Fusion
* **Goal:** Fuse data from iPhone and Samsung simultaneously.
* **Task:** Implement time-synchronization. Use the Network Time Protocol (NTP) synchronized timestamps from the Sensor Logger JSON. Interpolate the Android 100Hz stream and the iOS 100Hz stream onto a single master 100Hz grid.
* **SPARK Element:** Prove the interpolation function (e.g., Linear interpolation). Ensure `Post` conditions guarantee the interpolated timestamp exactly matches the target grid timestamp.
* **Validation:** Compute the relative rotation (Difference Quaternion) between the two phones. Since they are strapped together, this relative quaternion should remain constant over time despite wild movements.

### Step 5: Advanced Fusion with GPS/Barometer
* **Goal:** Extend to 3D position tracking.
* **Task:** Add `Location` (GPS altitude, speed) and `Barometer` (relative altitude, pressure) to an Extended Kalman Filter (EKF) to calculate smoothed 3D trajectory.
* **SPARK Element:** Matrix inversion is notoriously hard to prove AoRTE due to potential division by zero (singular matrices). You must write `Pre` conditions that check matrix determinant bounds before inversion. 
* **Validation:** Export the computed 3D track as a KML/CSV and compare it against the raw GPS track. Ensure vertical altitude is smoother than raw GPS by utilizing the barometer.

---

## 4. Formal Verification Plan

Apply SPARK at the Silver level (Absence of Run-Time Errors) universally, and Gold level (Functional Correctness) for safety-critical math.

1. **Floating Point Safety:** Define a global `Epsilon` for float comparisons. Use `pragma Assert` to ensure divisors are `> Epsilon` before any division operations to categorically eliminate `Divide_By_Zero` exceptions.
2. **Quaternion Normalization:** 
   ```ada
   function Normalize (Q : Quaternion) return Quaternion
     with Post => abs (Magnitude (Normalize'Result) - 1.0) < Epsilon;
   ```
3. **Data Integrity Contracts:**
   ```ada
   -- Ensure delta_t is valid to prevent integration explosion
   function Integrate_Gyro (Start_Q : Quaternion; Gyro : Vector_3D; DT : Float) return Quaternion
     with Pre => DT > 0.0 and DT < 0.2; -- Max 200ms gap allowed
   ```
4. **Testing Strategy for Proofs:** For code that GNATprove struggles with (e.g., complex non-linear trig functions like `ArcTan`), abstract them into external Ada functions and use `Assume` in SPARK, but rigorously test them in Ada using `AUnit` (unit testing framework).

---

## 5. Performance Requirements & Real-Time Constraints

Sensor Logger pushes batches roughly every 200ms (or at intervals configured by the app). To maintain a real-time buffer:
* **Latency:** The processing of a 1-second rolling window (which contains ~100-120 samples per sensor, ~600 data points total) must complete in **< 50ms**.
* **Memory:** Do not dynamically allocate memory (`new`) in the SPARK fusion loops. Use statically sized arrays (e.g., `type Sample_Array is array (1 .. 200) of Sensor_Record`) representing the maximum possible samples per second. Handle overflow gracefully by dropping the oldest samples if a device over-reports.
* **Concurrency:** The AWS HTTP receiver must run on a separate task from the SPARK Fusion engine, communicating via a protected queue, ensuring the HTTP receiver never blocks while mathematical proofs/fusions are calculating.

**Initialization Command for Implementation AI:**
Begin by reading `dependencies.md` via DeepWiki MCP to understand the GNATCOLL JSON API, setup the Alire project, and start on **Step 1**. Commit to git when Step 1 compiles and proves successfully.