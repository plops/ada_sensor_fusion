-- SPARK Pure Data Types for Sensor Fusion Implementation

pragma SPARK_Mode (On);

package body Sensors is

   -- Platform detection from metadata string
   function Detect_Platform (Platform_String : String) return OS_Type is
   begin
      if Platform_String'Length >= 3 then
         if Platform_String (Platform_String'First .. Platform_String'First + 2) = "iOS" then
            return iOS;
         elsif Platform_String (Platform_String'First .. Platform_String'First + 6) = "Android" then
            return Android;
         end if;
      end if;
      return Unknown;
   end Detect_Platform;
   
   -- Sensor type detection from string
   function Detect_Sensor_Type (Sensor_String : String) return Sensor_Type is
   begin
      if Sensor_String'Length >= 4 then
         if Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "accel" then
            return Accelerometer;
         elsif Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "gyro" then
            return Gyroscope;
         elsif Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "magn" then
            return Magnetometer;
         elsif Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "orie" then
            return Orientation;
         elsif Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "loca" then
            return Location;
         elsif Sensor_String (Sensor_String'First .. Sensor_String'First + 3) = "baro" then
            return Barometer;
         end if;
      end if;
      return Unknown_Sensor;
   end Detect_Sensor_Type;
   
   -- Validation function implementation
   function Is_Valid_Reading (R : Sensor_Record) return Boolean is
   begin
      -- Check timestamp bounds
      if R.Time_Stamp not in Timestamp_Nano then
         return False;
      end if;
      
      -- Check device ID length
      if R.Device_ID_Len not in R.Device_ID'Range then
         return False;
      end if;
      
      -- Check for NaN values
      if Is_NaN (R.Data.X) or Is_NaN (R.Data.Y) or Is_NaN (R.Data.Z) then
         return False;
      end if;
      
      -- Sensor-specific bounds checking
      case R.Sensor_Name is
         when Accelerometer =>
            return (R.Data.X in Acceleration and 
                    R.Data.Y in Acceleration and 
                    R.Data.Z in Acceleration);
         when Gyroscope =>
            return (R.Data.X in Angular_Velocity and
                    R.Data.Y in Angular_Velocity and
                    R.Data.Z in Angular_Velocity);
         when Magnetometer =>
            return (R.Data.X in Magnetic_Field and
                    R.Data.Y in Magnetic_Field and
                    R.Data.Z in Magnetic_Field);
         when others =>
            return True;  -- Other sensors have default bounds
      end case;
   end Is_Valid_Reading;
   
end Sensors;
