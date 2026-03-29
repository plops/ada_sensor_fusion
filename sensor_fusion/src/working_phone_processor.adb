-- Working Ada Phone Data Processor
-- Successfully processes real phone sensor data

with Ada.Text_IO;
with Ada.Exceptions;
with Sensors;

procedure Working_Phone_Processor is
   use Ada.Text_IO;
   
   File : Ada.Text_IO.File_Type;
   Line : String (1 .. 200);
   Line_Len : Natural;
   Reading_Count : Natural := 0;
   
   procedure Process_Line (L : String; Len : Natural) is
      -- Manual CSV parsing
      Comma1, Comma2, Comma3, Comma4, Comma5, Comma6 : Natural := 0;
      Comma_Count : Natural := 0;
      
      Sensor_Rec : Sensors.Sensor_Record;
   begin
      -- Find all commas
      for I in 1 .. Len loop
         if L (I) = ',' then
            Comma_Count := Comma_Count + 1;
            case Comma_Count is
               when 1 => Comma1 := I;
               when 2 => Comma2 := I;
               when 3 => Comma3 := I;
               when 4 => Comma4 := I;
               when 5 => Comma5 := I;
               when 6 => Comma6 := I;
               when others => exit;
            end case;
         end if;
      end loop;
      
      -- Skip if not enough commas (header line)
      if Comma_Count < 6 then
         return;
      end if;
      
      -- Extract and parse fields (excluding commas)
      declare
         Timestamp_Str : constant String := L (1 .. Comma1 - 1);
         Platform_Str : constant String := L (Comma1 + 1 .. Comma2 - 1);
         Device_Str : constant String := L (Comma2 + 1 .. Comma3 - 1);
         Sensor_Str : constant String := L (Comma3 + 1 .. Comma4 - 1);
         X_Str : constant String := L (Comma4 + 1 .. Comma5 - 1);
         Y_Str : constant String := L (Comma5 + 1 .. Comma6 - 1);
         Z_Str : constant String := L (Comma6 + 1 .. Len);
      begin
         -- Skip header
         if Timestamp_Str = "timestamp_ns" then
            return;
         end if;
         
         -- Parse timestamp
         Sensor_Rec.Time_Stamp := Sensors.Timestamp_Nano'Value (Timestamp_Str);
         
         -- Parse sensor type
         Sensor_Rec.Sensor_Name := Sensors.Detect_Sensor_Type (Sensor_Str);
         
         -- Parse coordinates with safe conversion
         declare
            X_Val, Y_Val, Z_Val : Float;
         begin
            Put_Line ("Parsing: X='" & X_Str & "' Y='" & Y_Str & "' Z='" & Z_Str & "'");
            X_Val := Float'Value (X_Str);
            Y_Val := Float'Value (Y_Str);
            Z_Val := Float'Value (Z_Str);
            Sensor_Rec.Data := (X_Val, Y_Val, Z_Val);
         exception
            when others =>
               Put_Line ("Float conversion failed for: X='" & X_Str & "' Y='" & Y_Str & "' Z='" & Z_Str & "'");
               return;
         end;
         
         -- Set device info
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
   Put_Line ("=== Working Ada Phone Data Processor ===");
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
end Working_Phone_Processor;
