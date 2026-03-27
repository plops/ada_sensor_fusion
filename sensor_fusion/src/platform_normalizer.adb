-- SPARK Pure Platform Normalizer Implementation for iOS vs Android Coordinate Corrections
-- Standardizes all raw inputs to Android (Right-Handed, m/s^2) format

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;

package body Platform_Normalizer is

   -- Normalize accelerometer data based on platform
   function Normalize_Accelerometer 
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
   is
   begin
      if Platform = Sensors.iOS then
         -- iOS: Convert from g to m/s^2 and invert axes
         return (
           X => -Raw_Vector.X * Gravity_Constant,
           Y => -Raw_Vector.Y * Gravity_Constant, 
           Z => -Raw_Vector.Z * Gravity_Constant
         );
      else
         -- Android: Keep as-is (already in m/s^2, right-handed)
         return Raw_Vector;
      end if;
   end Normalize_Accelerometer;

   -- Normalize gyroscope data based on platform  
   function Normalize_Gyroscope
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
   is
   begin
      if Platform = Sensors.iOS then
         -- iOS: Invert axes (rad/s units are same)
         return Invert_Axes (Raw_Vector);
      else
         -- Android: Keep as-is (already right-handed)
         return Raw_Vector;
      end if;
   end Normalize_Gyroscope;

   -- Normalize magnetometer data based on platform
   function Normalize_Magnetometer
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
   is
   begin
      if Platform = Sensors.iOS then
         -- iOS: Invert axes (microtesla units are same)  
         return Invert_Axes (Raw_Vector);
      else
         -- Android: Keep as-is (already right-handed)
         return Raw_Vector;
      end if;
   end Normalize_Magnetometer;

   -- Generic sensor record normalization
   function Normalize_Sensor_Record 
     (Raw_Record : Sensors.Sensor_Record) return Sensors.Sensor_Record
   is
      Normalized_Record : Sensors.Sensor_Record := Raw_Record;
   begin
      -- Apply platform-specific normalization based on sensor type
      case Raw_Record.Sensor_Name is
         when Sensors.Accelerometer =>
            declare
               Raw_Vec : constant Math_Library.Vector_3D := 
                 (X => Raw_Record.Data.X, Y => Raw_Record.Data.Y, Z => Raw_Record.Data.Z);
               Normalized_Vec : constant Math_Library.Vector_3D := 
                 Normalize_Accelerometer (Raw_Vec, Raw_Record.Platform);
            begin
               Normalized_Record.Data := 
                 (X => Normalized_Vec.X, Y => Normalized_Vec.Y, Z => Normalized_Vec.Z);
            end;
            
         when Sensors.Gyroscope =>
            declare
               Raw_Vec : constant Math_Library.Vector_3D := 
                 (X => Raw_Record.Data.X, Y => Raw_Record.Data.Y, Z => Raw_Record.Data.Z);
               Normalized_Vec : constant Math_Library.Vector_3D := 
                 Normalize_Gyroscope (Raw_Vec, Raw_Record.Platform);
            begin
               Normalized_Record.Data := 
                 (X => Normalized_Vec.X, Y => Normalized_Vec.Y, Z => Normalized_Vec.Z);
            end;
            
         when Sensors.Magnetometer =>
            declare
               Raw_Vec : constant Math_Library.Vector_3D := 
                 (X => Raw_Record.Data.X, Y => Raw_Record.Data.Y, Z => Raw_Record.Data.Z);
               Normalized_Vec : constant Math_Library.Vector_3D := 
                 Normalize_Magnetometer (Raw_Vec, Raw_Record.Platform);
            begin
               Normalized_Record.Data := 
                 (X => Normalized_Vec.X, Y => Normalized_Vec.Y, Z => Normalized_Vec.Z);
            end;
            
         when others =>
            -- Other sensors (orientation, location, barometer) 
            -- don't need coordinate normalization
            null;
      end case;
      
      return Normalized_Record;
   end Normalize_Sensor_Record;

   -- Apply magnetic declination correction (iOS True North vs Android Magnetic North)
   function Apply_Magnetic_Declination
     (Heading_Rad : Float;
      Platform    : Sensors.OS_Type) return Float
   is
      -- Simplified declination - in real implementation would use GPS location
      Magnetic_Declination : constant Float := 0.0;  -- radians
   begin
      if Platform = Sensors.iOS then
         -- iOS uses True North, convert to Magnetic North (subtract declination)
         return Heading_Rad - Magnetic_Declination;
      else
         -- Android already uses Magnetic North
         return Heading_Rad;
      end if;
   end Apply_Magnetic_Declination;

   -- Validate that normalized vectors meet physical constraints
   function Is_Valid_Normalized_Acceleration 
     (Vec : Math_Library.Vector_3D) return Boolean
   is
   begin
      return 
        Vec.X in -100.0 .. 100.0 and
        Vec.Y in -100.0 .. 100.0 and
        Vec.Z in -100.0 .. 100.0;
   end Is_Valid_Normalized_Acceleration;
   
   function Is_Valid_Normalized_Gyroscope 
     (Vec : Math_Library.Vector_3D) return Boolean
   is
   begin
      return
        Vec.X in -50.0 .. 50.0 and
        Vec.Y in -50.0 .. 50.0 and
        Vec.Z in -50.0 .. 50.0;
   end Is_Valid_Normalized_Gyroscope;

   -- Helper function for axis inversion
   function Invert_Axes (Vec : Vector_3D) return Vector_3D
   is
   begin
      return (
        X => -Vec.X,
        Y => -Vec.Y,
        Z => -Vec.Z
      );
   end Invert_Axes;

end Platform_Normalizer;
