pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Text_IO.Unbounded_IO;
with Ada.Streams;
with GNATCOLL.JSON;
with AWS.Messages;
with AWS.MIME;
with AWS.Config.Set;
with AWS.Translator;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Calendar;
with Ada.Exceptions;
with Sensors;

package body HTTP_Listener is

   use Ada.Text_IO;
   use GNATCOLL.JSON;

   function Sensor_Data_Callback (Request : AWS.Status.Data)
     return AWS.Response.Data is
      Method : constant String := AWS.Status.Method (Request);
      URI    : constant String := AWS.Status.URI (Request);
   begin
      Put_Line ("Request: " & Method & " " & URI);
      
      if Method = "POST" and then URI = "/data" then
         declare
            Content_Length : Natural := 0;
            Body_Str       : Unbounded_String;
            Buffer         : String (1 .. 4096);
            Last           : Natural;
            JSON_Val       : JSON_Value;
            Payload        : JSON_Array;
         begin
            -- Get content length from headers
            if AWS.Status.Header (Request, "Content-Length") /= "" then
               Content_Length := Natural'Value (AWS.Status.Header (Request, "Content-Length"));
            end if;
            
            Put_Line ("Content-Length: " & Natural'Image (Content_Length));
            
            -- Read the body using Read_Body (not Payload)
            if Content_Length > 0 then
               loop
                  AWS.Status.Read_Body (Request, Buffer, Last);
                  if Last > 0 then
                     Append (Body_Str, Buffer (1 .. Last));
                  end if;
                  exit when Last = 0 or else AWS.Status.End_Of_Body (Request);
               end loop;
            end if;
            
            declare
               Body_Data : constant String := To_String (Body_Str);
               Records : Sensors.Sensor_Record_Array (1 .. 500);
               Count   : Natural;
            begin
               Put_Line ("Received sensor data: " &
                        Natural'Image (Body_Data'Length) & " bytes");
               
               -- Show actual data content for debugging
               if Body_Data'Length > 0 then
                  Put_Line ("Raw data start (" & 
                           Natural'Image (Natural'Min (Body_Data'Length, 100)) & " chars):");
                  
                  -- Show first 100 characters
                  declare
                     Show_Length : constant Natural := Natural'Min (Body_Data'Length, 100);
                  begin
                     Put_Line (Body_Data (Body_Data'First .. Body_Data'First + Show_Length - 1));
                  end;
               end if;
               
               -- Parse the JSON and extract sensor records
               Parse_Sensor_JSON (Body_Data, Records, Count);
               
               Put_Line ("Parsed" & Natural'Image (Count) & " sensor records");
               
               -- Write the parsed data to file
               if Count > 0 then
                  Write_Sensor_Data_To_File (Records, Count);
               end if;
            end;

            return AWS.Response.Build
              (Content_Type => AWS.MIME.Text_HTML,
               Message_Body => "Data received successfully");
         end;
      else
         return AWS.Response.Build
           (Status_Code  => AWS.Messages.S404,
            Content_Type => AWS.MIME.Text_HTML,
            Message_Body => "Not Found");
      end if;
   end Sensor_Data_Callback;

   procedure Start_Server (Port : Natural := 8080) is
      Config : AWS.Config.Object;
   begin
      Put_Line ("Starting sensor data server on port" & Natural'Image (Port));
      AWS.Config.Set.Server_Port (Config, Port);
      AWS.Server.Start
        (Server,
         Callback => Sensor_Data_Callback'Access,
         Config   => Config);
      Put_Line ("Server started successfully");
   end Start_Server;

   procedure Stop_Server is
   begin
      Put_Line ("Stopping sensor data server");
      AWS.Server.Shutdown (Server);
      Put_Line ("Server stopped");
   end Stop_Server;

   procedure Parse_Sensor_JSON
     (JSON_String : String;
      Records     : out Sensors.Sensor_Record_Array;
      Count       : out Natural) is
      JSON_Val   : GNATCOLL.JSON.JSON_Value;
      Payload    : GNATCOLL.JSON.JSON_Array;
      Default_Device_ID : constant String := "phone001";
      Default_Platform : constant String := "Android";
   begin
      Count := 0;
      
      -- Parse the main JSON object
      JSON_Val := GNATCOLL.JSON.Read (JSON_String);
      
      -- Extract payload array (this is the main structure from Sensor Logger)
      if JSON_Val.Has_Field ("payload") then
         Payload := JSON_Val.Get ("payload");
         
         -- Process each sensor reading in payload
         for I in 1 .. GNATCOLL.JSON.Length (Payload) loop
            exit when Count >= Records'Length;
            
            declare
               Reading_Obj : constant GNATCOLL.JSON.JSON_Value := GNATCOLL.JSON.Get (Payload, I);
               Sensor_Record : Sensors.Sensor_Record;
               Values_Obj : GNATCOLL.JSON.JSON_Value;
            begin
               -- Extract sensor name (e.g., "accelerometer", "gyroscopeuncalibrated")
               if Reading_Obj.Has_Field ("name") then
                  declare
                     Name_Str : constant String := Reading_Obj.Get ("name");
                  begin
                     Sensor_Record.Sensor_Name := Sensors.Detect_Sensor_Type (Name_Str);
                  end;
               else
                  Sensor_Record.Sensor_Name := Sensors.Unknown_Sensor;
               end if;
               
               -- Extract timestamp (in nanoseconds)
               if Reading_Obj.Has_Field ("time") then
                  Sensor_Record.Time_Stamp := Timestamp_Nano (Reading_Obj.Get ("time"));
               else
                  Sensor_Record.Time_Stamp := 0;
               end if;
               
               -- Set default platform (can be enhanced later with detection logic)
               Sensor_Record.Platform := Sensors.Android;
               
               -- Set default device ID (can be enhanced with client IP detection)
               Sensor_Record.Device_ID := Default_Device_ID;
               Sensor_Record.Device_ID_Len := Default_Device_ID'Length;
               
               -- Extract sensor values (they are objects, not arrays)
               if Reading_Obj.Has_Field ("values") then
                  Values_Obj := Reading_Obj.Get ("values");
                  
                  -- Handle 3D vector values (x, y, z)
                  if Values_Obj.Has_Field ("x") and then 
                     Values_Obj.Has_Field ("y") and then 
                     Values_Obj.Has_Field ("z") then
                     Sensor_Record.Data.X := Float (Values_Obj.Get ("x"));
                     Sensor_Record.Data.Y := Float (Values_Obj.Get ("y"));
                     Sensor_Record.Data.Z := Float (Values_Obj.Get ("z"));
                     
                  -- Handle quaternion values (qw, qx, qy, qz) for orientation
                  elsif Values_Obj.Has_Field ("qw") and then 
                        Values_Obj.Has_Field ("qx") and then 
                        Values_Obj.Has_Field ("qy") and then 
                        Values_Obj.Has_Field ("qz") then
                     -- Store quaternion as vector (w, x, y, z mapped to x, y, z, with w in x)
                     Sensor_Record.Data.X := Float (Values_Obj.Get ("qw"));
                     Sensor_Record.Data.Y := Float (Values_Obj.Get ("qx"));
                     Sensor_Record.Data.Z := Float (Values_Obj.Get ("qy"));
                     -- Note: qz is stored separately if needed
                     
                  else
                     Sensor_Record.Data := (0.0, 0.0, 0.0);
                  end if;
               else
                  Sensor_Record.Data := (0.0, 0.0, 0.0);
               end if;
               
               -- Add to records if valid
               if Sensors.Is_Valid_Reading (Sensor_Record) then
                  Count := Count + 1;
                  Records (Count) := Sensor_Record;
               end if;
            end;
         end loop;
      end if;
      
   exception
      when E : others =>
         Put_Line ("Error parsing sensor JSON: " & Ada.Exceptions.Exception_Message (E));
         Count := 0;
   end Parse_Sensor_JSON;

      -- File output functionality for captured sensor data
   procedure Write_Sensor_Data_To_File
     (Records : Sensors.Sensor_Record_Array;
      Count   : Natural) is
      use Ada.Text_IO;
      use Ada.Calendar;
      
      File : File_Type;
      Filename : String (1 .. 100);
      Filename_Len : Natural;
      Timestamp : String (1 .. 20);
   begin
      if Count = 0 then
         return;
      end if;
      
      -- Generate filename with timestamp
      declare
         Now : constant Time := Clock;
      begin
         Timestamp := Ada.Strings.Fixed.Trim 
           (Now'Image, Ada.Strings.Both);
         
         -- Create filename based on first record's platform and device
         Filename_Len := Natural'Min (
           50 + Records (1).Device_ID_Len + Timestamp'Length,
           Filename'Length);
         
         declare
            Prefix : constant String := 
              (if Records (1).Platform = Sensors.iOS then "iphone" 
               elsif Records (1).Platform = Sensors.Android then "samsung"
               else "unknown");
            Device_Part : constant String := 
              Records (1).Device_ID (1 .. Records (1).Device_ID_Len);
         begin
            Filename (1 .. Filename_Len) := 
              Prefix & "_" & Device_Part & "_" & 
              Timestamp (Timestamp'First .. Timestamp'First + 19) & 
              ".csv";
         end;
      end;
      
      -- Open file for writing
      begin
         Create (File, Out_File, Filename (1 .. Filename_Len));
         
         -- Write CSV header
         Put_Line (File, "timestamp_ns,platform,device_id,sensor_type,x,y,z");
         
         -- Write sensor records
         for I in 1 .. Count loop
            declare
               Rec : Sensors.Sensor_Record renames Records (I);
               Platform_Str : constant String := 
                 (if Rec.Platform = Sensors.iOS then "iOS"
                  elsif Rec.Platform = Sensors.Android then "Android"
                  else "Unknown");
               Sensor_Str : constant String := 
                 (if Rec.Sensor_Name = Sensors.Accelerometer then "accelerometer"
                  elsif Rec.Sensor_Name = Sensors.Gyroscope then "gyroscope"
                  elsif Rec.Sensor_Name = Sensors.Magnetometer then "magnetometer"
                  elsif Rec.Sensor_Name = Sensors.Orientation then "orientation"
                  elsif Rec.Sensor_Name = Sensors.Location then "location"
                  elsif Rec.Sensor_Name = Sensors.Barometer then "barometer"
                  else "unknown");
               Device_Str : constant String := 
                 Rec.Device_ID (1 .. Rec.Device_ID_Len);
            begin
               Put (File, Long_Integer'Image (Rec.Time_Stamp));
               Put (File, "," & Platform_Str);
               Put (File, "," & Device_Str);
               Put (File, "," & Sensor_Str);
               Put (File, "," & Float'Image (Rec.Data.X));
               Put (File, "," & Float'Image (Rec.Data.Y));
               Put_Line (File, "," & Float'Image (Rec.Data.Z));
            end;
         end loop;
         
         Close (File);
         Put_Line ("Sensor data written to: " & Filename (1 .. Filename_Len));
         Put_Line ("Records written: " & Natural'Image (Count));
         
      exception
         when E : others =>
            Put_Line ("Error writing sensor data to file: " & 
                     Ada.Exceptions.Exception_Message (E));
            if Is_Open (File) then
               Close (File);
            end if;
      end;
   end Write_Sensor_Data_To_File;

protected body Sensor_Buffer is
      entry Add_Reading (Reading : Sensors.Sensor_Record)
        when Cur_Count < 1000 is
      begin
         Head := (Head mod 1000) + 1;
         Buffer (Head) := Reading;
         Cur_Count := Cur_Count + 1;
      end Add_Reading;

      entry Get_Readings (Records : out Sensors.Sensor_Record_Array;
                          Count   : out Natural)
        when Cur_Count > 0 is
         Num_To_Get : constant Natural := Natural'Min (Cur_Count,
                                                       Records'Length);
      begin
         for I in 1 .. Num_To_Get loop
            Records (I) := Buffer ((Tail + I) mod 1000 + 1);
         end loop;
         Tail := (Tail + Num_To_Get) mod 1000;
         Cur_Count := Cur_Count - Num_To_Get;
         Count := Num_To_Get;
      end Get_Readings;
   end Sensor_Buffer;

end HTTP_Listener;
