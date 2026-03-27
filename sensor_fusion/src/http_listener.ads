pragma SPARK_Mode (Off);

with AWS.Server;
with AWS.Status;
with AWS.Response;
with Sensors;

package HTTP_Listener is

   function Sensor_Data_Callback (Request : AWS.Status.Data)
     return AWS.Response.Data;

   procedure Start_Server (Port : Natural := 8080);

   procedure Stop_Server;

   Server : AWS.Server.HTTP;

private

   type Internal_Buffer is array (1 .. 1000) of Sensors.Sensor_Record;

   procedure Parse_Sensor_JSON
     (JSON_String : String;
      Records     : out Sensors.Sensor_Record_Array;
      Count       : out Natural);

   protected type Sensor_Buffer is
      entry Add_Reading (Reading : Sensors.Sensor_Record);
      entry Get_Readings (Records : out Sensors.Sensor_Record_Array;
                          Count   : out Natural);
   private
      Buffer : Internal_Buffer;
      Head   : Natural := 1;
      Tail   : Natural := 0;
      Cur_Count : Natural := 0;
   end Sensor_Buffer;

   Data_Buffer : Sensor_Buffer;

end HTTP_Listener;
