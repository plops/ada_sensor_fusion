-- Phone Sensor HTTP Server Integration
-- Connects ultra-simple HTTP server with phone sensor integration

pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Exceptions;
with GNAT.Sockets;
with Phone_Sensor_Integration;
with Sensors;

procedure Phone_Sensor_Server is
   
   use Ada.Text_IO;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : GNAT.Sockets.Sock_Addr_Type;
   Server_Socket : GNAT.Sockets.Socket_Type;
   Client_Socket : GNAT.Sockets.Socket_Type;
   Client_Addr : GNAT.Sockets.Sock_Addr_Type;
   
   -- Device tracking
   Devices : Phone_Sensor_Integration.Device_Array;
   Fusion  : Phone_Sensor_Integration.Device_Fusion_Array;
   
   -- Device assignment (simplified - assign based on connection order)
   Next_Device_ID : Phone_Sensor_Integration.Device_ID := 1;
   
   -- Function to extract JSON from HTTP request
   function Extract_JSON_Body (Request : String) return String is
      Body_Start : Natural := Request'First;
   begin
      -- Find the end of HTTP headers (double CRLF)
      for I in Request'First .. Request'Last - 3 loop
         if Request (I) = ASCII.CR and Request (I + 1) = ASCII.LF and
            Request (I + 2) = ASCII.CR and Request (I + 3) = ASCII.LF then
            Body_Start := I + 4;
            exit;
         end if;
      end loop;
      
      if Body_Start <= Request'Last then
         return Request (Body_Start .. Request'Last);
      else
         return "";
      end if;
   end Extract_JSON_Body;
   
   -- Function to parse simple sensor data from JSON
   procedure Parse_Sensor_JSON 
     (JSON_String : in String;
      Device_ID   : in Phone_Sensor_Integration.Device_ID;
      Platform    : in Sensors.OS_Type)
   is
      -- Very simple JSON parsing - just extract basic fields
      function Extract_Field (Field_Name : String; JSON : String) return String is
         Start_Pattern : constant String := """" & Field_Name & """:";
         Start_Pos : Natural := JSON'First - 1;
         End_Pos   : Natural := JSON'First - 1;
      begin
         -- Find field start
         for I in JSON'First .. JSON'Last - Start_Pattern'Length loop
            if JSON (I .. I + Start_Pattern'Length - 1) = Start_Pattern then
               Start_Pos := I + Start_Pattern'Length;
               exit;
            end if;
         end loop;
         
         if Start_Pos >= JSON'First then
            -- Find field end (next comma or brace)
            for J in Start_Pos .. JSON'Last loop
               if JSON (J) = ',' or JSON (J) = '}' then
                  End_Pos := J - 1;
                  exit;
               end if;
            end loop;
            
            if End_Pos > Start_Pos then
               -- Remove quotes and spaces
               while Start_Pos <= End_Pos and then 
                     (JSON (Start_Pos) = ' ' or JSON (Start_Pos) = '"') loop
                  Start_Pos := Start_Pos + 1;
               end loop;
               
               while End_Pos >= Start_Pos and then 
                     (JSON (End_Pos) = ' ' or JSON (End_Pos) = '"') loop
                  End_Pos := End_Pos - 1;
               end loop;
               
               if Start_Pos <= End_Pos then
                  return JSON (Start_Pos .. End_Pos);
               end if;
            end if;
         end if;
         
         return "";
      end Extract_Field;
      
      function Extract_Float (Field_Name : String; JSON : String) return Float is
         Field_Value : constant String := Extract_Field (Field_Name, JSON);
      begin
         if Field_Value'Length > 0 then
            return Float'Value (Field_Value);
         else
            return 0.0;
         end if;
      exception
         when others =>
            return 0.0;
      end Extract_Float;
      
      function Extract_Long_Integer (Field_Name : String; JSON : String) return Long_Integer is
         Field_Value : constant String := Extract_Field (Field_Name, JSON);
      begin
         if Field_Value'Length > 0 then
            return Long_Integer'Value (Field_Value);
         else
            return 0;
         end if;
      exception
         when others =>
            return 0;
      end Extract_Long_Integer;
      
      -- Extract sensor data
      Sensor_Name : constant String := Extract_Field ("name", JSON_String);
      Time_Stamp  : constant Long_Integer := Extract_Long_Integer ("time", JSON_String);
      Accel_X     : constant Float := Extract_Float ("x", JSON_String);
      Accel_Y     : constant Float := Extract_Float ("y", JSON_String);
      Accel_Z     : constant Float := Extract_Float ("z", JSON_String);
      
      -- Create sensor record
      Sensor_Data : Sensors.Sensor_Record;
      
   begin
      -- Determine sensor type
      if Sensor_Name = "accelerometer" then
         Sensor_Data.Sensor_Name := Sensors.Accelerometer;
      elsif Sensor_Name'Length >= 5 and then Sensor_Name (Sensor_Name'First .. Sensor_Name'First + 4) = "gyro" then
         Sensor_Data.Sensor_Name := Sensors.Gyroscope;
      elsif Sensor_Name'Length >= 9 and then Sensor_Name (Sensor_Name'First .. Sensor_Name'First + 8) = "magnetome" then
         Sensor_Data.Sensor_Name := Sensors.Magnetometer;
      else
         Sensor_Data.Sensor_Name := Sensors.Unknown_Sensor;
      end if;
      
      -- Fill sensor record
      Sensor_Data.Time_Stamp := Time_Stamp;
      Sensor_Data.Platform := Platform;
      Sensor_Data.Device_ID := "Device_" & Device_ID'Image & "________________";
      Sensor_Data.Device_ID_Len := 7 + Device_ID'Image'Length;
      Sensor_Data.Data := (Accel_X, Accel_Y, Accel_Z);
      
      -- Process the sensor data
      if Sensors.Is_Valid_Reading (Sensor_Data) then
         Phone_Sensor_Integration.Process_Sensor_Data 
           (Devices, Fusion, Device_ID, Sensor_Data);
      end if;
   end Parse_Sensor_JSON;
   
   -- Function to handle client connection
   procedure Handle_Connection (Client_Socket : GNAT.Sockets.Socket_Type) is
      Buffer : String (1 .. 8192);
      Last    : Natural;
      Client_IP : constant String := GNAT.Sockets.Image (Client_Addr.Addr);
   begin
      -- Read data from client
      begin
         GNAT.Sockets.Receive_Socket (Client_Socket, Buffer'Address, Buffer'Length, Last);
      exception
         when others =>
            return;
      end;
      
      if Last > Buffer'First then
         declare
            Request : constant String := Buffer (Buffer'First .. Last);
            JSON_Body : constant String := Extract_JSON_Body (Request);
         begin
            Put_Line ("Received " & Natural'Image (Last) & " bytes from " & Client_IP);
            
            if JSON_Body'Length > 0 then
               Put_Line ("JSON data: " & JSON_Body (1 .. Natural'Min (JSON_Body'Length, 100)) & "...");
               
               -- Parse and process sensor data
               -- For simplicity, assume Android platform (can be enhanced with User-Agent parsing)
               Parse_Sensor_JSON (JSON_Body, 1, Sensors.Android);
            end if;
         end;
      end if;
      
      -- Send HTTP response
      declare
         Response : constant String := 
           "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
           "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
           "Connection: close" & ASCII.CR & ASCII.LF &
           ASCII.CR & ASCII.LF &
           "Sensor data received by Ada fusion server";
      begin
         String'Write (GNAT.Sockets.Stream (Client_Socket), Response);
      end;
   end Handle_Connection;
   
begin
   Put_Line ("=== Phone Sensor Fusion Server ===");
   Put_Line ("Integrating real sensor data from iPhone and Android devices");
   Put_Line ("");
   
   -- Initialize device tracking
   Phone_Sensor_Integration.Initialize_Device_Tracking (Devices, Fusion);
   Put_Line ("✓ Device tracking system initialized");
   
   -- Create and configure server socket
   GNAT.Sockets.Create_Socket (Server_Socket);
   Server_Addr.Addr := GNAT.Sockets.Inet_Addr ("127.0.0.1");
   Server_Addr.Port := GNAT.Sockets.Port_Type (Server_Port);
   
   GNAT.Sockets.Set_Socket_Option (Server_Socket, GNAT.Sockets.Socket_Level, (GNAT.Sockets.Reuse_Address, True));
   
   GNAT.Sockets.Bind_Socket (Server_Socket, Server_Addr);
   GNAT.Sockets.Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Server listening on port" & Natural'Image (Server_Port));
   Put_Line ("✓ Ready to receive sensor data from phones");
   Put_Line ("");
   Put_Line ("Send sensor data to: http://localhost:" & Natural'Image (Server_Port));
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Main server loop
   loop
      begin
         GNAT.Sockets.Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         
         -- Handle connection in current thread (simplified)
         Handle_Connection (Client_Socket);
         
         GNAT.Sockets.Close_Socket (Client_Socket);
         
         -- Update device status
         declare
            Current_Time : constant Long_Integer := 1640995200000000000; -- Simplified
         begin
            Phone_Sensor_Integration.Update_Device_Status (Devices, Current_Time);
         end;
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Message (E));
      GNAT.Sockets.Close_Socket (Server_Socket);
end Phone_Sensor_Server;
