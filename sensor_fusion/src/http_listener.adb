pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Streams;
with GNATCOLL.JSON;
with AWS.Messages;
with AWS.MIME;
with AWS.Config.Set;
with AWS.Translator;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body HTTP_Listener is

   use Ada.Text_IO;
   use GNATCOLL.JSON;

   function Sensor_Data_Callback (Request : AWS.Status.Data)
     return AWS.Response.Data is
      Method : constant String := AWS.Status.Method (Request);
      URI    : constant String := AWS.Status.URI (Request);
   begin
      if Method = "POST" and then URI = "/data" then
         declare
            Request_Body : Unbounded_String;
            -- Use the built-in AWS Payload if possible, or chunked:
            Raw_Payload  : constant String := AWS.Status.Payload (Request);
         begin
            Append (Request_Body, Raw_Payload);
            Put_Line ("Received sensor data: " &
                      Natural'Image (Length (Request_Body)) & " bytes");

            return AWS.Response.Build
              (Content_Type => AWS.MIME.Text_HTML,
               Message_Body => "Data received successfully");
         end;
      else
         return AWS.Response.Build
           (Status_Code  => AWS.Messages.S404,
            Content_Type => AWS.MIME.Text_HTML,
            Message_Body => "Not Found");
      end if;
   end Sensor_Data_Callback;

   procedure Start_Server (Port : Natural := 8080) is
      Config : AWS.Config.Object;
   begin
      Put_Line ("Starting sensor data server on port" & Natural'Image (Port));
      AWS.Config.Set.Server_Port (Config, Port);
      AWS.Server.Start
        (Server,
         Callback => Sensor_Data_Callback'Access,
         Config   => Config);
      Put_Line ("Server started successfully");
   end Start_Server;

   procedure Stop_Server is
   begin
      Put_Line ("Stopping sensor data server");
      AWS.Server.Shutdown (Server);
      Put_Line ("Server stopped");
   end Stop_Server;

   procedure Parse_Sensor_JSON
     (JSON_String : String;
      Records     : out Sensors.Sensor_Record_Array;
      Count       : out Natural) is
      -- Placeholder for actual JSON logic
      pragma Unreferenced (JSON_String, Records);
   begin
      Count := 0;
   end Parse_Sensor_JSON;

   protected body Sensor_Buffer is
      entry Add_Reading (Reading : Sensors.Sensor_Record)
        when Cur_Count < 1000 is
      begin
         Head := (Head mod 1000) + 1;
         Buffer (Head) := Reading;
         Cur_Count := Cur_Count + 1;
      end Add_Reading;

      entry Get_Readings (Records : out Sensors.Sensor_Record_Array;
                          Count   : out Natural)
        when Cur_Count > 0 is
         Num_To_Get : constant Natural := Natural'Min (Cur_Count,
                                                       Records'Length);
      begin
         for I in 1 .. Num_To_Get loop
            Records (I) := Buffer ((Tail + I) mod 1000 + 1);
         end loop;
         Tail := (Tail + Num_To_Get) mod 1000;
         Cur_Count := Cur_Count - Num_To_Get;
         Count := Num_To_Get;
      end Get_Readings;
   end Sensor_Buffer;

end HTTP_Listener;
