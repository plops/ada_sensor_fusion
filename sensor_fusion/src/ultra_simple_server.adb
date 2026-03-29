-- Ultra Simple Working HTTP Server for Sensor Data
-- Minimal implementation without complex dependencies

with Ada.Text_IO;
with GNAT.Sockets;
with Ada.Exceptions;

procedure Ultra_Simple_Server is
   
   use Ada.Text_IO;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : GNAT.Sockets.Sock_Addr_Type;
   Server_Socket : GNAT.Sockets.Socket_Type;
   Client_Socket : GNAT.Sockets.Socket_Type;
   Client_Addr : GNAT.Sockets.Sock_Addr_Type;
   
begin
   Put_Line ("=== Ultra Simple Ada HTTP Server ===");
   Put_Line ("Starting server on port" & Natural'Image (Server_Port));
   Put_Line ("Target: http://localhost:" & Natural'Image (Server_Port));
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   
   -- Create and configure server socket
   GNAT.Sockets.Create_Socket (Server_Socket);
   Server_Addr.Addr := GNAT.Sockets.Inet_Addr ("127.0.0.1");
   Server_Addr.Port := GNAT.Sockets.Port_Type (Server_Port);
   
   GNAT.Sockets.Set_Socket_Option (Server_Socket, GNAT.Sockets.Socket_Level, (GNAT.Sockets.Reuse_Address, True));
   
   GNAT.Sockets.Bind_Socket (Server_Socket, Server_Addr);
   GNAT.Sockets.Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Server listening on port" & Natural'Image (Server_Port));
   
   -- Main server loop
   loop
      begin
         GNAT.Sockets.Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         Put_Line ("Client connected: " & GNAT.Sockets.Image (Client_Addr.Addr));
         
         -- Simple HTTP response using string write
         declare
            Response : constant String := 
              "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
              "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
              "Connection: close" & ASCII.CR & ASCII.LF &
              ASCII.CR & ASCII.LF &
              "Data received by Ada server";
         begin
            String'Write (GNAT.Sockets.Stream (Client_Socket), Response);
         end;
         
         GNAT.Sockets.Close_Socket (Client_Socket);
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Server error: " & Ada.Exceptions.Exception_Message (E));
      GNAT.Sockets.Close_Socket (Server_Socket);
end Ultra_Simple_Server;
