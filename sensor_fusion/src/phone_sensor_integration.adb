-- Phone Sensor Integration Implementation
-- Integrates real sensor data from iPhone and Android devices

pragma SPARK_Mode (On);

with Sensors;
with Math_Library;
with Platform_Normalizer;
with Alignment_Engine;

package body Phone_Sensor_Integration is

   -- Initialize device tracking system
   procedure Initialize_Device_Tracking
     (Devices : out Device_Array;
      Fusion  : out Device_Fusion_Array)
   is
   begin
      -- Initialize all devices as disconnected
      for I in Devices'Range loop
         Devices (I) := (
            ID => I,
            Status => Disconnected,
            Platform => Sensors.Unknown,
            Last_Update => 0,
            IP_Address => (others => ' '),
            IP_Length => 0
         );
         
         -- Initialize fusion states
         Fusion (I) := (
            Current_Orientation => Math_Library.Identity_Quaternion,
            Last_Accel => (0.0, 0.0, 0.0),
            Last_Gyro => (0.0, 0.0, 0.0),
            Last_Mag => (0.0, 0.0, 0.0),
            Last_Time => 0,
            Is_Initialized => False
         );
      end loop;
   end Initialize_Device_Tracking;
   
   -- Register new device when first data arrives
   procedure Register_Device
     (Devices     : in out Device_Array;
      Device_ID   : in Device_ID;
      Platform    : in Sensors.OS_Type;
      IP_Address  : in String;
      IP_Length   : in Natural)
   is
   begin
      Devices (Device_ID).Status := Connected;
      Devices (Device_ID).Platform := Platform;
      Devices (Device_ID).Last_Update := 0;
      
      -- Copy IP address (truncate if necessary)
      for I in 1 .. IP_Length loop
         if I <= Devices (Device_ID).IP_Address'Length then
            Devices (Device_ID).IP_Address (I) := IP_Address (I);
         end if;
      end loop;
      Devices (Device_ID).IP_Length := IP_Length;
   end Register_Device;
   
   -- Process incoming sensor data from a device
   procedure Process_Sensor_Data
     (Devices        : in out Device_Array;
      Fusion         : in out Device_Fusion_Array;
      Device_ID      : in Device_ID;
      Raw_Sensor_Data : in Sensors.Sensor_Record)
   is
      Normalized_Data : constant Sensors.Sensor_Record := 
        Normalize_Sensor_Reading (Raw_Sensor_Data);
   begin
      -- Update device status
      Devices (Device_ID).Status := Receiving_Data;
      Devices (Device_ID).Last_Update := Raw_Sensor_Data.Time_Stamp;
      
      -- Update fusion state based on sensor type
      case Normalized_Data.Sensor_Name is
         when Sensors.Accelerometer =>
            Update_Device_Fusion 
              (Fusion (Device_ID), 
               Normalized_Data.Data,
               Fusion (Device_ID).Last_Gyro,
               Fusion (Device_ID).Last_Mag,
               Normalized_Data.Time_Stamp);
            Fusion (Device_ID).Last_Accel := Normalized_Data.Data;
            
         when Sensors.Gyroscope =>
            Update_Device_Fusion 
              (Fusion (Device_ID),
               Fusion (Device_ID).Last_Accel,
               Normalized_Data.Data,
               Fusion (Device_ID).Last_Mag,
               Normalized_Data.Time_Stamp);
            Fusion (Device_ID).Last_Gyro := Normalized_Data.Data;
            
         when Sensors.Magnetometer =>
            Update_Device_Fusion 
              (Fusion (Device_ID),
               Fusion (Device_ID).Last_Accel,
               Fusion (Device_ID).Last_Gyro,
               Normalized_Data.Data,
               Normalized_Data.Time_Stamp);
            Fusion (Device_ID).Last_Mag := Normalized_Data.Data;
            
         when others =>
            -- Other sensor types (orientation, etc.) - not used in fusion
            null;
      end case;
   end Process_Sensor_Data;
   
   -- Get current orientation for a device
   function Get_Device_Orientation 
     (Fusion    : Device_Fusion_Array;
      Device_ID : Device_ID) return Math_Library.Quaternion
   is
   begin
      return Fusion (Device_ID).Current_Orientation;
   end Get_Device_Orientation;
   
   -- Check if device is actively receiving data
   function Is_Device_Active 
     (Devices   : Device_Array;
      Device_ID : Device_ID;
      Timeout_Ns : Long_Integer := 5000000000) return Boolean
   is
      use type Long_Integer;
   begin
      return Devices (Device_ID).Status = Receiving_Data and then
             (Devices (Device_ID).Last_Update > 0 and then
              (Long_Integer'Last - Devices (Device_ID).Last_Update >= Timeout_Ns and then
               Long_Integer'Last - Timeout_Ns >= Devices (Device_ID).Last_Update));
   end Is_Device_Active;
   
   -- Get relative rotation between two devices
   function Get_Relative_Rotation 
     (Fusion     : Device_Fusion_Array;
      Device1_ID : Device_ID;
      Device2_ID : Device_ID) return Math_Library.Quaternion
   is
      Q1 : constant Math_Library.Quaternion := Fusion (Device1_ID).Current_Orientation;
      Q2 : constant Math_Library.Quaternion := Fusion (Device2_ID).Current_Orientation;
      Q2_Conj : constant Math_Library.Quaternion := Math_Library.Conjugate (Q2);
   begin
      return Math_Library.Multiply (Q1, Q2_Conj);
   end Get_Relative_Rotation;
   
   -- Validate multi-device setup (strapped devices should have constant relative rotation)
   function Validate_Multi_Device_Setup 
     (Fusion          : Device_Fusion_Array;
      Device1_ID      : Device_ID;
      Device2_ID      : Device_ID;
      Tolerance       : Float := 0.1) return Boolean
   is
      use type Math_Library.Float;
      
      Relative_Rot : constant Math_Library.Quaternion := 
        Get_Relative_Rotation (Fusion, Device1_ID, Device2_ID);
      
      -- Check if relative rotation is close to identity (devices aligned)
      Deviation_X : constant Float := abs (Relative_Rot.X);
      Deviation_Y : constant Float := abs (Relative_Rot.Y);
      Deviation_Z : constant Float := abs (Relative_Rot.Z);
      Deviation_W : constant Float := abs (Relative_Rot.W - 1.0);
   begin
      -- For strapped devices, relative rotation should be minimal
      return Deviation_X < Tolerance and then
             Deviation_Y < Tolerance and then
             Deviation_Z < Tolerance and then
             Deviation_W < Tolerance;
   end Validate_Multi_Device_Setup;
   
   -- Update device status based on activity
   procedure Update_Device_Status
     (Devices   : in out Device_Array;
      Current_Time : in Long_Integer;
      Timeout_Ns : in Long_Integer := 5000000000)  -- 5 second timeout
   is
      use type Long_Integer;
   begin
      for I in Devices'Range loop
         if Devices (I).Status = Receiving_Data and then
            (Current_Time > Devices (I).Last_Update and then
             Current_Time - Devices (I).Last_Update > Timeout_Ns) then
            Devices (I).Status := Connected;  -- Still connected but not receiving
         end if;
      end loop;
   end Update_Device_Status;
   
private
   
   -- Internal helper to normalize sensor data based on platform
   function Normalize_Sensor_Reading
     (Raw_Reading : Sensors.Sensor_Record) return Sensors.Sensor_Record
   is
      Normalized_Data : Sensors.Sensor_Record := Raw_Reading;
      Normalized_Vector : Sensors.Vector_3D;
   begin
      -- Normalize based on sensor type and platform
      case Raw_Reading.Sensor_Name is
         when Sensors.Accelerometer =>
            Normalized_Vector := Platform_Normalizer.Normalize_Accelerometer 
              (Raw_Reading.Data, Raw_Reading.Platform);
            
         when Sensors.Gyroscope =>
            Normalized_Vector := Platform_Normalizer.Normalize_Gyroscope 
              (Raw_Reading.Data, Raw_Reading.Platform);
            
         when Sensors.Magnetometer =>
            Normalized_Vector := Platform_Normalizer.Normalize_Magnetometer 
              (Raw_Reading.Data, Raw_Reading.Platform);
            
         when others =>
            Normalized_Vector := Raw_Reading.Data;  -- No normalization needed
      end case;
      
      Normalized_Data.Data := Normalized_Vector;
      return Normalized_Data;
   end Normalize_Sensor_Reading;
   
   -- Internal helper to update fusion state for a device
   procedure Update_Device_Fusion
     (Fusion_State : in out Device_Fusion_State;
      Accel        : in Sensors.Vector_3D;
      Gyro         : in Sensors.Vector_3D;
      Mag          : in Sensors.Vector_3D;
      Timestamp    : in Long_Integer)
   is
   begin
      if not Fusion_State.Is_Initialized then
         -- Initialize with current orientation estimate from accelerometer
         Fusion_State.Current_Orientation := Math_Library.Identity_Quaternion;
         Fusion_State.Is_Initialized := True;
         Fusion_State.Last_Time := Timestamp;
      else
         -- Update using Madgwick filter
         declare
            DT : constant Float := 
              Math_Library.Compute_Delta_Time (Timestamp, Fusion_State.Last_Time);
         begin
            if DT > 0.0 and DT < 0.2 then  -- Protect against time jumps
               Fusion_State.Current_Orientation := Math_Library.Update_Madgwick 
                 (Fusion_State.Current_Orientation, Accel, Gyro, DT);
            end if;
         end;
         
         Fusion_State.Last_Time := Timestamp;
      end if;
   end Update_Device_Fusion;

end Phone_Sensor_Integration;
