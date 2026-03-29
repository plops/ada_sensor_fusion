-- SPARK Sensor Fusion Engine Implementation
-- Core sensor fusion algorithms with formal verification

pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;

package body Sensor_Fusion_Engine is
   
   -- Initialize fusion engine with first sensor reading
   procedure Initialize
     (State       : out Fusion_State;
      Initial_Q   : in  Math_Library.Quaternion;
      Time_Ns     : in  Long_Integer;
      Platform    : in  Sensors.OS_Type)
   is
   begin
      State.Current_Quaternion := Initial_Q;
      State.Last_Update_Time := Time_Ns;
      State.Is_Initialized := True;
      State.Platform := Platform;
   end Initialize;
   
   -- Update fusion state with new sensor readings
   procedure Update
     (State        : in out Fusion_State;
      Accel        : in  Sensors.Vector_3D;
      Gyro         : in  Sensors.Vector_3D;
      Mag          : in  Sensors.Vector_3D;
      Current_Time : in  Long_Integer)
   is
      DT : constant Float := Math_Library.Compute_Delta_Time (Current_Time, State.Last_Update_Time);
   begin
      if Is_Valid_Sensor_Data (Accel, Gyro, Mag) then
         -- Apply Madgwick filter for sensor fusion
         State.Current_Quaternion := Math_Library.Update_Madgwick 
           (State.Current_Quaternion, Accel, Gyro, DT);
         State.Last_Update_Time := Current_Time;
      end if;
   end Update;
   
   -- Get current orientation as quaternion
   function Get_Orientation (State : Fusion_State) return Math_Library.Quaternion is
   begin
      return State.Current_Quaternion;
   end Get_Orientation;
   
   -- Get current orientation as rotation matrix
   function Get_Rotation_Matrix (State : Fusion_State) return Math_Library.Matrix_3x3 is
   begin
      return Math_Library.To_Rotation_Matrix (State.Current_Quaternion);
   end Get_Rotation_Matrix;
   
   -- Check if fusion state is properly initialized
   function Is_Ready (State : Fusion_State) return Boolean is
   begin
      return State.Is_Initialized;
   end Is_Ready;
   
   -- Internal helper to compute initial orientation from accelerometer
   function Compute_Initial_Orientation
     (Accel : Sensors.Vector_3D) return Math_Library.Quaternion
   is
      -- Normalize accelerometer vector
      Norm_Accel : constant Sensors.Vector_3D := 
        (Accel.X / Math_Library.Magnitude ((Accel.X, Accel.Y, Accel.Z)),
         Accel.Y / Math_Library.Magnitude ((Accel.X, Accel.Y, Accel.Z)),
         Accel.Z / Math_Library.Magnitude ((Accel.X, Accel.Y, Accel.Z)));
      
      -- Compute roll and pitch from accelerometer
      Roll  : constant Float := Ada.Numerics.Elementary_Functions.Arctan (Norm_Accel.Y, Norm_Accel.Z);
      Pitch : constant Float := Ada.Numerics.Elementary_Functions.Arctan 
        (-Norm_Accel.X, 
         Ada.Numerics.Elementary_Functions.Sqrt (Norm_Accel.Y * Norm_Accel.Y + Norm_Accel.Z * Norm_Accel.Z));
      
      -- Convert roll/pitch to quaternion
      Half_Roll  : constant Float := Roll  * 0.5;
      Half_Pitch : constant Float := Pitch * 0.5;
      
      Cos_Roll  : constant Float := Ada.Numerics.Elementary_Functions.Cos (Half_Roll);
      Sin_Roll  : constant Float := Ada.Numerics.Elementary_Functions.Sin (Half_Roll);
      Cos_Pitch : constant Float := Ada.Numerics.Elementary_Functions.Cos (Half_Pitch);
      Sin_Pitch : constant Float := Ada.Numerics.Elementary_Functions.Sin (Half_Pitch);
      
   begin
      return (
        Cos_Roll * Cos_Pitch,
        Sin_Roll * Cos_Pitch,
        Cos_Roll * Sin_Pitch,
        -Sin_Roll * Sin_Pitch
      );
   end Compute_Initial_Orientation;
   
   -- Internal helper to validate sensor data
   function Is_Valid_Sensor_Data
     (Accel : Sensors.Vector_3D;
      Gyro  : Sensors.Vector_3D;
      Mag   : Sensors.Vector_3D) return Boolean
   is
      use type Math_Library.Float;
   begin
      -- Check for reasonable sensor values
      return 
        (abs Accel.X) <= 100.0 and (abs Accel.Y) <= 100.0 and (abs Accel.Z) <= 100.0 and
        (abs Gyro.X)  <= 50.0  and (abs Gyro.Y)  <= 50.0  and (abs Gyro.Z)  <= 50.0 and
        (abs Mag.X)   <= 2000.0 and (abs Mag.Y)   <= 2000.0 and (abs Mag.Z)   <= 2000.0;
   end Is_Valid_Sensor_Data;

end Sensor_Fusion_Engine;
