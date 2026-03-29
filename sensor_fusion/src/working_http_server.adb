-- Working HTTP Server for Sensor Data
-- Minimal implementation without complex dependencies

with Ada.Text_IO;
with GNAT.Sockets;
with Ada.Streams;
with Ada.Exceptions;

procedure Working_HTTP_Server is
   use Ada.Text_IO;
   use GNAT.Sockets;
   use Ada.Streams;
   
   Server_Port : constant := 8080;
   Server_Addr : Sock_Addr_Type;
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Client_Addr : Sock_Addr_Type;
   
   -- File for storing captured data
   Data_File : Ada.Text_IO.File_Type;
   File_Created : Boolean := False;
   
   procedure Handle_Connection (Socket : in out Socket_Type) is
      Buffer : Stream_Element_Array (1 .. 8192);
      Last : Stream_Element_Offset;
   begin
      -- Read the HTTP request
      Receive_Socket (Socket, Buffer, Last);
      
      if Last > 0 then
         Put_Line ("=== Connection received ===");
         Put_Line ("Data length: " & Stream_Element_Offset'Image (Last));
         
         -- Convert to string for processing
         declare
            Request_String : String (1 .. Integer (Last));
            for Request_String'Address use Buffer'Address;
         begin
            Put_Line ("Request preview: " & Request_String (1 .. Integer'Min (100, Integer (Last))));
            
            -- Look for JSON data (simplified detection)
            for I in 1 .. Integer (Last) - 10 loop
               if Request_String (I .. I + 1) = "{""" then
                  Put_Line ("Found JSON start at position: " & Integer'Image (I));
                  
                  -- Save the raw data
                  if not File_Created then
                     Create (Data_File, Out_File, "captured_sensor_data.json");
                     File_Created := True;
                  end if;
                  
                  -- Write the JSON portion
                  for J in I .. Integer (Last) loop
                     Put (Data_File, Request_String (J));
                  end loop;
                  New_Line (Data_File);
                  Flush (Data_File);
                  Put_Line ("✓ Data saved to captured_sensor_data.json");
                  exit;
               end if;
            end loop;
         end;
      end if;
      
      -- Send HTTP response
      declare
         Response : constant String := 
           "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
           "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
           "Connection: close" & ASCII.CR & ASCII.LF &
           ASCII.CR & ASCII.LF &
           "Data received by Ada server";
         Resp_Stream : constant Stream_Access := Stream (Socket);
      begin
         String'Write (Resp_Stream, Response);
      end;
   end Handle_Connection;
   
begin
   Put_Line ("=== Working Ada HTTP Server ===");
   Put_Line ("Starting server on port 8080...");
   Put_Line ("Target: http://localhost:8080");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Create and configure server socket
   Create_Socket (Server_Socket);
   Server_Addr.Addr := Inet_Addr ("127.0.0.1");
   Server_Addr.Port := Port_Type (Server_Port);
   
   Set_Socket_Option (Server_Socket, Socket_Level, (Reuse_Address, True));
   
   Bind_Socket (Server_Socket, Server_Addr);
   Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Server listening on port 8080");
   
   -- Main server loop
   loop
      begin
         Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         Put_Line ("Client connected: " & Image (Client_Addr.Addr));
         
         Handle_Connection (Client_Socket);
         
         Close_Socket (Client_Socket);
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Message (E));
      if Is_Open (Data_File) then
         Close (Data_File);
      end if;
end Working_HTTP_Server;
