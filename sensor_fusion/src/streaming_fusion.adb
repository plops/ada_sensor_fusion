-- Streaming Fusion Pipeline
-- Real-time sensor fusion with streaming output

pragma SPARK_Mode (Off);

with Ada.Text_IO;
with Ada.Exceptions;
with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Streams;
with GNAT.Sockets;
with Ada.Numerics.Elementary_Functions;

procedure Streaming_Fusion is
   
   use Ada.Text_IO;
   use Ada.Calendar;
   use Ada.Numerics.Elementary_Functions;
   use Ada.Streams;
   
   -- Server configuration
   Server_Port : constant := 8080;
   Server_Addr : GNAT.Sockets.Sock_Addr_Type;
   Server_Socket : GNAT.Sockets.Socket_Type;
   Client_Socket : GNAT.Sockets.Socket_Type;
   Client_Addr : GNAT.Sockets.Sock_Addr_Type;
   
   -- Fusion state
   type Fusion_State is record
      Q_X, Q_Y, Q_Z, Q_W : Float := 0.0;  -- Quaternion
      Bias_X, Bias_Y, Bias_Z : Float := 0.0;  -- Gyro bias
      Last_Update : Time := Clock;
      Is_Initialized : Boolean := False;
   end record;
   
   Fusion_Data : Fusion_State;
   
   -- Sensor data record
   type Sensor_Reading is record
      Timestamp : Long_Integer;
      Accel_X, Accel_Y, Accel_Z : Float;
      Gyro_X, Gyro_Y, Gyro_Z : Float;
      Valid : Boolean := False;
   end record;
   
   -- Function to extract JSON from HTTP request
   function Extract_JSON_Body (Request : String) return String is
      Body_Start : Natural := Request'First;
   begin
      -- Find the end of HTTP headers (double CRLF)
      for I in Request'First .. Request'Last - 3 loop
         if Request (I) = ASCII.CR and Request (I + 1) = ASCII.LF and
            Request (I + 2) = ASCII.CR and Request (I + 3) = ASCII.LF then
            Body_Start := I + 4;
            exit;
         end if;
      end loop;
      
      if Body_Start <= Request'Last then
         return Request (Body_Start .. Request'Last);
      else
         return "";
      end if;
   end Extract_JSON_Body;
   
   -- Simple fusion update (complementary filter)
   procedure Update_Fusion 
     (State : in out Fusion_State;
      Accel : in Sensor_Reading;
      Gyro  : in Sensor_Reading)
   is
      DT : Float;
      Alpha : constant Float := 0.98;  -- Complementary filter coefficient
      Norm_Factor : Float;
      Q_Mag : Float;
      Accel_Mag : Float;
      Time_Diff : Duration;
   begin
      if not State.Is_Initialized then
         -- Initialize with accelerometer orientation
         State.Q_W := 1.0;
         State.Q_X := 0.0;
         State.Q_Y := 0.0;
         State.Q_Z := 0.0;
         State.Is_Initialized := True;
         State.Last_Update := Clock;
         return;
      end if;
      
      -- Calculate time delta
      Time_Diff := Clock - State.Last_Update;
      DT := Float (Time_Diff);
      State.Last_Update := Clock;
      
      if DT > 0.0 and DT < 0.2 then
         -- Simple complementary filter
         Accel_Mag := Accel.Accel_X**2 + Accel.Accel_Y**2 + Accel.Accel_Z**2;
         Norm_Factor := 1.0;
         if Accel_Mag > 0.01 then
            Norm_Factor := 1.0 / Sqrt (Accel_Mag);
         end if;
         
         -- Update quaternion with gyroscope (prediction)
         State.Q_X := State.Q_X + 0.5 * DT * (Gyro.Gyro_X - State.Bias_X);
         State.Q_Y := State.Q_Y + 0.5 * DT * (Gyro.Gyro_Y - State.Bias_Y);
         State.Q_Z := State.Q_Z + 0.5 * DT * (Gyro.Gyro_Z - State.Bias_Z);
         
         -- Normalize quaternion
         Q_Mag := State.Q_X**2 + State.Q_Y**2 + State.Q_Z**2 + State.Q_W**2;
         if Q_Mag > 0.01 then
            Norm_Factor := 1.0 / Sqrt (Q_Mag);
            State.Q_X := State.Q_X * Norm_Factor;
            State.Q_Y := State.Q_Y * Norm_Factor;
            State.Q_Z := State.Q_Z * Norm_Factor;
            State.Q_W := State.Q_W * Norm_Factor;
         end if;
         
         -- Update bias estimate
         State.Bias_X := State.Bias_X * 0.99 + Gyro.Gyro_X * 0.01;
         State.Bias_Y := State.Bias_Y * 0.99 + Gyro.Gyro_Y * 0.01;
         State.Bias_Z := State.Bias_Z * 0.99 + Gyro.Gyro_Z * 0.01;
      end if;
   end Update_Fusion;
   
   -- Function to parse sensor data from JSON
   procedure Parse_Sensor_JSON 
     (JSON_String : in String;
      Accel_Data  : out Sensor_Reading;
      Gyro_Data   : out Sensor_Reading)
   is
      function Extract_Field (Field_Name : String; JSON : String) return String is
         Start_Pattern : constant String := """" & Field_Name & """:";
         Start_Pos : Natural := JSON'First - 1;
         End_Pos   : Natural := JSON'First - 1;
      begin
         -- Find field start
         for I in JSON'First .. JSON'Last - Start_Pattern'Length loop
            if JSON (I .. I + Start_Pattern'Length - 1) = Start_Pattern then
               Start_Pos := I + Start_Pattern'Length;
               exit;
            end if;
         end loop;
         
         if Start_Pos >= JSON'First then
            -- Find field end (next comma or brace)
            for J in Start_Pos .. JSON'Last loop
               if JSON (J) = ',' or JSON (J) = '}' then
                  End_Pos := J - 1;
                  exit;
               end if;
            end loop;
            
            if End_Pos > Start_Pos then
               -- Remove quotes and spaces
               while Start_Pos <= End_Pos and then 
                     (JSON (Start_Pos) = ' ' or JSON (Start_Pos) = '"') loop
                  Start_Pos := Start_Pos + 1;
               end loop;
               
               while End_Pos >= Start_Pos and then 
                     (JSON (End_Pos) = ' ' or JSON (End_Pos) = '"') loop
                  End_Pos := End_Pos - 1;
               end loop;
               
               if Start_Pos <= End_Pos then
                  return JSON (Start_Pos .. End_Pos);
               end if;
            end if;
         end if;
         
         return "";
      end Extract_Field;
      
      function Extract_Float (Field_Name : String; JSON : String) return Float is
         Field_Value : constant String := Extract_Field (Field_Name, JSON);
      begin
         if Field_Value'Length > 0 then
            return Float'Value (Field_Value);
         else
            return 0.0;
         end if;
      exception
         when others =>
            return 0.0;
      end Extract_Float;
      
      function Extract_Long_Integer (Field_Name : String; JSON : String) return Long_Integer is
         Field_Value : constant String := Extract_Field (Field_Name, JSON);
      begin
         if Field_Value'Length > 0 then
            return Long_Integer'Value (Field_Value);
         else
            return 0;
         end if;
      exception
         when others =>
            return 0;
      end Extract_Long_Integer;
      
      Sensor_Name : constant String := Extract_Field ("name", JSON_String);
      Time_Stamp  : constant Long_Integer := Extract_Long_Integer ("time", JSON_String);
      Accel_X     : constant Float := Extract_Float ("x", JSON_String);
      Accel_Y     : constant Float := Extract_Float ("y", JSON_String);
      Accel_Z     : constant Float := Extract_Float ("z", JSON_String);
      
   begin
      -- Initialize outputs
      Accel_Data := (0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, False);
      Gyro_Data := (0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, False);
      
      -- Parse based on sensor type
      if Sensor_Name = "accelerometer" then
         Accel_Data := (
            Timestamp => Time_Stamp,
            Accel_X => Accel_X,
            Accel_Y => Accel_Y,
            Accel_Z => Accel_Z,
            Gyro_X => 0.0,
            Gyro_Y => 0.0,
            Gyro_Z => 0.0,
            Valid => True
         );
         
      elsif Sensor_Name'Length >= 5 and then Sensor_Name (Sensor_Name'First .. Sensor_Name'First + 4) = "gyro" then
         Gyro_Data := (
            Timestamp => Time_Stamp,
            Accel_X => 0.0,
            Accel_Y => 0.0,
            Accel_Z => 0.0,
            Gyro_X => Accel_X,  -- X field contains gyro X
            Gyro_Y => Accel_Y,  -- Y field contains gyro Y
            Gyro_Z => Accel_Z,  -- Z field contains gyro Z
            Valid => True
         );
      end if;
   end Parse_Sensor_JSON;
   
   -- Function to handle client connection
   procedure Handle_Connection (Client_Socket : GNAT.Sockets.Socket_Type) is
      Buffer : Ada.Streams.Stream_Element_Array (1 .. 8192);
      Last    : Ada.Streams.Stream_Element_Offset;
      Client_IP : constant String := GNAT.Sockets.Image (Client_Addr.Addr);
      
      Current_Accel : Sensor_Reading;
      Current_Gyro  : Sensor_Reading;
   begin
      -- Read data from client
      begin
         GNAT.Sockets.Receive_Socket (Client_Socket, Buffer, Last);
      exception
         when others =>
            return;
      end;
      
      if Last > Buffer'First then
         declare
            Request : String (1 .. Natural (Last));
         begin
            -- Convert stream elements to characters
            for I in Request'Range loop
               Request (I) := Character'Val (Buffer (Ada.Streams.Stream_Element_Offset (I)));
            end loop;
            
            Put_Line ("[" & Ada.Calendar.Formatting.Image (Clock) & "] Received " & 
                     Natural'Image (Natural (Last)) & " bytes from " & Client_IP);
            
            -- Extract and parse JSON
            declare
               JSON_Body : constant String := Extract_JSON_Body (Request);
            begin
               if JSON_Body'Length > 0 then
                  Parse_Sensor_JSON (JSON_Body, Current_Accel, Current_Gyro);
                  
                  -- Update fusion with new data
                  if Current_Accel.Valid or Current_Gyro.Valid then
                     Update_Fusion (Fusion_Data, Current_Accel, Current_Gyro);
                     
                     -- Stream fusion output
                     Put_Line ("=== FUSION FILTER OUTPUT ===");
                     Put_Line ("Timestamp: " & Ada.Calendar.Formatting.Image (Clock));
                     Put_Line ("Quaternion: [" & 
                               Float'Image (Fusion_Data.Q_X) & ", " &
                               Float'Image (Fusion_Data.Q_Y) & ", " &
                               Float'Image (Fusion_Data.Q_Z) & ", " &
                               Float'Image (Fusion_Data.Q_W) & "]");
                     Put_Line ("Gyro Bias: [" &
                               Float'Image (Fusion_Data.Bias_X) & ", " &
                               Float'Image (Fusion_Data.Bias_Y) & ", " &
                               Float'Image (Fusion_Data.Bias_Z) & "]");
                     
                     -- Calculate Euler angles for readability
                     declare
                        -- Simple quaternion to Euler conversion
                        Roll  : Float;
                        Pitch : Float;
                        Yaw   : Float;
                     begin
                        Roll := 2.0 * (Fusion_Data.Q_W * Fusion_Data.Q_X + 
                                       Fusion_Data.Q_Y * Fusion_Data.Q_Z);
                        Pitch := 2.0 * (Fusion_Data.Q_W * Fusion_Data.Q_Y - 
                                        Fusion_Data.Q_X * Fusion_Data.Q_Z);
                        Yaw := 2.0 * (Fusion_Data.Q_W * Fusion_Data.Q_Z + 
                                      Fusion_Data.Q_X * Fusion_Data.Q_Y);
                        
                        Put_Line ("Euler Angles: Roll=" & Float'Image (Roll) &
                                 "°, Pitch=" & Float'Image (Pitch) &
                                 "°, Yaw=" & Float'Image (Yaw) & "°");
                     end;
                     
                     Put_Line ("==========================");
                  end if;
               end if;
            end;
         end;
      end if;
      
      -- Send HTTP response
      declare
         Response : constant String := 
           "HTTP/1.1 200 OK" & ASCII.CR & ASCII.LF &
           "Content-Type: text/plain" & ASCII.CR & ASCII.LF &
           "Connection: close" & ASCII.CR & ASCII.LF &
           ASCII.CR & ASCII.LF &
           "Fusion data processed and streamed to console";
      begin
         String'Write (GNAT.Sockets.Stream (Client_Socket), Response);
      end;
   end Handle_Connection;
   
begin
   Put_Line ("=== Streaming Fusion Pipeline ===");
   Put_Line ("Real-time sensor fusion with streaming output");
   Put_Line ("");
   
   -- Create and configure server socket
   GNAT.Sockets.Create_Socket (Server_Socket);
   Server_Addr.Addr := GNAT.Sockets.Inet_Addr ("10.0.0.146");
   Server_Addr.Port := GNAT.Sockets.Port_Type (Server_Port);
   
   GNAT.Sockets.Set_Socket_Option (Server_Socket, GNAT.Sockets.Socket_Level, (GNAT.Sockets.Reuse_Address, True));
   
   GNAT.Sockets.Bind_Socket (Server_Socket, Server_Addr);
   GNAT.Sockets.Listen_Socket (Server_Socket);
   
   Put_Line ("✓ Fusion server listening on port" & Natural'Image (Server_Port));
   Put_Line ("✓ Fusion filter initialized");
   Put_Line ("✓ Streaming output enabled");
   Put_Line ("");
   Put_Line ("Send sensor data to: http://10.0.0.146:" & Natural'Image (Server_Port));
   Put_Line ("Output: Real-time quaternion and Euler angles");
   Put_Line ("Press Ctrl+C to stop");
   Put_Line ("");
   Put_Line ("=== WAITING FOR SENSOR DATA ===");
   
   -- Main server loop
   loop
      begin
         GNAT.Sockets.Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
         
         -- Handle connection in current thread (simplified)
         Handle_Connection (Client_Socket);
         
         GNAT.Sockets.Close_Socket (Client_Socket);
         
      exception
         when E : others =>
            Put_Line ("Error handling connection: " & Ada.Exceptions.Exception_Message (E));
      end;
   end loop;
   
exception
   when E : others =>
      Put_Line ("Fusion server error: " & Ada.Exceptions.Exception_Message (E));
      GNAT.Sockets.Close_Socket (Server_Socket);
end Streaming_Fusion;
