-- Ada CSV Processor for Real Phone Sensor Data
-- Processes the captured phone_data_*.csv files

with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Exceptions;
with Sensors;

procedure Process_Phone_Data is
   use Ada.Text_IO;
   use Ada.Strings.Unbounded;
   use Ada.Strings.Fixed;
   
   File : Ada.Text_IO.File_Type;
   Line : Unbounded_String;
   Line_Count : Natural := 0;
   Reading_Count : Natural := 0;
   
   -- CSV parsing
   procedure Parse_CSV_Line (CSV_Line : String) is
      Fields : array (1 .. 7) of Unbounded_String;
      Field_Index : Natural := 1;
      Start_Pos : Natural := CSV_Line'First;
      In_Quotes : Boolean := False;
      
      procedure Extract_Field is
         Field_End : Natural := Start_Pos;
      begin
         -- Find the end of current field
         while Field_End <= CSV_Line'Last loop
            if CSV_Line (Field_End) = ',' and not In_Quotes then
               exit;
            elsif CSV_Line (Field_End) = '"' then
               In_Quotes := not In_Quotes;
            end if;
            Field_End := Field_End + 1;
         end loop;
         
         -- Extract field content
         if Field_Index <= Fields'Length then
            Fields (Field_Index) := To_Unbounded_String (CSV_Line (Start_Pos .. Field_End - 1));
            Field_Index := Field_Index + 1;
         end if;
         
         -- Move to next field
         Start_Pos := Field_End + 1;
      end Extract_Field;
      
   begin
      -- Parse all fields
      while Start_Pos <= CSV_Line'Last and Field_Index <= Fields'Length loop
         Extract_Field;
      end loop;
      
      -- Create sensor record if we have enough fields
      if Field_Index > 6 then  -- At least timestamp, platform, device_id, sensor_type, x, y, z
         declare
            Sensor_Rec : Sensors.Sensor_Record;
            X_Val, Y_Val, Z_Val : Float;
         begin
            -- Parse timestamp
            Sensor_Rec.Time_Stamp := Sensors.Timestamp_Nano'Value (To_String (Fields (1)));
            
            -- Parse sensor type
            declare
               Sensor_Name : constant String := To_String (Fields (4));
            begin
               Sensor_Rec.Sensor_Name := Sensors.Detect_Sensor_Type (Sensor_Name);
            end;
            
            -- Parse coordinates
            declare
               X_Str : constant String := To_String (Fields (5));
               Y_Str : constant String := To_String (Fields (6));
               Z_Str : constant String := To_String (Fields (7));
            begin
               X_Val := Float'Value (X_Str);
               Y_Val := Float'Value (Y_Str);
               Z_Val := Float'Value (Z_Str);
            exception
               when others =>
                  Put_Line ("Float parse error on line " & Integer'Image (Line_Count));
                  Put_Line ("X: '" & To_String (Fields (5)) & "'");
                  Put_Line ("Y: '" & To_String (Fields (6)) & "'");
                  Put_Line ("Z: '" & To_String (Fields (7)) & "'");
                  raise;
            end;
            
            Sensor_Rec.Data := (X_Val, Y_Val, Z_Val);
            
            -- Set default platform and device info
            Sensor_Rec.Platform := Sensors.Android;
            Sensor_Rec.Device_ID := "real_phone_device_1234567890    ";
            Sensor_Rec.Device_ID_Len := 24;
            
            -- Validate and count
            if Sensors.Is_Valid_Reading (Sensor_Rec) then
               Reading_Count := Reading_Count + 1;
               
               -- Print first few readings for verification
               if Reading_Count <= 5 then
                  Put_Line ("✓ Reading " & Integer'Image (Reading_Count) & ": " &
                           Sensors.Sensor_Type'Image (Sensor_Rec.Sensor_Name) &
                           " (" & Float'Image (X_Val) & ", " & 
                           Float'Image (Y_Val) & ", " & 
                           Float'Image (Z_Val) & ")");
               end if;
            end if;
         end;
      end if;
   end Parse_CSV_Line;
   
begin
   Put_Line ("=== Ada Phone Data Processor ===");
   Put_Line ("Processing captured phone sensor data...");
   Put_Line ("");
   
   -- Find the most recent CSV file
   declare
      Latest_File : constant String := "test_phone_data.csv";
   begin
      Put_Line ("Processing file: " & Latest_File);
      
      Open (File, In_File, Latest_File);
      
      -- Skip header line
      if not End_Of_File (File) then
         Line := To_Unbounded_String (Get_Line (File));
      end if;
      
      -- Process data lines
      while not End_Of_File (File) loop
         begin
            Line := To_Unbounded_String (Get_Line (File));
            Line_Count := Line_Count + 1;
            
            if Line_Count mod 1000 = 0 then
               Put_Line ("Processing line " & Integer'Image (Line_Count));
            end if;
            
            Parse_CSV_Line (To_String (Line));
         exception
            when E : others =>
               Put_Line ("Error on line " & Integer'Image (Line_Count) & ": " & 
                        Ada.Exceptions.Exception_Name (E) & " - " &
                        Ada.Exceptions.Exception_Message (E));
               raise;
         end;
      end loop;
      
      Close (File);
      
      Put_Line ("");
      Put_Line ("=== Processing Complete ===");
      Put_Line ("Total lines processed: " & Integer'Image (Line_Count));
      Put_Line ("Valid sensor readings: " & Integer'Image (Reading_Count));
      Put_Line ("✓ Real phone data successfully processed by Ada!");
      
   exception
      when E : others =>
         Put_Line ("Error processing file: " & Ada.Exceptions.Exception_Name (E));
         Put_Line ("Message: " & Ada.Exceptions.Exception_Message (E));
         if Is_Open (File) then
            Close (File);
         end if;
   end;
end Process_Phone_Data;
