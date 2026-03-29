-- Simple Phone Sensor Server
-- Basic integration of HTTP server with sensor data processing

pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Streams;
with GNAT.Sockets;

procedure Simple_Phone_Server is
   
   use Ada.Text_IO;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : GNAT.Sockets.Sock_Addr_Type;
   Server_Socket : GNAT.Sockets.Socket_Type;
   Client_Socket : GNAT.Sockets.Socket_Type;
   Client_Addr : GNAT.Sockets.Sock_Addr_Type;
   
   -- Sensor data storage (simplified)
   type Sensor_Data_Record is record
      Time_Stamp : Long_Integer;
      Sensor_Name : String (1 .. 20);
      Name_Length  : Natural;
      X, Y, Z    : Float;
   end record;
   
   type Sensor_Buffer is array (1 .. 100) of Sensor_Data_Record;
   Sensor_Count : Natural := 0;
   
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
   procedure Parse_Sensor_JSON (JSON_String : String) is
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
      
      -- Store sensor data
      New_Data : Sensor_Data_Record;
      
   begin
      Put_Line ("  Sensor: " & Sensor_Name);
      Put_Line ("  Time: " & Long_Integer'Image (Time_Stamp));
      Put_Line ("  Data: (" & Float'Image (Accel_X) & ", " & 
                 Float'Image (Accel_Y) & ", " & Float'Image (Accel_Z) & ")");
      
      -- Store in buffer
      if Sensor_Count < Sensor_Buffer'Last then
         Sensor_Count := Sensor_Count + 1;
         New_Data.Time_Stamp := Time_Stamp;
         New_Data.Name_Length := Natural'Min (Sensor_Name'Length, New_Data.Sensor_Name'Length);
         New_Data.Sensor_Name (1 .. New_Data.Name_Length) := 
           Sensor_Name (Sensor_Name'First .. Sensor_Name'First + New_Data.Name_Length - 1);
         New_Data.X := Accel_X;
         New_Data.Y := Accel_Y;
         New_Data.Z := Accel_Z;
         Sensor_Buffer (Sensor_Count) := New_Data;
      end if;
   end Parse_Sensor_JSON;
   
   -- Function to handle client connection
   procedure Handle_Connection (Client_Socket : GNAT.Sockets.Socket_Type) is
      Buffer : Ada.Streams.Stream_Element_Array (1 .. 8192);
      Last    : Ada.Streams.Stream_Element_Offset;
      Client_IP : constant String := GNAT.Sockets.Image (Client_Addr.Addr);
   begin
      -- Read data from client
      begin
         GNAT.Sockets.Receive_Socket (Client_Socket, Buffer, Last);
      exception
         when others =>
            return;
      end;
      
      if Last > Buffer'First then
         declare
            Request : String (1 .. Natural (Last));
         begin
            -- Convert stream elements to characters
            for I in Request'Range loop
               Request (I) := Character'Val (Buffer (Ada.Streams.Stream_Element_Offset (I)));
            end loop;
            
            Put_Line ("Received " & Natural'Image (Natural (Last)) & " bytes from " & Client_IP);
            
            -- Extract and parse JSON
            declare
               JSON_Body : constant String := Extract_JSON_Body (Request);
            begin
               if JSON_Body'Length > 0 then
                  Put_Line ("JSON data: " & JSON_Body (1 .. Natural'Min (JSON_Body'Length, 100)) & "...");
                  Put_Line ("");
                  Parse_Sensor_JSON (JSON_Body);
                  Put_Line ("✓ Sensor data processed and stored");
               else
                  Put_Line ("No JSON data found in request");
               end if;
            end;
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
   Put_Line ("=== Simple Phone Sensor Fusion Server ===");
   Put_Line ("Ready to receive real sensor data from iPhone and Android devices");
   Put_Line ("");
   
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
   Put_Line ("Expected JSON format: {""name"":""accelerometer"",""values"":{""x"":0.1,""y"":0.2,""z"":9.8},""time"":1640995200000000000}");
   Put_Line ("");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Main server loop
   loop
      begin
         GNAT.Sockets.Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         
         -- Handle connection in current thread (simplified)
         Handle_Connection (Client_Socket);
         
         GNAT.Sockets.Close_Socket (Client_Socket);
         
         Put_Line ("Total sensor readings received: " & Natural'Image (Sensor_Count));
         Put_Line ("");
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Message (E));
      GNAT.Sockets.Close_Socket (Server_Socket);
end Simple_Phone_Server;
