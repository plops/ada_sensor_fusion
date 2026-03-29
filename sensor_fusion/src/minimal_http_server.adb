-- Minimal HTTP Server for Sensor Data Reception
-- No AWS dependencies - uses basic socket programming

with Ada.Text_IO;
with Ada.Text_IO.Unbounded_IO;
with GNAT.Sockets;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.Calendar;
with GNAT.OS_Lib;
with Sensors;

procedure Minimal_HTTP_Server is

   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use GNAT.Sockets;

   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : Sock_Addr_Type;
   Server_Sock : Socket_Type;
   Client_Sock : Socket_Type;
   
   -- Buffer for receiving data
   Buffer_Size : constant := 8192;
   Buffer : String (1 .. Buffer_Size);
   Last : Natural;
   
   -- Flag to control server loop
   Running : Boolean := True;

   -- Simple HTTP response helper
   function Build_HTTP_Response 
     (Status_Code : String;
      Content_Type : String;
      Body_Str : String) return String
   is
      Response : Unbounded_String;
      CRLF : constant String := (1 => ASCII.CR, 2 => ASCII.LF);
   begin
      Append (Response, "HTTP/1.1 " & Status_Code & CRLF);
      Append (Response, "Content-Type: " & Content_Type & CRLF);
      Append (Response, "Content-Length: " & Natural'Image (Body_Str'Length) & CRLF);
      Append (Response, "Access-Control-Allow-Origin: *" & CRLF);
      Append (Response, "Connection: close" & CRLF);
      Append (Response, CRLF);
      Append (Response, Body_Str);
      return To_String (Response);
   end Build_HTTP_Response;

   -- Parse HTTP request to extract method, URI, and body
   procedure Parse_HTTP_Request 
     (Request : String;
      Method : out Unbounded_String;
      URI : out Unbounded_String;
      Body : out Unbounded_String)
   is
      Lines : array (1 .. 100) of Unbounded_String;
      Line_Count : Natural := 0;
      Current_Line : Unbounded_String;
      Header_End : Natural := 0;
      CRLF : constant String := (1 => ASCII.CR, 2 => ASCII.LF);
   begin
      Method := To_Unbounded_String ("");
      URI := To_Unbounded_String ("");
      Body := To_Unbounded_String ("");
      
      -- Split request into lines
      for I in Request'Range loop
         if Request (I) = ASCII.CR then
            if I + 1 <= Request'Last and then Request (I + 1) = ASCII.LF then
               Line_Count := Line_Count + 1;
               Lines (Line_Count) := Current_Line;
               Current_Line := To_Unbounded_String ("");
               
               -- Check for end of headers (empty line)
               if Length (Lines (Line_Count)) = 0 then
                  Header_End := I + 2;
                  exit;
               end if;
               
               -- Skip the LF
               I := I + 1;
            end if;
         else
            Append (Current_Line, Request (I));
         end if;
      end loop;
      
      -- Extract method and URI from first line
      if Line_Count > 0 then
         declare
            First_Line : constant String := To_String (Lines (1));
            Space1_Pos : Natural;
            Space2_Pos : Natural;
         begin
            Space1_Pos := Ada.Strings.Fixed.Index (First_Line, " ");
            if Space1_Pos > 0 then
               Method := To_Unbounded_String (First_Line (First_Line'First .. Space1_Pos - 1));
               
               Space2_Pos := Ada.Strings.Fixed.Index (First_Line, " ", Space1_Pos + 1);
               if Space2_Pos > 0 then
                  URI := To_Unbounded_String (First_Line (Space1_Pos + 1 .. Space2_Pos - 1));
               else
                  URI := To_Unbounded_String (First_Line (Space1_Pos + 1 .. First_Line'Last));
               end if;
            end if;
         end;
      end if;
      
      -- Extract body if present
      if Header_End > 0 and then Header_End <= Request'Last then
         Body := To_Unbounded_String (Request (Header_End .. Request'Last));
      end if;
   end Parse_HTTP_Request;

   -- Handle sensor data POST request
   procedure Handle_Sensor_Data (Body : String) is
      use GNATCOLL.JSON;
      use Ada.Calendar;
      
      JSON_Val : JSON_Value;
      Payload : JSON_Array;
      Records : Sensors.Sensor_Record_Array (1 .. 500);
      Count : Natural;
      File : Ada.Text_IO.File_Type;
      Filename : String (1 .. 50);
      Now : constant Time := Clock;
   begin
      Put_Line ("Processing sensor data: " & Natural'Image (Body'Length) & " bytes");
      
      -- Show first 100 characters of data for debugging
      if Body'Length > 0 then
         declare
            Show_Length : constant Natural := Natural'Min (Body'Length, 100);
         begin
            Put_Line ("Data preview: " & Body (Body'First .. Body'First + Show_Length - 1));
         end;
      end if;
      
      -- Parse JSON (simplified version without full AWS dependencies)
      begin
         JSON_Val := Read (Body);
         
         if JSON_Val.Has_Field ("payload") then
            Payload := JSON_Val.Get ("payload");
            Count := 0;
            
            -- Process each sensor reading
            for I in 1 .. Length (Payload) loop
               exit when Count >= Records'Length;
               
               declare
                  Reading_Obj : constant JSON_Value := Get (Payload, I);
                  Sensor_Record : Sensors.Sensor_Record;
                  Values_Obj : JSON_Value;
               begin
                  -- Extract sensor name
                  if Reading_Obj.Has_Field ("name") then
                     declare
                        Name_Str : constant String := Reading_Obj.Get ("name");
                     begin
                        Sensor_Record.Sensor_Name := Sensors.Detect_Sensor_Type (Name_Str);
                     end;
                  else
                     Sensor_Record.Sensor_Name := Sensors.Unknown_Sensor;
                  end if;
                  
                  -- Extract timestamp
                  if Reading_Obj.Has_Field ("time") then
                     Sensor_Record.Time_Stamp := Timestamp_Nano (Reading_Obj.Get ("time"));
                  else
                     Sensor_Record.Time_Stamp := 0;
                  end if;
                  
                  -- Set defaults
                  Sensor_Record.Platform := Sensors.Android;
                  Sensor_Record.Device_ID := "phone001";
                  Sensor_Record.Device_ID_Len := 8;
                  
                  -- Extract values
                  if Reading_Obj.Has_Field ("values") then
                     Values_Obj := Reading_Obj.Get ("values");
                     
                     if Values_Obj.Has_Field ("x") and then 
                        Values_Obj.Has_Field ("y") and then 
                        Values_Obj.Has_Field ("z") then
                        Sensor_Record.Data.X := Float (Values_Obj.Get ("x"));
                        Sensor_Record.Data.Y := Float (Values_Obj.Get ("y"));
                        Sensor_Record.Data.Z := Float (Values_Obj.Get ("z"));
                     else
                        Sensor_Record.Data := (0.0, 0.0, 0.0);
                     end if;
                  else
                     Sensor_Record.Data := (0.0, 0.0, 0.0);
                  end if;
                  
                  -- Add valid records
                  if Sensors.Is_Valid_Reading (Sensor_Record) then
                     Count := Count + 1;
                     Records (Count) := Sensor_Record;
                  end if;
               end;
            end loop;
            
            -- Write to CSV file
            if Count > 0 then
               -- Generate filename
               declare
                  Time_Str : constant String := Ada.Strings.Fixed.Trim 
                    (Now'Image, Ada.Strings.Both);
                  Filename_Len : Natural;
               begin
                  Filename_Len := Natural'Min (50, 22 + Time_Str'Length);
                  Filename (1 .. Filename_Len) := "sensor_data_" & 
                    Time_Str (Time_Str'First .. Time_Str'First + 19) & ".csv";
                  
                  Create (File, Out_File, Filename (1 .. Filename_Len));
                  
                  -- Write CSV header
                  Put_Line (File, "timestamp_ns,platform,device_id,sensor_type,x,y,z");
                  
                  -- Write records
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
                           else "unknown");
                     begin
                        Put (File, Long_Integer'Image (Rec.Time_Stamp));
                        Put (File, "," & Platform_Str);
                        Put (File, "," & Rec.Device_ID (1 .. Rec.Device_ID_Len));
                        Put (File, "," & Sensor_Str);
                        Put (File, "," & Float'Image (Rec.Data.X));
                        Put (File, "," & Float'Image (Rec.Data.Y));
                        Put_Line (File, "," & Float'Image (Rec.Data.Z));
                     end;
                  end loop;
                  
                  Close (File);
                  Put_Line ("Wrote " & Natural'Image (Count) & 
                           " records to " & Filename (1 .. Filename_Len));
               end;
            end if;
         end if;
         
      exception
         when E : others =>
            Put_Line ("Error parsing JSON: " & Ada.Exceptions.Exception_Message (E));
      end;
   end Handle_Sensor_Data;

begin
   Put_Line ("Minimal HTTP Server for Sensor Data");
   Put_Line ("====================================");
   
   -- Initialize socket library
   Initialize;
   
   -- Create server socket
   Create_Socket (Server_Sock, Family_Inet, Socket_Stream);
   
   -- Set socket option to reuse address
   Set_Socket_Option (Server_Sock, Socket_Level, (Reuse_Address, True));
   
   -- Bind to port
   Server_Addr := (Family => Family_Inet,
                   Addr   => Any_Inet_Addr,
                   Port   => Port_Type (Server_Port));
   
   Bind_Socket (Server_Sock, Server_Addr);
   
   -- Start listening
   Listen_Socket (Server_Sock, 5);
   
   Put_Line ("Server started on http://localhost:" & Natural'Image (Server_Port));
   Put_Line ("Send POST requests to /data endpoint");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Main server loop
   while Running loop
      begin
         -- Accept client connection
         Accept_Socket (Server_Sock, Client_Sock, Server_Addr);
         
         Put_Line ("Client connected from: " & Image (Server_Addr.Addr));
         
         -- Receive request
         begin
            loop
               Receive_Socket (Client_Sock, Buffer, Last);
               exit when Last = 0;
               
               declare
                  Request : constant String := Buffer (1 .. Last);
                  Method, URI, Body : Unbounded_String;
                  Response : String;
               begin
                  -- Parse HTTP request
                  Parse_HTTP_Request (Request, Method, URI, Body);
                  
                  Put_Line ("Request: " & To_String (Method) & " " & To_String (URI));
                  
                  -- Handle different endpoints
                  if To_String (Method) = "POST" and then To_String (URI) = "/data" then
                     Handle_Sensor_Data (To_String (Body));
                     Response := Build_HTTP_Response ("200 OK", "text/plain", "Data received successfully");
                  elsif To_String (Method) = "GET" and then To_String (URI) = "/" then
                     Response := Build_HTTP_Response ("200 OK", "text/html", 
                        "<html><body><h1>Sensor Data Server</h1>" &
                        "<p>Send POST requests to /data endpoint</p></body></html>");
                  else
                     Response := Build_HTTP_Response ("404 Not Found", "text/plain", "Not Found");
                  end if;
                  
                  -- Send response
                  Send_Socket (Client_Sock, Response, Response'Length);
               end;
               
               exit; -- Process one request per connection
            end loop;
            
         exception
            when E : others =>
               Put_Line ("Error handling client: " & Ada.Exceptions.Exception_Message (E));
         end;
         
         -- Close client socket
         Close_Socket (Client_Sock);
         
      exception
         when E : others =>
            Put_Line ("Error in server loop: " & Ada.Exceptions.Exception_Message (E));
            if Is_Open (Client_Sock) then
               Close_Socket (Client_Sock);
            end if;
      end;
   end loop;
   
   -- Cleanup
   Close_Socket (Server_Sock);
   Finalize;
   
   Put_Line ("Server stopped");

exception
   when E : others =>
      Put_Line ("Fatal error: " & Ada.Exceptions.Exception_Message (E));
      if Is_Open (Server_Sock) then
         Close_Socket (Server_Sock);
      end if;
      if Is_Open (Client_Sock) then
         Close_Socket (Client_Sock);
      end if;
      Finalize;
end Minimal_HTTP_Server;
