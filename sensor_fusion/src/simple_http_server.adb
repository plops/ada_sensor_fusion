-- Simple Ada HTTP Server for Sensor Data Capture
-- Uses basic Ada networking without complex dependencies

with Ada.Text_IO;
with GNAT.Sockets;
with Ada.Streams;
with Ada.Calendar;

procedure Simple_HTTP_Server is
   use Ada.Text_IO;
   use GNAT.Sockets;
   
   Server_Port : constant := 8080;
   Server_Addr : Sock_Addr_Type;
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Client_Addr : Sock_Addr_Type;
   
   -- File for storing captured data
   Data_File : Ada.Text_IO.File_Type;
   File_Created : Boolean := False;
   
   procedure Handle_Connection (Socket : in out Socket_Type) is
      Buffer : String (1 .. 8192);
      Last : Natural;
   begin
      -- Read the HTTP request
      Receive_Socket (Socket, Buffer, Last);
      
      if Last > 0 then
         Put_Line ("=== Connection received ===");
         Put_Line ("Data length: " & Integer'Image (Last));
         
         -- Look for JSON data (simplified detection)
         for I in Buffer'First .. Last - 10 loop
            if Buffer (I .. I + 1) = "{""" then
               Put_Line ("Found JSON start at position: " & Integer'Image (I));
               
               -- Save the raw data
               if not File_Created then
                  Create (Data_File, Out_File, "captured_sensor_data.json");
                  File_Created := True;
               end if;
               
               -- Write the JSON portion
               for J in I .. Last loop
                  Put (Data_File, Buffer (J));
               end loop;
               Put_Line (Data_File);
               Flush (Data_File);
               Put_Line ("✓ Data saved to captured_sensor_data.json");
               exit;
            end if;
         end loop;
      end if;
      
      -- Send HTTP response
      declare
         Response : constant String := 
           "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
           "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
           "Connection: close" & ASCII.CR & ASCII.LF &
           ASCII.CR & ASCII.LF &
           "Data received by Ada server";
         Stream : constant Stream_Access := Stream (Socket);
      begin
         String'Write (Stream.all, Response);
      end;
   end Handle_Connection;
   
begin
   Put_Line ("=== Simple Ada HTTP Server ===");
   Put_Line ("Starting server on port 8080...");
   Put_Line ("Target: http://10.0.0.146:8080");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Initialize networking
   Initialize;
   
   -- Create and configure server socket
   Create_Socket (Server_Socket);
   Server_Addr.Addr := Addresses (Get_Host_By_Name (Inet_Addr), "10.0.0.146");
   Server_Addr.Port := Port_Type (Server_Port);
   
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
         when others =>
            Put_Line ("Error handling connection");
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Name (E));
end Simple_HTTP_Server;
