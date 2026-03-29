-- SPARK Pure Alignment Engine Implementation for Multi-Device Sensor Fusion
-- Implements provable interpolation and time synchronization

pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;
with Sensors;
with Math_Library;

package body Alignment_Engine is

   -- Linear interpolation factor (0.0 to 1.0)
   function Compute_Interpolation_Factor 
     (T1, T2, Target_T : Long_Integer) return Float
   is
      use type Long_Integer;
   begin
      return Float (Target_T - T1) / Float (T2 - T1);
   end Compute_Interpolation_Factor;

   -- Time interpolation for multi-device synchronization
   function Interpolate_Float 
     (V1, V2 : Float; 
      T1, T2, Target_T : Long_Integer) return Float
   is
      Alpha : constant Float := Compute_Interpolation_Factor (T1, T2, Target_T);
   begin
      return V1 + Alpha * (V2 - V1);
   end Interpolate_Float;

   -- Vector interpolation for 3D sensor data
   function Interpolate_Vector 
     (V1, V2 : Math_Library.Vector_3D;
      T1, T2, Target_T : Long_Integer) return Math_Library.Vector_3D
   is
      Alpha : constant Float := Compute_Interpolation_Factor (T1, T2, Target_T);
   begin
      return (
        X => V1.X + Alpha * (V2.X - V1.X),
        Y => V1.Y + Alpha * (V2.Y - V1.Y),
        Z => V1.Z + Alpha * (V2.Z - V1.Z)
      );
   end Interpolate_Vector;

   -- Safe SLERP with quaternion normalization
   function Safe_SLERP 
     (Q1, Q2 : Math_Library.Quaternion;
      T    : Float) return Math_Library.Quaternion
   is
      use type Math_Library.Float;
      
      -- Compute dot product
      Dot_Product : constant Float := 
        Q1.W * Q2.W + Q1.X * Q2.X + Q1.Y * Q2.Y + Q1.Z * Q2.Z;
      
      -- Use absolute value for shortest path
      Abs_Dot : constant Float := 
        (if Dot_Product < 0.0 then -Dot_Product else Dot_Product);
      
      -- Compute interpolation parameters
      Omega : constant Float := Ada.Numerics.Elementary_Functions.Acos (Abs_Dot);
      Sin_Omega : constant Float := Ada.Numerics.Elementary_Functions.Sin (Omega);
      
   begin
      if Sin_Omega < Math_Library.Epsilon then
         -- Quaternions are very close, use linear interpolation
         return Math_Library.Normalize (
           (Q1.W + T * (Q2.W - Q1.W),
            Q1.X + T * (Q2.X - Q1.X),
            Q1.Y + T * (Q2.Y - Q1.Y),
            Q1.Z + T * (Q2.Z - Q1.Z))
         );
      else
         -- Proper SLERP
         return Math_Library.Normalize (
           (Ada.Numerics.Elementary_Functions.Sin ((1.0 - T) * Omega) / Sin_Omega * Q1.W +
              Ada.Numerics.Elementary_Functions.Sin (T * Omega) / Sin_Omega * Q2.W,
            Ada.Numerics.Elementary_Functions.Sin ((1.0 - T) * Omega) / Sin_Omega * Q1.X +
              Ada.Numerics.Elementary_Functions.Sin (T * Omega) / Sin_Omega * Q2.X,
            Ada.Numerics.Elementary_Functions.Sin ((1.0 - T) * Omega) / Sin_Omega * Q1.Y +
              Ada.Numerics.Elementary_Functions.Sin (T * Omega) / Sin_Omega * Q2.Y,
            Ada.Numerics.Elementary_Functions.Sin ((1.0 - T) * Omega) / Sin_Omega * Q1.Z +
              Ada.Numerics.Elementary_Functions.Sin (T * Omega) / Sin_Omega * Q2.Z)
         );
      end if;
   end Safe_SLERP;

   -- Quaternion interpolation using SLERP (Spherical Linear Interpolation)
   function Interpolate_Quaternion 
     (Q1, Q2 : Math_Library.Quaternion;
      T1, T2, Target_T : Long_Integer) return Math_Library.Quaternion
   is
      Alpha : constant Float := Compute_Interpolation_Factor (T1, T2, Target_T);
   begin
      return Safe_SLERP (Q1, Q2, Alpha);
   end Interpolate_Quaternion;

   -- Sensor record interpolation (complete sensor reading)
   function Interpolate_Sensor_Record 
     (R1, R2 : Sensors.Sensor_Record;
      Target_Time : Long_Integer) return Sensors.Sensor_Record
   is
      Interpolated_Data : constant Math_Library.Vector_3D := 
        Interpolate_Vector (R1.Data, R2.Data, R1.Time_Stamp, R2.Time_Stamp, Target_Time);
   begin
      return (
        Time_Stamp   => Target_Time,
        Sensor_Name  => R1.Sensor_Name,  -- Same sensor type
        Platform     => R1.Platform,     -- Same platform
        Device_ID    => R1.Device_ID,    -- Same device
        Device_ID_Len => R1.Device_ID_Len,
        Data         => Interpolated_Data
      );
   end Interpolate_Sensor_Record;

   -- Time grid generation for uniform sampling
   function Generate_Time_Grid 
     (Start_Time, End_Time : Long_Integer;
      Grid_Interval_Ns    : Long_Integer) return Long_Integer_Array
   is
      use type Long_Integer;
      
      Grid_Size : constant Natural := 
        Natural ((End_Time - Start_Time) / Grid_Interval_Ns) + 1;
      
      Result : Long_Integer_Array (1 .. Grid_Size);
   begin
      for I in Result'Range loop
         Result (I) := Start_Time + Long_Integer'Min (Long_Integer (I - 1) * Grid_Interval_Ns, Long_Integer'Last);
      end loop;
      return Result;
   end Generate_Time_Grid;

   -- Align two sensor streams to a common time grid
   procedure Align_Sensor_Streams
     (Stream1, Stream2 : in  Sensors.Sensor_Record_Array;
      Time_Grid        : in  Long_Integer_Array;
      Aligned_Stream1  : out Sensors.Sensor_Record_Array;
      Aligned_Stream2  : out Sensors.Sensor_Record_Array)
   is
   begin
      -- Initialize aligned streams
      Aligned_Stream1 := (others => (
        Time_Stamp   => 0,
        Sensor_Name  => Sensors.Unknown_Sensor,
        Platform     => Sensors.Unknown,
        Device_ID    => (others => ' '),
        Device_ID_Len => 0,
        Data         => (0.0, 0.0, 0.0)
      ));
      Aligned_Stream2 := (others => (
        Time_Stamp   => 0,
        Sensor_Name  => Sensors.Unknown_Sensor,
        Platform     => Sensors.Unknown,
        Device_ID    => (others => ' '),
        Device_ID_Len => 0,
        Data         => (0.0, 0.0, 0.0)
      ));
      
      -- For each time grid point, find and interpolate surrounding readings
      for I in Time_Grid'Range loop
         -- Find surrounding readings for Stream1 (simplified implementation)
         -- In a full implementation, this would use binary search for efficiency
         for J in Stream1'First .. Stream1'Last - 1 loop
            if Stream1 (J).Time_Stamp <= Time_Grid (I) and then
               Stream1 (J + 1).Time_Stamp >= Time_Grid (I) then
               Aligned_Stream1 (I) := Interpolate_Sensor_Record 
                 (Stream1 (J), Stream1 (J + 1), Time_Grid (I));
               exit;
            end if;
         end loop;
         
         -- Find surrounding readings for Stream2
         for J in Stream2'First .. Stream2'Last - 1 loop
            if Stream2 (J).Time_Stamp <= Time_Grid (I) and then
               Stream2 (J + 1).Time_Stamp >= Time_Grid (I) then
               Aligned_Stream2 (I) := Interpolate_Sensor_Record 
                 (Stream2 (J), Stream2 (J + 1), Time_Grid (I));
               exit;
            end if;
         end loop;
      end loop;
   end Align_Sensor_Streams;

   -- Compute relative rotation between two orientations
   function Compute_Relative_Rotation 
     (Q1, Q2 : Math_Library.Quaternion) return Math_Library.Quaternion
   is
      Q2_Conj : constant Math_Library.Quaternion := Math_Library.Conjugate (Q2);
   begin
      return Math_Library.Multiply (Q1, Q2_Conj);
   end Compute_Relative_Rotation;

   -- Check if relative rotation is constant (for validation)
   function Is_Relative_Rotation_Constant 
     (Rotations : Math_Library.Quaternion_Array;
      Tolerance  : Float := Math_Library.Epsilon * 100.0) return Boolean
   is
      use type Math_Library.Float;
      
      First_Rotation : constant Math_Library.Quaternion := Rotations (Rotations'First);
   begin
      for I in Rotations'First + 1 .. Rotations'Last loop
         declare
            Diff : constant Math_Library.Quaternion := 
              Math_Library.Multiply (Rotations (I), Math_Library.Conjugate (First_Rotation));
         begin
            -- Check if difference is within tolerance
            if abs (Diff.W - 1.0) > Tolerance or
               abs (Diff.X) > Tolerance or
               abs (Diff.Y) > Tolerance or
               abs (Diff.Z) > Tolerance then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Relative_Rotation_Constant;

private

   -- Helper array types
   type Long_Integer_Array is array (Positive range <>) of Long_Integer;

end Alignment_Engine;
