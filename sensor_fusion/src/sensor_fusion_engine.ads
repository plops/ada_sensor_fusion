-- SPARK Sensor Fusion Engine
-- Core sensor fusion algorithms with formal verification

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;

package Sensor_Fusion_Engine is
   
   -- Fusion state containing current orientation and metadata
   type Fusion_State is record
      Current_Quaternion : Math_Library.Quaternion;
      Last_Update_Time   : Long_Integer;
      Is_Initialized    : Boolean := False;
      Platform           : Sensors.OS_Type := Sensors.Unknown;
   end record;
   
   -- Initialize fusion engine with first sensor reading
   procedure Initialize
     (State       : out Fusion_State;
      Initial_Q   : in  Math_Library.Quaternion;
      Time_Ns     : in  Long_Integer;
      Platform    : in  Sensors.OS_Type)
     with 
       Post => State.Is_Initialized and
               State.Current_Quaternion = Initial_Q and
               State.Last_Update_Time = Time_Ns and
               State.Platform = Platform;
   
   -- Update fusion state with new sensor readings
   procedure Update
     (State        : in out Fusion_State;
      Accel        : in  Sensors.Vector_3D;
      Gyro         : in  Sensors.Vector_3D;
      Mag          : in  Sensors.Vector_3D;
      Current_Time : in  Long_Integer)
     with
       Pre => State.Is_Initialized and then
             Current_Time >= State.Last_Update_Time,
       Post => State.Last_Update_Time = Current_Time;
   
   -- Get current orientation as quaternion
   function Get_Orientation (State : Fusion_State) return Math_Library.Quaternion
     with 
       Pre => State.Is_Initialized,
       Post => Math_Library.Magnitude_Squared (Get_Orientation'Result) > Math_Library.Epsilon;
   
   -- Get current orientation as rotation matrix
   function Get_Rotation_Matrix (State : Fusion_State) return Math_Library.Matrix_3x3
     with Pre => State.Is_Initialized;
   
   -- Check if fusion state is properly initialized
   function Is_Ready (State : Fusion_State) return Boolean
     with Post => Is_Ready'Result = State.Is_Initialized;
   
private
   
   -- Internal helper to compute initial orientation from accelerometer
   function Compute_Initial_Orientation
     (Accel : Sensors.Vector_3D) return Math_Library.Quaternion
     with 
       Post => Math_Library.Magnitude_Squared (Compute_Initial_Orientation'Result) > Math_Library.Epsilon;
   
   -- Internal helper to validate sensor data
   function Is_Valid_Sensor_Data
     (Accel : Sensors.Vector_3D;
      Gyro  : Sensors.Vector_3D;
      Mag   : Sensors.Vector_3D) return Boolean;

end Sensor_Fusion_Engine;
