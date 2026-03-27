# Sensor Fusion Project Plan (Ada/SPARK)

**To the Implementation AI:** You are tasked with developing a formally verified sensor fusion engine in Ada/SPARK. You will process raw data streamed via HTTP from the Sensor Logger app (iOS and Android), handle unit/coordinate disparities, and perform multi-sensor fusion. Safety, correctness (via SPARK proofs), and modular progression are your top priorities. If you are missing context on how to use a dependency, use the DeepWiki MCP to read the documentation from the repositories listed in `dependencies.md`. When calling compiler or spark proovers, use the threads of this computer (e.g. using option `-j0`).

## 0. Dependencies & Environment Setup ✅ **COMPLETED**

You will use Alire (Ada LIbrary REpository) to manage dependencies and build the project. 

**Instructions for Implementation AI:**
1. ✅ Create a file named `dependencies.md` in the project root...
2. ✅ Initialize the project using Alire: `alr init --bin sensor_fusion`
3. ✅ Add dependencies: `alr with aws gnatcoll`
4. ✅ Setup `gnatformat` for code formatting in your standard workflow. (Tool installed but project conflicts prevent execution - code manually follows Ada style)

---

## 1. Data Acquisition & Experiments (Pre-Implementation)

Before writing the fusion core, you must acquire real-world data and validate the hardware constraints.

**Actionable Steps:**
1. **App Configuration:** Install Sensor Logger on the iPhone 11 and Samsung S10e. Leave "Standardise Units & Frames" **OFF**. Enable HTTP Push targeting your dev machine IP.
2. **Data Collection (The "Strapped" Experiment):** Strap both phones tightly together (screens facing the same way, tops aligned). Start recording on both simultaneously and move them in 3D space for 60 seconds.
3. **Baseline Analysis:** Extract exact median sampling rates and note the `deviceId` and `platform` strings for your normalization logic.

---

## 2. Technical Architecture Blueprint

The system is divided into an **Impure (Ada)** I/O layer and a **Pure (SPARK)** mathematical core.

### Prototype: Pure Layer Structs (`sensors.ads`)
```ada
package Sensors with SPARK_Mode is
   type OS_Type is (Android, iOS);
   
   -- Define strict physical bounds to prevent overflow
   type Sensor_Value is new Float range -100_000.0 .. 100_000.0;
   
   type Vector_3D is record
      X, Y, Z : Sensor_Value;
   end record;
   
   type Sensor_Record is record
      Time_Ns : Long_Integer;
      Values  : Vector_3D;
      Valid   : Boolean;
   end record;

   -- Basic validation function for contracts
   function Is_Valid_Reading (R : Sensor_Record) return Boolean is
      (R.Valid and then R.Values.X in -200.0 .. 200.0); -- e.g., acceptable Accel bounds
end Sensors;
```

---

## 3. Step-by-Step Implementation Strategy

You must complete, format (`gnatformat`), compile, and prove each step before moving to the next.

### Step 1: Basic Data Reception and Validation (Ada + SPARK bounds) ✅ **COMPLETED** / *Reference*
* **Goal:** Receive JSON, parse it, and securely pass it to SPARK structs.
* **Prototype Code (Ada Impure AWS Callback):**
  ```ada
  with AWS.Response;
  with AWS.Status;
  with GNATCOLL.JSON; use GNATCOLL.JSON;
  
  function HTTP_Handler (Request : in AWS.Status.Data) return AWS.Response.Data is
     URI : constant String := AWS.Status.URI (Request);
  begin
     if URI = "/data" and then AWS.Status.Method (Request) = AWS.Status.POST then
        declare
           Body_Str : constant String := AWS.Status.Message_Body (Request);
           JSON_Val : constant JSON_Value := Read (Body_Str);
           Payload  : constant JSON_Array := JSON_Val.Get ("payload");
        begin
           -- Loop through payload, convert to Sensors.Sensor_Record, 
           -- and push to a thread-safe queue for SPARK layer.
           return AWS.Response.Build ("text/plain", "success");
        end;
     end if;
     return AWS.Response.Build (AWS.Messages.S404, "Not Found");
  end HTTP_Handler;
  ```

### Step 2: Single-Device Sensor Fusion
* **Goal:** Implement the core orientation filter (Accelerometer + Gyroscope + Magnetometer).
* **Task:** Write a SPARK-verified Quaternion filter. 
* **Prototype Code (SPARK Quaternion & Contracts):**
  ```ada
  package Math_Library with SPARK_Mode is
     type Quaternion is record
        W, X, Y, Z : Float;
     end record;

     Epsilon : constant Float := 0.00001;

     function Magnitude_Squared (Q : Quaternion) return Float is
       (Q.W**2 + Q.X**2 + Q.Y**2 + Q.Z**2);

     -- The Post condition ensures the math proves the result is a unit quaternion
     function Normalize (Q : Quaternion) return Quaternion
       with Pre  => Magnitude_Squared (Q) > Epsilon,
            Post => abs (Magnitude_Squared (Normalize'Result) - 1.0) < Epsilon * 10.0;
            
     function Update_Filter (Current : Quaternion; Accel, Gyro : Vector_3D; DT : Float) return Quaternion
       with Pre => DT > 0.0 and DT < 0.2; -- Protect against massive time jumps
  end Math_Library;
  ```

### Step 3: Coordinate System Corrections & Validation
* **Goal:** Handle iOS vs. Android disparities based on the documentation.
* **Task:** Implement SPARK coordinate standardization.
* **Prototype Code (SPARK Normalizer):**
  ```ada
  package Platform_Normalizer with SPARK_Mode is
     -- Standardizes all raw inputs to Android (Right-Handed, m/s^2) format
     function Normalize_Accelerometer (Raw : Vector_3D; Platform : OS_Type) return Vector_3D
       with Post => 
         (if Platform = iOS then 
             Normalize_Accelerometer'Result.X = -Raw.X * 9.80665 and
             Normalize_Accelerometer'Result.Y = -Raw.Y * 9.80665 and
             Normalize_Accelerometer'Result.Z = -Raw.Z * 9.80665
          else
             Normalize_Accelerometer'Result = Raw);
  end Platform_Normalizer;
  ```
* **Validation:** Replay the "Strapped" experiment data. Plot/compare the output; the normalized vectors from both phones must overlap perfectly.

### Step 4: Multi-Device Fusion
* **Goal:** Fuse data from iPhone and Samsung simultaneously on a uniform time grid.
* **Task:** Implement a provable interpolation engine.
* **Prototype Code (SPARK Time Interpolation):**
  ```ada
  package Alignment_Engine with SPARK_Mode is
     -- Linear interpolation between two readings to match a Target_Time
     function Interpolate (V1, V2 : Float; T1, T2, Target_T : Long_Integer) return Float
       with Pre  => T2 > T1 and then Target_T >= T1 and then Target_T <= T2,
            Post => (if Target_T = T1 then Interpolate'Result = V1
                     elsif Target_T = T2 then Interpolate'Result = V2);
  end Alignment_Engine;
  ```
* **Validation:** Compute the relative rotation (Difference Quaternion) between the two phones. Since they are strapped together, this relative quaternion should remain constant.

### Step 5: Advanced Fusion with GPS/Barometer
* **Goal:** Extend to 3D position tracking using an Extended Kalman Filter (EKF).
* **Prototype Code (SPARK Safe Matrix Operations):**
  ```ada
  package Kalman_Math with SPARK_Mode is
     type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Float;
     
     function Determinant (M : Matrix_3x3) return Float;
     
     -- Proving inversion requires proving the determinant is not dangerously close to 0
     function Invert (M : Matrix_3x3) return Matrix_3x3
       with Pre => abs (Determinant (M)) > 0.0001;
  end Kalman_Math;
  ```
* **Validation:** Export the computed 3D track as a CSV/KML and compare it against the raw GPS. Ensure vertical altitude is smoothed utilizing the barometer.

---

## 4. Formal Verification Plan

Apply SPARK at the Silver level (Absence of Run-Time Errors) universally, and Gold level (Functional Correctness) for safety-critical math.

1. **Floating Point Safety:** Always define a global `Epsilon`. Use `pragma Assert` or `Pre` conditions to ensure divisors are `> Epsilon` before division to categorically eliminate `Divide_By_Zero` exceptions.
2. **Testing Strategy for Proofs:** For math that GNATprove struggles with natively (e.g., complex non-linear trig functions like `ArcTan` from `Ada.Numerics`), abstract them into isolated functions, use `with Import` or `Assume` in SPARK, but rigorously test them in Ada using `AUnit` (unit testing framework).

---

## 5. Performance Requirements & Real-Time Constraints

Sensor Logger pushes batches roughly every 200ms. To maintain a real-time buffer:
* **Latency:** A 1-second rolling window (containing ~100-120 samples per sensor) must process in **< 50ms**.
* **Memory Handling Prototype:**
  Do not dynamically allocate memory (`new`). Use bounded arrays and a ring buffer approach.
  ```ada
  Max_Samples : constant := 200;
  type Sample_Index is range 1 .. Max_Samples;
  type Sample_Buffer is array (Sample_Index) of Sensor_Record;
  
  type Ring_Buffer is record
     Data  : Sample_Buffer;
     Head  : Sample_Index := 1;
     Count : Natural := 0;
  end record;
  ```
* **Concurrency:** The AWS HTTP receiver must run on a separate task from the SPARK Fusion engine, communicating via a protected object (queue), ensuring the HTTP receiver never blocks.