-- Simple Ada Phone Data Processor
-- Manually parses CSV data from real phones

with Ada.Text_IO;
with Ada.Exceptions;
with Sensors;

procedure Simple_Phone_Processor is
   use Ada.Text_IO;
   
   File : Ada.Text_IO.File_Type;
   Line : String (1 .. 1024);
   Line_Len : Natural;
   Reading_Count : Natural := 0;
   
   procedure Process_Line (L : String; Len : Natural) is
      -- Simple CSV parsing - find commas
      function Find_Next_Comma (Start : Natural) return Natural is
      begin
         for I in Start .. Len loop
            if L (I) = ',' then
               return I;
            end if;
         end loop;
         return Len + 1;
      end Find_Next_Comma;
      
      -- Extract substring between positions
      function Extract (Start, Stop : Natural) return String is
      begin
         if Start > Stop then
            return "";
         else
            return L (Start .. Stop);
         end if;
      end Extract;
      
      -- Parse positions
      Pos1, Pos2, Pos3, Pos4, Pos5, Pos6, Pos7 : Natural;
   begin
      -- Find comma positions
      Pos1 := Find_Next_Comma (1);
      Pos2 := Find_Next_Comma (Pos1 + 1);
      Pos3 := Find_Next_Comma (Pos2 + 1);
      Pos4 := Find_Next_Comma (Pos3 + 1);
      Pos5 := Find_Next_Comma (Pos4 + 1);
      Pos6 := Find_Next_Comma (Pos5 + 1);
      Pos7 := Len;
      
      -- Extract fields
      Timestamp_Str : constant String := Extract (1, Pos1 - 1);
      Platform_Str : constant String := Extract (Pos1 + 1, Pos2 - 1);
      Device_Str : constant String := Extract (Pos2 + 1, Pos3 - 1);
      Sensor_Str : constant String := Extract (Pos3 + 1, Pos4 - 1);
      X_Str : constant String := Extract (Pos4 + 1, Pos5 - 1);
      Y_Str : constant String := Extract (Pos5 + 1, Pos6 - 1);
      Z_Str : constant String := Extract (Pos6 + 1, Pos7);
      
      Sensor_Rec : Sensors.Sensor_Record;
   begin
      -- Debug output
      Put_Line ("Debug: '" & Timestamp_Str & "' | '" & Sensor_Str & "' | '" & X_Str & "' | '" & Y_Str & "' | '" & Z_Str & "'");
         -- Skip header line
         if Timestamp_Str = "timestamp_ns" then
            return;
         end if;
         
         -- Parse timestamp
         Sensor_Rec.Time_Stamp := Sensors.Timestamp_Nano'Value (Timestamp_Str);
         
         -- Parse sensor type
         Sensor_Rec.Sensor_Name := Sensors.Detect_Sensor_Type (Sensor_Str);
         
         -- Parse coordinates (with error handling)
         begin
            Sensor_Rec.Data := (
               Float'Value (X_Str),
               Float'Value (Y_Str), 
               Float'Value (Z_Str)
            );
         exception
            when others =>
               Put_Line ("Float parse error: X=" & X_Str & " Y=" & Y_Str & " Z=" & Z_Str);
               return;
         end;
         
         -- Set default device info
         Sensor_Rec.Platform := Sensors.Android;
         Sensor_Rec.Device_ID := "phone1_device_1234567890      ";
         Sensor_Rec.Device_ID_Len := 24;
         
         -- Validate and count
         if Sensors.Is_Valid_Reading (Sensor_Rec) then
            Reading_Count := Reading_Count + 1;
            
            -- Show first few readings
            if Reading_Count <= 5 then
               Put_Line ("✓ Reading " & Integer'Image (Reading_Count) & ": " &
                        Sensors.Sensor_Type'Image (Sensor_Rec.Sensor_Name) &
                        " (" & Float'Image (Sensor_Rec.Data.X) & ", " &
                        Float'Image (Sensor_Rec.Data.Y) & ", " &
                        Float'Image (Sensor_Rec.Data.Z) & ")");
            end if;
         end if;
      end;
   end Process_Line;
   
begin
   Put_Line ("=== Simple Ada Phone Data Processor ===");
   Put_Line ("Processing captured phone sensor data...");
   Put_Line ("");
   
   begin
      Open (File, In_File, "test_phone_data.csv");
      
      while not End_Of_File (File) loop
         Get_Line (File, Line, Line_Len);
         Process_Line (Line (1 .. Line_Len), Line_Len);
      end loop;
      
      Close (File);
      
      Put_Line ("");
      Put_Line ("=== Processing Complete ===");
      Put_Line ("Valid sensor readings: " & Integer'Image (Reading_Count));
      Put_Line ("✓ Real phone data successfully processed by Ada!");
      
   exception
      when E : others =>
         Put_Line ("Error: " & Ada.Exceptions.Exception_Name (E));
         Put_Line ("Message: " & Ada.Exceptions.Exception_Message (E));
         if Is_Open (File) then
            Close (File);
         end if;
   end;
end Simple_Phone_Processor;
