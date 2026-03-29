-- SPARK Sensor Fusion Main Program
-- Step 2: Single-Device Sensor Fusion

pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Exceptions;
with Sensors;
with Math_Library;
with Sensor_Fusion_Engine;

procedure Sensor_Fusion_Main is
   
   use Ada.Text_IO;
   
   -- Test data for sensor fusion
   Test_State : Sensor_Fusion_Engine.Fusion_State;
   
   -- Sample sensor readings (accelerometer pointing up, no rotation)
   Sample_Accel : constant Sensors.Vector_3D := (0.0, 0.0, 9.81);
   Sample_Gyro  : constant Sensors.Vector_3D := (0.0, 0.0, 0.0);
   Sample_Mag   : constant Sensors.Vector_3D := (0.0, 0.0, 0.0);
   
   -- Initial orientation (identity quaternion)
   Initial_Q : constant Math_Library.Quaternion := Math_Library.Identity_Quaternion;
   
begin
   Put_Line ("=== SPARK Sensor Fusion Engine Test ===");
   Put_Line ("Step 2: Single-Device Sensor Fusion");
   Put_Line ("");
   
   -- Initialize fusion engine
   Put_Line ("Initializing fusion engine...");
   Sensor_Fusion_Engine.Initialize 
     (State       => Test_State,
      Initial_Q   => Initial_Q,
      Time_Ns     => 1640995200000000000,
      Platform    => Sensors.Android);
   
   Put_Line ("✓ Fusion engine initialized");
   Put_Line ("Initial quaternion: " & 
              Math_Library.Quaternion'Image (Sensor_Fusion_Engine.Get_Orientation (Test_State)));
   
   -- Test sensor fusion update
   Put_Line ("");
   Put_Line ("Testing sensor fusion update...");
   Sensor_Fusion_Engine.Update
     (State        => Test_State,
      Accel        => Sample_Accel,
      Gyro         => Sample_Gyro,
      Mag          => Sample_Mag,
      Current_Time => 1640995200000000000 + 200000000);  -- 200ms later
   
   Put_Line ("✓ Sensor fusion update completed");
   Put_Line ("Updated quaternion: " & 
              Math_Library.Quaternion'Image (Sensor_Fusion_Engine.Get_Orientation (Test_State)));
   
   -- Test rotation matrix conversion
   Put_Line ("");
   Put_Line ("Testing rotation matrix conversion...");
   declare
      Rot_Matrix : constant Math_Library.Matrix_3x3 := 
        Sensor_Fusion_Engine.Get_Rotation_Matrix (Test_State);
   begin
      Put_Line ("✓ Rotation matrix computed");
      Put_Line ("Matrix[1,1]: " & Float'Image (Rot_Matrix (1, 1)));
      Put_Line ("Matrix[2,2]: " & Float'Image (Rot_Matrix (2, 2)));
      Put_Line ("Matrix[3,3]: " & Float'Image (Rot_Matrix (3, 3)));
   end;
   
   -- Verify quaternion normalization
   Put_Line ("");
   Put_Line ("Verifying quaternion properties...");
   declare
      Current_Q : constant Math_Library.Quaternion := 
        Sensor_Fusion_Engine.Get_Orientation (Test_State);
      Magnitude : constant Float := Math_Library.Magnitude (Current_Q);
   begin
      Put_Line ("Quaternion magnitude: " & Float'Image (Magnitude));
      if abs (Magnitude - 1.0) < Math_Library.Epsilon * 10.0 then
         Put_Line ("✓ Quaternion is properly normalized");
      else
         Put_Line ("⚠ Quaternion normalization check failed");
      end if;
   end;
   
   Put_Line ("");
   Put_Line ("=== SPARK Sensor Fusion Test Complete ===");
   Put_Line ("Ready for integration with HTTP data reception");
   
exception
   when E : others =>
      Put_Line ("Error: " & Ada.Exceptions.Exception_Message (E));
end Sensor_Fusion_Main;
