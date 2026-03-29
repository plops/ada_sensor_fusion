-- Phone Sensor Integration Package
-- Integrates real sensor data from iPhone and Android devices

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;
with Platform_Normalizer;
with Alignment_Engine;

package Phone_Sensor_Integration is

   -- Device identification for tracking multiple phones
   type Device_ID is range 1 .. 10;
   
   -- Device status tracking
   type Device_Status is (Disconnected, Connected, Receiving_Data, Error);
   
   -- Device information record
   type Device_Info is record
      ID           : Device_ID;
      Status       : Device_Status := Disconnected;
      Platform     : Sensors.OS_Type := Sensors.Unknown;
      Last_Update  : Long_Integer := 0;
      IP_Address   : String (1 .. 15) := (others => ' ');
      IP_Length    : Natural := 0;
   end record;
   
   -- Device array for multiple phone tracking
   type Device_Array is array (Device_ID) of Device_Info;
   
   -- Sensor data buffer for each device
   type Sensor_Buffer is array (Positive range <>) of Sensors.Sensor_Record;
   
   -- Fusion state for each device
   type Device_Fusion_State is record
      Current_Orientation : Math_Library.Quaternion := Math_Library.Identity_Quaternion;
      Last_Accel        : Sensors.Vector_3D := (0.0, 0.0, 0.0);
      Last_Gyro         : Sensors.Vector_3D := (0.0, 0.0, 0.0);
      Last_Mag          : Sensors.Vector_3D := (0.0, 0.0, 0.0);
      Last_Time         : Long_Integer := 0;
      Is_Initialized    : Boolean := False;
   end record;
   
   type Device_Fusion_Array is array (Device_ID) of Device_Fusion_State;
   
   -- Initialize device tracking system
   procedure Initialize_Device_Tracking
     (Devices : out Device_Array;
      Fusion  : out Device_Fusion_Array)
     with 
       Post => 
         (for all I in Devices'Range =>
            Devices (I).Status = Disconnected and
            Devices (I).Platform = Sensors.Unknown and
            not Fusion (I).Is_Initialized);
   
   -- Register new device when first data arrives
   procedure Register_Device
     (Devices     : in out Device_Array;
      Device_ID   : in Device_ID;
      Platform    : in Sensors.OS_Type;
      IP_Address  : in String;
      IP_Length   : in Natural)
     with 
       Pre => IP_Length <= IP_Address'Length,
       Post => 
         Devices (Device_ID).Status = Connected and
         Devices (Device_ID).Platform = Platform;
   
   -- Process incoming sensor data from a device
   procedure Process_Sensor_Data
     (Devices        : in out Device_Array;
      Fusion         : in out Device_Fusion_Array;
      Device_ID      : in Device_ID;
      Raw_Sensor_Data : in Sensors.Sensor_Record)
     with 
       Pre => Devices (Device_ID).Status = Connected or Devices (Device_ID).Status = Receiving_Data,
       Post => 
         Devices (Device_ID).Status = Receiving_Data and
         Devices (Device_ID).Last_Update = Raw_Sensor_Data.Time_Stamp;
   
   -- Get current orientation for a device
   function Get_Device_Orientation 
     (Fusion    : Device_Fusion_Array;
      Device_ID : Device_ID) return Math_Library.Quaternion
     with 
       Pre => Fusion (Device_ID).Is_Initialized,
       Post => Math_Library.Magnitude_Squared (Get_Device_Orientation'Result) > Math_Library.Epsilon;
   
   -- Check if device is actively receiving data
   function Is_Device_Active 
     (Devices   : Device_Array;
      Device_ID : Device_ID;
      Timeout_Ns : Long_Integer := 5000000000) return Boolean  -- 5 second timeout
     with 
       Post => 
         (if Is_Device_Active'Result then
             Devices (Device_ID).Status = Receiving_Data
          else
             Devices (Device_ID).Status /= Receiving_Data);
   
   -- Get relative rotation between two devices
   function Get_Relative_Rotation 
     (Fusion     : Device_Fusion_Array;
      Device1_ID : Device_ID;
      Device2_ID : Device_ID) return Math_Library.Quaternion
     with 
       Pre => Fusion (Device1_ID).Is_Initialized and then Fusion (Device2_ID).Is_Initialized,
       Post => Math_Library.Magnitude_Squared (Get_Relative_Rotation'Result) > Math_Library.Epsilon;
   
   -- Validate multi-device setup (strapped devices should have constant relative rotation)
   function Validate_Multi_Device_Setup 
     (Fusion          : Device_Fusion_Array;
      Device1_ID      : Device_ID;
      Device2_ID      : Device_ID;
      Tolerance       : Float := 0.1) return Boolean
     with 
       Pre => Fusion (Device1_ID).Is_Initialized and then Fusion (Device2_ID).Is_Initialized;
   
   -- Update device status based on activity
   procedure Update_Device_Status
     (Devices   : in out Device_Array;
      Current_Time : in Long_Integer;
      Timeout_Ns : in Long_Integer := 5000000000)  -- 5 second timeout
     with 
       Post => 
         (for all I in Devices'Range =>
            (if Current_Time - Devices (I).Last_Update > Timeout_Ns then
                Devices (I).Status /= Receiving_Data));
   
private
   
   -- Internal helper to normalize sensor data based on platform
   function Normalize_Sensor_Reading
     (Raw_Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record
     with 
       Pre => Sensors.Is_Valid_Reading (Raw_Reading),
       Post => Sensors.Is_Valid_Reading (Normalize_Sensor_Reading'Result);
   
   -- Internal helper to update fusion state for a device
   procedure Update_Device_Fusion
     (Fusion_State : in out Device_Fusion_State;
      Accel        : in Sensors.Vector_3D;
      Gyro         : in Sensors.Vector_3D;
      Mag          : in Sensors.Vector_3D;
      Timestamp    : in Long_Integer)
     with 
       Pre => Timestamp >= Fusion_State.Last_Time,
       Post => Fusion_State.Last_Time = Timestamp;

end Phone_Sensor_Integration;
