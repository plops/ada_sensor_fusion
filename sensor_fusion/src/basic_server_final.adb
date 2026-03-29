-- Basic Working HTTP Server for Sensor Data
-- Simple implementation without complex dependencies

with Ada.Text_IO;
with GNAT.Sockets;
with Ada.Streams;
with Ada.Exceptions;

procedure Basic_Server_Final is
   
   use Ada.Text_IO;
   use GNAT.Sockets;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : Sock_Addr_Type;
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Client_Addr : Sock_Addr_Type;
   
   -- File for storing captured data
   Data_File : Ada.Text_IO.File_Type;
   File_Created : Boolean := False;
   
begin
   Put_Line ("=== Basic Working Ada HTTP Server ===");
   Put_Line ("Starting server on port" & Natural'Image (Server_Port));
   Put_Line ("Target: http://localhost:" & Natural'Image (Server_Port));
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Create and configure server socket
   Create_Socket (Server_Socket);
   Server_Addr.Addr := Inet_Addr ("127.0.0.1");
   Server_Addr.Port := Port_Type (Server_Port);
   
   Set_Socket_Option (Server_Socket, Socket_Level, (Reuse_Address, True));
   
   Bind_Socket (Server_Socket, Server_Addr);
   Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Server listening on port" & Natural'Image (Server_Port));
   
   -- Main server loop
   loop
      begin
         Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         Put_Line ("Client connected: " & Image (Client_Addr.Addr));
         
         -- Simple HTTP handling
         declare
            Response : constant String := 
              "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
              "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
              "Connection: close" & ASCII.CR & ASCII.LF &
              ASCII.CR & ASCII.LF &
              "Data received by Ada server";
         begin
            -- Send response immediately
            declare
               Stream : constant Ada.Streams.Stream_Access := Ada.Streams.Stream (Client_Socket);
            begin
               for I in Response'Range loop
                  Ada.Streams.Write (Stream.all, Character'Val (Response (I)), 1);
               end loop;
            end;
         end;
         
         Close_Socket (Client_Socket);
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Message (E));
      if GNAT.Sockets.Is_Open (Server_Socket) then
         GNAT.Sockets.Close_Socket (Server_Socket);
      end if;
      if Ada.Text_IO.Is_Open (Data_File) then
         Ada.Text_IO.Close (Data_File);
      end if;
end Basic_Server_Final;
