-- Basic HTTP Server for Sensor Data Reception
-- No external dependencies - uses only standard Ada libraries

with Ada.Text_IO;
with Ada.Text_IO.Unbounded_IO;
with GNAT.Sockets;
with Ada.Strings.Unbounded;
with Ada.Exceptions;
with Ada.Calendar;
with GNAT.OS_Lib;

procedure Basic_HTTP_Server is

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
   CRLF : constant String := (1 => ASCII.CR, 2 => ASCII.LF);

   -- Simple HTTP response helper
   function Build_HTTP_Response 
     (Status_Code : String;
      Content_Type : String;
      Body_Str : String) return String
   is
      Response : Unbounded_String;
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

   -- Simple JSON parser for sensor data
   procedure Process_Sensor_Data (Data : String) is
      use Ada.Calendar;
      
      File : Ada.Text_IO.File_Type;
      Filename : String (1 .. 50);
      Now : constant Time := Clock;
      Line_Count : Natural := 0;
      
      -- Simple parsing to extract basic sensor info
      function Extract_JSON_Field (Data : String; Field : String) return String is
         Search_Str : constant String := """" & Field & """:";
         Pos : Natural := Ada.Strings.Fixed.Index (Data, Search_Str);
         Start_Pos : Natural;
         End_Pos : Natural;
      begin
         if Pos = 0 then
            return "";
         end if;
         
         Start_Pos := Pos + Search_Str'Length;
         
         -- Skip whitespace
         while Start_Pos <= Data'Last and then 
               (Data (Start_Pos) = ' ' or else Data (Start_Pos) = ASCII.HT) loop
            Start_Pos := Start_Pos + 1;
         end loop;
         
         -- Handle string values
         if Data (Start_Pos) = '"' then
            Start_Pos := Start_Pos + 1;
            End_Pos := Start_Pos;
            while End_Pos <= Data'Last and then Data (End_Pos) /= '"' loop
               End_Pos := End_Pos + 1;
            end loop;
            return Data (Start_Pos .. End_Pos - 1);
         else
            -- Handle numeric values
            End_Pos := Start_Pos;
            while End_Pos <= Data'Last and then 
                  ((Data (End_Pos) >= '0' and then Data (End_Pos) <= '9') or else
                   Data (End_Pos) = '.' or else Data (End_Pos) = '-' or else
                   Data (End_Pos) = 'e' or else Data (End_Pos) = 'E') loop
               End_Pos := End_Pos + 1;
            end loop;
            return Data (Start_Pos .. End_Pos - 1);
         end if;
      end Extract_JSON_Field;
      
   begin
      Put_Line ("Processing sensor data: " & Natural'Image (Data'Length) & " bytes");
      
      -- Show first 100 characters for debugging
      if Data'Length > 0 then
         declare
            Show_Length : constant Natural := Natural'Min (Data'Length, 100);
         begin
            Put_Line ("Data preview: " & Data (Data'First .. Data'First + Show_Length - 1));
         end;
      end if;
      
      -- Check if this looks like sensor data
      if Ada.Strings.Fixed.Index (Data, "payload") > 0 then
         Put_Line ("Detected sensor data payload");
         
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
            Put_Line (File, "timestamp_raw,data_preview");
            
            -- Write a summary line
            declare
               Preview : constant String := 
                 (if Data'Length > 50 then Data (Data'First .. Data'First + 49) & "..."
                  else Data);
            begin
               Put_Line (File, Long_Integer'Image (To_Long_Integer (Now)) & "," & Preview);
            end;
            
            Close (File);
            Put_Line ("Wrote data summary to " & Filename (1 .. Filename_Len));
         end;
      else
         Put_Line ("Data does not appear to be sensor data");
      end if;
      
   exception
      when E : others =>
         Put_Line ("Error processing sensor data: " & Ada.Exceptions.Exception_Message (E));
   end Process_Sensor_Data;

   -- Parse HTTP request to extract method, URI, and request_body
   procedure Parse_HTTP_Request 
     (Request : String;
      Method : out Unbounded_String;
      URI : out Unbounded_String;
      Request_Body : out Unbounded_String)
   is
      Lines : array (1 .. 100) of Unbounded_String;
      Line_Count : Natural := 0;
      Current_Line : Unbounded_String;
      Header_End : Natural := 0;
   begin
      Method := To_Unbounded_String ("");
      URI := To_Unbounded_String ("");
      Request_Body := To_Unbounded_String ("");
      
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
      
      -- Extract request_body if present
      if Header_End > 0 and then Header_End <= Request'Last then
         Request_Body := To_Unbounded_String (Request (Header_End .. Request'Last));
      end if;
   end Parse_HTTP_Request;

begin
   Put_Line ("Basic HTTP Server for Sensor Data");
   Put_Line ("==================================");
   Put_Line ("No external dependencies - pure Ada implementation");
   Put_Line ("");
   
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
                  Method, URI, Request_Body : Unbounded_String;
                  Response : String;
               begin
                  -- Parse HTTP request
                  Parse_HTTP_Request (Request, Method, URI, Request_Body);
                  
                  Put_Line ("Request: " & To_String (Method) & " " & To_String (URI));
                  
                  -- Handle different endpoints
                  if To_String (Method) = "POST" and then To_String (URI) = "/data" then
                     Process_Sensor_Data (To_String (Request_Body));
                     Response := Build_HTTP_Response ("200 OK", "text/plain", "Data received successfully");
                  elsif To_String (Method) = "GET" and then To_String (URI) = "/" then
                     Response := Build_HTTP_Response ("200 OK", "text/html", 
                        "<html><body><h1>Basic Sensor Data Server</h1>" &
                        "<p>Send POST requests to /data endpoint</p>" &
                        "<p>No external dependencies - pure Ada implementation</p></body></html>");
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
end Basic_HTTP_Server;
