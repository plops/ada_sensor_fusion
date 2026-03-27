-- Sensor Fusion Main Program
-- Step 1: Basic Data Reception and Validation

with Ada.Text_IO;
with HTTP_Listener;
with Sensors;

procedure Sensor_Fusion is
begin
   Ada.Text_IO.Put_Line ("Sensor Fusion Engine Starting...");
   Ada.Text_IO.Put_Line ("Step 1: Basic Data Reception and Validation");

   -- Start the HTTP server to receive sensor data
   HTTP_Listener.Start_Server (Port => 8080);

   Ada.Text_IO.Put_Line ("Server running on http://localhost:8080");
   Ada.Text_IO.Put_Line ("Send POST requests to /data endpoint");
   Ada.Text_IO.Put_Line ("Press Ctrl+C to stop");

   -- Keep server running
   loop
      delay 1.0;
   end loop;

exception
   when others =>
      HTTP_Listener.Stop_Server;
      Ada.Text_IO.Put_Line ("Server stopped");
end Sensor_Fusion;
