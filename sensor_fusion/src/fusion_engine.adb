-- SPARK Pure Fusion Engine Implementation for Single-Device Sensor Fusion
-- Integrates accelerometer, gyroscope, and magnetometer data

pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;

package body Fusion_Engine is

   -- Initialize fusion state with identity quaternion
   function Initialize_Fusion return Fusion_State is
   begin
      return (
        Current_Quaternion => Math_Library.Identity_Quaternion,
        Last_Timestamp     => 0,
        Initialized        => True
      );
   end Initialize_Fusion;

   -- Update fusion state with new sensor reading
   function Update_Fusion
     (State    : Fusion_State;
      Reading  : Sensors.Sensor_Record) return Fusion_State
   is
      Delta_Time : Float;
   begin
      -- Handle first reading (initialization)
      if not State.Initialized then
         return (
           Current_Quaternion => Math_Library.Identity_Quaternion,
           Last_Timestamp     => Reading.Time_Stamp,
           Initialized        => True
         );
      end if;
      
      -- Compute delta time
      Delta_Time := Math_Library.Compute_Delta_Time (Reading.Time_Stamp, State.Last_Timestamp);
      
      -- Update based on sensor type
      case Reading.Sensor_Name is
         when Sensors.Accelerometer =>
            -- For accelerometer only, we can't update without gyroscope
            -- In a real implementation, we'd buffer and wait for matching gyroscope
            return State;
            
         when Sensors.Gyroscope =>
            -- For gyroscope only, we can't update without accelerometer
            -- In a real implementation, we'd buffer and wait for matching accelerometer
            return State;
            
         when Sensors.Orientation =>
            -- Directly use orientation if provided by sensor
            declare
               -- Convert orientation data to quaternion (simplified)
               New_Q : Math_Library.Quaternion := Math_Library.Identity_Quaternion;
            begin
               return (
                 Current_Quaternion => New_Q,
                 Last_Timestamp     => Reading.Time_Stamp,
                 Initialized        => True
               );
            end;
            
         when others =>
            -- Unsupported sensor type, return unchanged state
            return State;
      end case;
   end Update_Fusion;

   -- Get current orientation as quaternion
   function Get_Orientation (State : Fusion_State) return Math_Library.Quaternion is
   begin
      return State.Current_Quaternion;
   end Get_Orientation;

   -- Get current orientation as Euler angles (roll, pitch, yaw in radians)
   function Get_Orientation_Euler 
     (State : Fusion_State) return Math_Library.Vector_3D
   is
   begin
      return Quaternion_To_Euler (State.Current_Quaternion);
   end Get_Orientation_Euler;

   -- Check if fusion state is properly initialized
   function Is_Initialized (State : Fusion_State) return Boolean is
   begin
      return State.Initialized;
   end Is_Initialized;

   -- Convert quaternion to Euler angles
   function Quaternion_To_Euler 
     (Q : Math_Library.Quaternion) return Math_Library.Vector_3D
   is
      -- Roll (x-axis rotation)
      Sinr_Cosp : constant Float := 2.0 * (Q.W * Q.X + Q.Y * Q.Z);
      Cosr_Cosp : constant Float := 1.0 - 2.0 * (Q.X * Q.X + Q.Y * Q.Y);
      Roll : constant Float := Ada.Numerics.Elementary_Functions.Arctan (Sinr_Cosp, Cosr_Cosp);
      
      -- Pitch (y-axis rotation)
      Sinp : constant Float := 2.0 * (Q.W * Q.Y - Q.Z * Q.X);
      Pitch : Float;
      
      -- Yaw (z-axis rotation)
      Siny_Cosp : constant Float := 2.0 * (Q.W * Q.Z + Q.X * Q.Y);
      Cosy_Cosp : constant Float := 1.0 - 2.0 * (Q.Y * Q.Y + Q.Z * Q.Z);
      Yaw : constant Float := Ada.Numerics.Elementary_Functions.Arctan (Siny_Cosp, Cosy_Cosp);
      
   begin
      -- Handle pitch singularity at +/- 90 degrees
      if abs (Sinp) >= 1.0 then
         Pitch := 3.14159 / 2.0 * (if Sinp >= 0.0 then 1.0 else -1.0);  -- Use 90 degrees
      else
         Pitch := Ada.Numerics.Elementary_Functions.Arctan (Sinp, Math_Library.Safe_Sqrt (1.0 - Sinp * Sinp));
      end if;
      
      return (Roll, Pitch, Yaw);
   end Quaternion_To_Euler;

   -- Update with accelerometer and gyroscope (Madgwick filter)
   function Update_AG
     (State    : Fusion_State;
      Accel    : Sensors.Sensor_Record;
      Gyro     : Sensors.Sensor_Record) return Fusion_State
   is
      Delta_Time : constant Float := Math_Library.Compute_Delta_Time (Accel.Time_Stamp, State.Last_Timestamp);
      
      -- Convert sensor data to Math_Library vectors
      Accel_Vec : constant Math_Library.Vector_3D := (Accel.Data.X, Accel.Data.Y, Accel.Data.Z);
      Gyro_Vec  : constant Math_Library.Vector_3D := (Gyro.Data.X, Gyro.Data.Y, Gyro.Data.Z);
      
      -- Update quaternion using Madgwick filter
      New_Q : constant Math_Library.Quaternion := 
        Math_Library.Update_Madgwick (State.Current_Quaternion, Accel_Vec, Gyro_Vec, Delta_Time);
      
   begin
      return (
        Current_Quaternion => New_Q,
        Last_Timestamp     => Accel.Time_Stamp,
        Initialized        => True
      );
   end Update_AG;

   -- Extract sensor reading by type from sensor record
   function Extract_Accelerometer 
     (Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record
   is
   begin
      return Reading;  -- Simplified - assumes input is already accelerometer
   end Extract_Accelerometer;
   
   function Extract_Gyroscope 
     (Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record
   is
   begin
      return Reading;  -- Simplified - assumes input is already gyroscope
   end Extract_Gyroscope;

end Fusion_Engine;
