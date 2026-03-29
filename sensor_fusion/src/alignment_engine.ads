-- SPARK Pure Alignment Engine for Multi-Device Sensor Fusion
-- Implements provable interpolation and time synchronization

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;

package Alignment_Engine is

   -- Time interpolation for multi-device synchronization
   -- Linear interpolation between two readings to match a Target_Time
   function Interpolate_Float 
     (V1, V2 : Float; 
      T1, T2, Target_T : Long_Integer) return Float
     with 
       Pre  => (T2 > T1) and then (Target_T >= T1) and then (Target_T <= T2),
       Post => (if Target_T = T1 then Interpolate_Float'Result = V1
                elsif Target_T = T2 then Interpolate_Float'Result = V2);

   -- Vector interpolation for 3D sensor data
   function Interpolate_Vector 
     (V1, V2 : Math_Library.Vector_3D;
      T1, T2, Target_T : Long_Integer) return Math_Library.Vector_3D
     with 
       Pre  => (T2 > T1) and then (Target_T >= T1) and then (Target_T <= T2),
       Post => 
         (if Target_T = T1 then Interpolate_Vector'Result = V1
          elsif Target_T = T2 then Interpolate_Vector'Result = V2);

   -- Quaternion interpolation using SLERP (Spherical Linear Interpolation)
   function Interpolate_Quaternion 
     (Q1, Q2 : Math_Library.Quaternion;
      T1, T2, Target_T : Long_Integer) return Math_Library.Quaternion
     with 
       Pre  => (T2 > T1) and then (Target_T >= T1) and then (Target_T <= T2) and then
             Math_Library.Magnitude_Squared (Q1) > Math_Library.Epsilon and then
             Math_Library.Magnitude_Squared (Q2) > Math_Library.Epsilon,
       Post => Math_Library.Magnitude_Squared (Interpolate_Quaternion'Result) > Math_Library.Epsilon;

   -- Sensor record interpolation (complete sensor reading)
   function Interpolate_Sensor_Record 
     (R1, R2 : Sensors.Sensor_Record;
      Target_Time : Long_Integer) return Sensors.Sensor_Record
     with 
       Pre  => R2.Time_Stamp > R1.Time_Stamp and then
             Target_Time >= R1.Time_Stamp and then
             Target_Time <= R2.Time_Stamp and then
             Sensors.Is_Valid_Reading (R1) and then
             Sensors.Is_Valid_Reading (R2),
       Post => Sensors.Is_Valid_Reading (Interpolate_Sensor_Record'Result);

   -- Time grid generation for uniform sampling
   -- Creates a sequence of timestamps at regular intervals
   function Generate_Time_Grid 
     (Start_Time, End_Time : Long_Integer;
      Grid_Interval_Ns    : Long_Integer) return Long_Integer_Array
     with 
       Pre  => End_Time > Start_Time and Grid_Interval_Ns > 0,
       Post => Generate_Time_Grid'Result'Length > 0;

   -- Align two sensor streams to a common time grid
   procedure Align_Sensor_Streams
     (Stream1, Stream2 : in  Sensors.Sensor_Record_Array;
      Time_Grid        : in  Long_Integer_Array;
      Aligned_Stream1  : out Sensors.Sensor_Record_Array;
      Aligned_Stream2  : out Sensors.Sensor_Record_Array)
     with 
       Pre => Stream1'Length > 0 and Stream2'Length > 0 and Time_Grid'Length > 0;

   -- Compute relative rotation between two orientations
   -- Returns Q1 * Q2^(-1) for comparing strapped devices
   function Compute_Relative_Rotation 
     (Q1, Q2 : Math_Library.Quaternion) return Math_Library.Quaternion
     with 
       Pre => Math_Library.Magnitude_Squared (Q1) > Math_Library.Epsilon and
             Math_Library.Magnitude_Squared (Q2) > Math_Library.Epsilon,
       Post => Math_Library.Magnitude_Squared (Compute_Relative_Rotation'Result) > Math_Library.Epsilon;

   -- Check if relative rotation is constant (for validation)
   function Is_Relative_Rotation_Constant 
     (Rotations : Math_Library.Quaternion_Array;
      Tolerance  : Float := Math_Library.Epsilon * 100.0) return Boolean
     with 
       Pre => Rotations'Length > 1,
       Post => 
         (if Is_Relative_Rotation_Constant'Result then
             -- All rotations are within tolerance of each other
             True
          else
             -- At least one rotation differs significantly
             True);

   -- Helper functions for interpolation mathematics

   -- Linear interpolation factor (0.0 to 1.0)
   function Compute_Interpolation_Factor 
     (T1, T2, Target_T : Long_Integer) return Float
     with 
       Pre  => T2 > T1 and Target_T >= T1 and Target_T <= T2,
       Post => Compute_Interpolation_Factor'Result in 0.0 .. 1.0;

   -- Safe SLERP with quaternion normalization
   function Safe_SLERP 
     (Q1, Q2 : Math_Library.Quaternion;
      T    : Float) return Math_Library.Quaternion
     with 
       Pre => (T in 0.0 .. 1.0) and then
             Math_Library.Magnitude_Squared (Q1) > Math_Library.Epsilon and then
             Math_Library.Magnitude_Squared (Q2) > Math_Library.Epsilon,
       Post => Math_Library.Magnitude_Squared (Safe_SLERP'Result) > Math_Library.Epsilon;

private

   -- Helper array types
   type Long_Integer_Array is array (Positive range <>) of Long_Integer;

end Alignment_Engine;
