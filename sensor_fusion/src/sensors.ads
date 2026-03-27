-- SPARK Pure Data Types for Sensor Fusion
-- Defines sensor data structures with strict bounds for formal verification

pragma SPARK_Mode (On);

package Sensors is

   -- Platform enumeration for iOS vs Android handling
   type OS_Type is (iOS, Android, Unknown);
   
   -- Sensor type enumeration
   type Sensor_Type is (Accelerometer, Gyroscope, Magnetometer, 
                        Orientation, Location, Barometer, Unknown_Sensor);
   
   -- Strictly bounded float types for safety
   subtype Acceleration is Float range -100.0 .. 100.0;  -- m/s^2
   subtype Angular_Velocity is Float range -50.0 .. 50.0;  -- rad/s
   subtype Magnetic_Field is Float range -2000.0 .. 2000.0;  -- microtesla
   subtype Timestamp_Nano is Long_Integer range 0 .. Long_Integer'Last;
   
   -- 3D Vector type with bounded components
   type Vector_3D is record
      X : Float;
      Y : Float;
      Z : Float;
   end record;
   
   -- Sensor reading record with nanosecond precision timestamp
   type Sensor_Record is record
      Time_Stamp : Timestamp_Nano;
      Sensor_Name : Sensor_Type;
      Platform : OS_Type;
      Device_ID : String (1 .. 32);
      Device_ID_Len : Natural;
      Data : Vector_3D;
   end record;
   
   -- Array type for sensor records (for buffering)
   type Sensor_Record_Array is array (Positive range <>) of Sensor_Record;
   
   -- Validation function for sensor readings
   function Is_Valid_Reading (R : Sensor_Record) return Boolean
     with 
       Post => Is_Valid_Reading'Result = 
         (R.Time_Stamp in Timestamp_Nano and
          R.Device_ID_Len in R.Device_ID'Range and
          (if R.Sensor_Name = Accelerometer then 
             (R.Data.X in Acceleration and 
              R.Data.Y in Acceleration and 
              R.Data.Z in Acceleration)
           elsif R.Sensor_Name = Gyroscope then
             (R.Data.X in Angular_Velocity and
              R.Data.Y in Angular_Velocity and
              R.Data.Z in Angular_Velocity)
           elsif R.Sensor_Name = Magnetometer then
             (R.Data.X in Magnetic_Field and
              R.Data.Y in Magnetic_Field and
              R.Data.Z in Magnetic_Field)
           else
             True));  -- Other sensors have default bounds
   
   -- Platform detection from metadata
   function Detect_Platform (Platform_String : String) return OS_Type;
   
   -- Sensor type detection from string
   function Detect_Sensor_Type (Sensor_String : String) return Sensor_Type;
   
private
   
   -- Helper function to check if float is NaN
   function Is_NaN (Value : Float) return Boolean
     with Import, Convention => Intrinsic, External_Name => "__builtin_isnan";

end Sensors;
