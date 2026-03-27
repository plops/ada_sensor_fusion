-- SPARK Pure Fusion Engine for Single-Device Sensor Fusion
-- Integrates accelerometer, gyroscope, and magnetometer data

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;
with Ada.Numerics.Elementary_Functions;

package Fusion_Engine is
   
   -- Fusion state for a single device
   type Fusion_State is record
      Current_Quaternion : Math_Library.Quaternion;
      Last_Timestamp     : Sensors.Timestamp_Nano;
      Initialized        : Boolean;
   end record;
   
   -- Initialize fusion state with identity quaternion
   function Initialize_Fusion return Fusion_State;
   
   -- Update fusion state with new sensor reading
   -- Pre: Reading must be valid and timestamp must be increasing
   -- Post: Returns updated fusion state with new orientation estimate
   function Update_Fusion
     (State    : Fusion_State;
      Reading  : Sensors.Sensor_Record) return Fusion_State;
   
   -- Get current orientation as quaternion
   function Get_Orientation (State : Fusion_State) return Math_Library.Quaternion;
   
   -- Get current orientation as Euler angles (roll, pitch, yaw in radians)
   function Get_Orientation_Euler 
     (State : Fusion_State) return Math_Library.Vector_3D;
   
   -- Check if fusion state is properly initialized
   function Is_Initialized (State : Fusion_State) return Boolean;
   
private
   
   -- Convert quaternion to Euler angles
   function Quaternion_To_Euler 
     (Q : Math_Library.Quaternion) return Math_Library.Vector_3D;
   
   -- Update with accelerometer and gyroscope (Madgwick filter)
   function Update_AG
     (State    : Fusion_State;
      Accel    : Sensors.Sensor_Record;
      Gyro     : Sensors.Sensor_Record) return Fusion_State;
   
   -- Extract sensor reading by type from sensor record
   -- (In a real implementation, this would handle multiple sensors per timestamp)
   function Extract_Accelerometer 
     (Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record;
   
   function Extract_Gyroscope 
     (Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record;

end Fusion_Engine;
