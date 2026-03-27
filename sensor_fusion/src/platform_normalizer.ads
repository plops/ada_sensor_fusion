-- SPARK Pure Platform Normalizer for iOS vs Android Coordinate Corrections
-- Standardizes all raw inputs to Android (Right-Handed, m/s^2) format

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;

package Platform_Normalizer is

   -- Gravity constant for unit conversion (g to m/s^2)
   Gravity_Constant : constant Float := 9.80665;
   
   -- Platform-specific coordinate normalization functions
   
   -- Normalize accelerometer data based on platform
   -- iOS: Convert from g to m/s^2 and invert axes
   -- Android: Keep as-is (already in m/s^2, right-handed)
   function Normalize_Accelerometer 
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
     with 
       Post => 
         (if Platform = Sensors.iOS then 
             (Normalize_Accelerometer'Result.X = -Raw_Vector.X * Gravity_Constant and
              Normalize_Accelerometer'Result.Y = -Raw_Vector.Y * Gravity_Constant and
              Normalize_Accelerometer'Result.Z = -Raw_Vector.Z * Gravity_Constant)
          else
             Normalize_Accelerometer'Result = Raw_Vector);
   
   -- Normalize gyroscope data based on platform  
   -- iOS: Invert axes (rad/s units are same)
   -- Android: Keep as-is (already right-handed)
   function Normalize_Gyroscope
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
     with
       Post =>
         (if Platform = Sensors.iOS then
             (Normalize_Gyroscope'Result.X = -Raw_Vector.X and
              Normalize_Gyroscope'Result.Y = -Raw_Vector.Y and
              Normalize_Gyroscope'Result.Z = -Raw_Vector.Z)
          else
             Normalize_Gyroscope'Result = Raw_Vector);
   
   -- Normalize magnetometer data based on platform
   -- iOS: Invert axes (microtesla units are same)  
   -- Android: Keep as-is (already right-handed)
   function Normalize_Magnetometer
     (Raw_Vector : Math_Library.Vector_3D;
      Platform   : Sensors.OS_Type) return Math_Library.Vector_3D
     with
       Post =>
         (if Platform = Sensors.iOS then
             (Normalize_Magnetometer'Result.X = -Raw_Vector.X and
              Normalize_Magnetometer'Result.Y = -Raw_Vector.Y and
              Normalize_Magnetometer'Result.Z = -Raw_Vector.Z)
          else
             Normalize_Magnetometer'Result = Raw_Vector);
   
   -- Generic sensor record normalization
   -- Handles all sensor types with platform-specific corrections
   function Normalize_Sensor_Record 
     (Raw_Record : Sensors.Sensor_Record) return Sensors.Sensor_Record
     with 
       Pre => Sensors.Is_Valid_Reading (Raw_Record),
       Post => Sensors.Is_Valid_Reading (Normalize_Sensor_Record'Result);
   
   -- Apply magnetic declination correction (iOS True North vs Android Magnetic North)
   -- This is a simplified yaw correction - full implementation would use location data
   function Apply_Magnetic_Declination
     (Heading_Rad : Float;
      Platform    : Sensors.OS_Type) return Float
     with 
       Post => 
         (if Platform = Sensors.iOS then
             Apply_Magnetic_Declination'Result = Heading_Rad + 0.0  -- Placeholder declination
          else
             Apply_Magnetic_Declination'Result = Heading_Rad);
   
   -- Validate that normalized vectors meet physical constraints
   function Is_Valid_Normalized_Acceleration 
     (Vec : Math_Library.Vector_3D) return Boolean
     with 
       Post => 
         Is_Valid_Normalized_Acceleration'Result = 
           (Math_Library.Vector_3D (Vec).X in -100.0 .. 100.0 and
            Math_Library.Vector_3D (Vec).Y in -100.0 .. 100.0 and
            Math_Library.Vector_3D (Vec).Z in -100.0 .. 100.0);
   
   function Is_Valid_Normalized_Gyroscope 
     (Vec : Math_Library.Vector_3D) return Boolean
     with
       Post =>
         Is_Valid_Normalized_Gyroscope'Result =
           (Math_Library.Vector_3D (Vec).X in -50.0 .. 50.0 and
            Math_Library.Vector_3D (Vec).Y in -50.0 .. 50.0 and
            Math_Library.Vector_3D (Vec).Z in -50.0 .. 50.0);

   -- Helper function for axis inversion
   function Invert_Axes (Vec : Math_Library.Vector_3D) return Math_Library.Vector_3D
     with 
       Post => 
         (Invert_Axes'Result.X = -Math_Library.Vector_3D (Vec).X and
          Invert_Axes'Result.Y = -Math_Library.Vector_3D (Vec).Y and
          Invert_Axes'Result.Z = -Math_Library.Vector_3D (Vec).Z);

end Platform_Normalizer;
