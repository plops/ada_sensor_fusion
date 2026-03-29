-- Sensor Fusion Main Program
-- Step 1: Basic Data Reception and Validation

with Ada.Text_IO;
with Ada.Text_IO.Unbounded;
with HTTP_Listener;
with Sensors;
with GNAT.Sockets;
with Ada.Exceptions;
with GNAT.OS_Lib;

procedure Sensor_Fusion is
begin
   Ada.Text_IO.Put_Line ("Sensor Fusion Engine Starting...");
   Ada.Text_IO.Put_Line ("Step 1: Basic Data Reception and Validation");

   -- Start the HTTP server to receive sensor data
   begin
      HTTP_Listener.Start_Server (Port => 8080);
   exception
      when E : others =>
         Ada.Text_IO.Put_Line ("ERROR: Failed to start server on port 8080");
         Ada.Text_IO.Put_Line ("ERROR: " & Ada.Exceptions.Exception_Message (E));
         
         -- Check for port conflicts
         declare
            Sock_Addr : Sock_Addr_Type;
            Is_Connected : Boolean;
         begin
            Sock_Addr := (Family => Family_Inet,
                           Addr  => Inet_Addr ("127.0.0.1"),
                           Port => 8080);
            
            -- Try to create a socket to test if port is available
            declare
               Test_Socket : Socket_Type;
            begin
               Create_Socket (Test_Socket, Family_Inet, Socket_Stream);
               Connect_Socket (Test_Socket, Sock_Addr);
               Is_Connected := True;
               Close_Socket (Test_Socket);
            exception
               when others =>
                  Is_Connected := False;
            end;
            
            if Is_Connected then
               Ada.Text_IO.Put_Line ("ERROR: Port 8080 is already in use by another process");
               Ada.Text_IO.Put_Line ("ERROR: Attempting to identify conflicting process...");
               
               -- Try to find process using port
               declare
                  Command : constant String := "netstat -tlnp 2>/dev/null | grep :8080";
                  Result   : Integer;
               begin
                  Ada.Text_IO.Put_Line ("INFO: Checking for processes using port 8080...");
                  Result := GNAT.OS_Lib.Spawn (Command_String => Command);
                  Ada.Text_IO.Put_Line ("INFO: Please stop any conflicting processes and try again");
               end;
            else
               Ada.Text_IO.Put_Line ("Server running on http://localhost:8080");
               Ada.Text_IO.Put_Line ("Send POST requests to /data endpoint");
               Ada.Text_IO.Put_Line ("Press Ctrl+C to stop");
               
               -- Keep server running
               loop
                  delay 1.0;
               end loop;
            end if;
         end;
   end;

exception
   when others =>
      HTTP_Listener.Stop_Server;
      Ada.Text_IO.Put_Line ("Server stopped");
end Sensor_Fusion;
