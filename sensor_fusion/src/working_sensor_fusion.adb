-- Working Ada HTTP Server without AWS dependencies
-- Uses GNAT.Sockets for basic HTTP server functionality

with Ada.Text_IO;
with Ada.Calendar;
with GNAT.Sockets;
with Ada.Streams;
with Ada.Strings.Unbounded;

procedure Working_Sensor_Fusion is
   use Ada.Text_IO;
   use Ada.Calendar;
   use GNAT.Sockets;
   use Ada.Strings.Unbounded;
   
   -- HTTP response constants
   HTTP_OK : constant String := "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF;
   Content_Type : constant String := "Content-Type: text/plain" & ASCII.CR & ASCII.LF;
   Connection_Close : constant String := "Connection: close" & ASCII.CR & ASCII.LF;
   Empty_Line : constant String := ASCII.CR & ASCII.LF;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : Sock_Addr_Type;
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Client_Addr : Sock_Addr_Type;
   
   -- File for storing sensor data
   Data_File : Ada.Text_IO.File_Type;
   File_Created : Boolean := False;
   
   procedure Process_HTTP_Request (Request : String) is
   begin
      Put_Line ("Received HTTP Request:");
      Put_Line ("Length: " & Integer'Image (Request'Length));
      Put_Line ("First 100 chars: " & Request (Request'First .. Request'First + 99));
      
      -- Look for JSON data in POST request
      if Request'Length > 100 and then 
         Request (Request'First .. Request'First + 3) = "POST" then
         
         -- Find the start of JSON data (after headers)
         Json_Start : Natural := Request'First;
         while Json_Start <= Request'Last and then 
               Request (Json_Start .. Json_Start + 3) /= "{   " loop
            Json_Start := Json_Start + 1;
         end loop;
         
         if Json_Start <= Request'Last then
            declare
               Json_Data : constant String := Request (Json_Start .. Request'Last);
            begin
               Put_Line ("Found JSON data:");
               Put_Line (Json_Data (Json_Data'First .. Json_Data'First + 200) & "...");
               
               -- Save to file for later processing
               if not File_Created then
                  Create (Data_File, Out_File, "captured_sensor_data.json");
                  File_Created := True;
               end if;
               
               Put_Line (Data_File, Json_Data);
               Flush (Data_File);
               Put_Line ("✓ Data saved to captured_sensor_data.json");
            end;
         end if;
      end if;
   end Process_HTTP_Request;
   
   procedure Send_HTTP_Response (Socket : in out Socket_Type) is
      Response : constant String := 
        HTTP_OK & 
        Content_Type & 
        Connection_Close & 
        Empty_Line &
        "Data received by Ada sensor fusion server";
   begin
      -- Send response
      declare
         Stream : constant Stream_Access := Stream (Socket);
      begin
         String'Write (Stream.all, Response);
      end;
   end Send_HTTP_Response;
   
begin
   Put_Line ("=== Ada Sensor Fusion Server (Working Version) ===");
   Put_Line ("Starting HTTP server on port 8080...");
   Put_Line ("Target URL: http://10.0.0.146:8080/data");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Initialize server
   Initialize;
   
   -- Create server socket
   Create_Socket (Server_Socket);
   
   -- Set up server address
   Server_Addr.Addr := Addresses (Get_Host_By_Name (Inet_Addr), "10.0.0.146");
   Server_Addr.Port := Port_Type (Server_Port);
   
   -- Bind socket to address
   Bind_Socket (Server_Socket, Server_Addr);
   
   -- Listen for connections
   Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Server listening on port 8080");
   Put_Line ("Waiting for phone connections...");
   
   -- Main server loop
   loop
      begin
         -- Accept connection
         Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         
         Put_Line ("=== Connection from " & Image (Client_Addr.Addr) & " ===");
         
         -- Read request
         declare
            Request : Unbounded_String;
            Buffer : String (1 .. 4096);
            Last : Natural;
         begin
            loop
               Receive_Socket (Client_Socket, Buffer, Last);
               exit when Last = 0;
               
               Append (Request, Buffer (1 .. Last));
               
               -- Look for end of HTTP headers
               if Length (Request) > 4 and then
                  Slice (Request, Length (Request) - 3, Length (Request)) = ASCII.CR & ASCII.LF & ASCII.CR & ASCII.LF then
                  exit;
               end if;
            end loop;
            
            -- Process the request
            Process_HTTP_Request (To_String (Request));
            
            -- Send response
            Send_HTTP_Response (Client_Socket);
         end;
         
         -- Close client socket
         Close_Socket (Client_Socket);
         
      exception
         when others =>
            Put_Line ("Error handling connection");
      end;
   end loop;
   
exception
   when others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Name (Ada.Exceptions.Exception_Occurrence));
end Working_Sensor_Fusion;
