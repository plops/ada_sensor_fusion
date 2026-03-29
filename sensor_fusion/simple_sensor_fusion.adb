-- Simplified Sensor Fusion Server (No AWS)
-- For testing when AWS dependencies are unavailable

with Ada.Text_IO;
with Ada.Calendar;

procedure Simple_Sensor_Fusion is
   use Ada.Text_IO;
   use Ada.Calendar;
   
   File : Ada.Text_IO.File_Type;
begin
   Put_Line ("Simple Sensor Fusion Server");
   Put_Line ("============================");
   Put_Line ("This is a simplified version for testing.");
   Put_Line ("The full AWS version requires system dependencies:");
   Put_Line ("  - libgmp-dev");
   Put_Line ("  - libssl-dev");
   Put_Line ("  - GNAT compiler");
   Put_Line ("  - AWS Ada library");
   Put_Line ("");
   Put_Line ("To capture data, use the Python server:");
   Put_Line ("  python3 verify_phones_8080.py");
   Put_Line ("  python3 test_data_capture.py");
   Put_Line ("");
   
   -- Create a sample data file to demonstrate functionality
   begin
      Create (File, Out_File, "sample_sensor_data.csv");
      Put_Line (File, "timestamp_ns,platform,device_id,sensor_type,x,y,z");
      Put_Line (File, "1640995200000000000,iOS,iPhone11,accelerometer,0.1,0.2,9.8");
      Put_Line (File, "1640995200100000000,Android,SamsungS10e,accelerometer,0.15,0.25,9.81");
      Close (File);
      Put_Line ("Created sample data file: sample_sensor_data.csv");
   exception
      when others =>
         Put_Line ("Error creating sample file");
   end;
   
   Put_Line ("");
   Put_Line ("To build the full AWS server, run:");
   Put_Line ("  ./build_aws_server.sh --full");
   Put_Line ("");
end Simple_Sensor_Fusion;
