-- Simple HTTP server to show raw sensor data
with Ada.Text_IO;
with Ada.Streams;
with GNAT.Sockets;
with Ada.Strings.Unbounded;

procedure Simple_HTTP_Server is
   use Ada.Text_IO;
   use Ada.Streams;
   use GNAT.Sockets;
   use Ada.Strings.Unbounded;
   
   Server_Socket : Socket_Type;
   Client_Socket : Socket_Type;
   Address       : Sock_Addr_Type;
   Client_Addr   : Sock_Addr_Type;
   Message       : Stream_Element_Array (1 .. 4096);
   Last          : Stream_Element_Offset;
   
   procedure Handle_Request (Socket : in out Socket_Type) is
      Request_Line : Unbounded_String;
      Data_Start   : Natural := 0;
      Content_Length : Natural := 0;
      Headers_Done : Boolean := False;
   begin
      -- Read request line by line
      loop
         declare
            Line : String (1 .. 1024);
            Last : Natural;
         begin
            Read_Line (Socket, Line, Last);
            exit when Last = 0;  -- Empty line ends headers
            
            Put_Line ("Header: " & Line (1 .. Last));
            
            -- Look for Content-Length
            if Line (1 .. Last)'Length >= 16 and then 
               Line (1 .. 16) = "Content-Length:" then
               Content_Length := Natural'Value (Line (17 .. Last));
            end if;
            
            -- Empty line marks end of headers
            if Last = 2 and then Line (1 .. 2) = Cr_Lf then
               Headers_Done := True;
               exit;
            end if;
         end;
      end loop;
      
      -- Read POST data if present
      if Content_Length > 0 then
         declare
            Data : Stream_Element_Array (1 .. Stream_Element_Offset (Content_Length));
            Data_Last : Stream_Element_Offset;
         begin
            Receive (Socket, Data, Data_Last);
            
            Put_Line ("Received " & Natural'Image (Content_Length) & " bytes");
            
            -- Convert to string and show first 100 chars
            declare
               Data_Str : String (1 .. Content_Length);
               for Data_Str'Address use Data'Address;
            begin
               Put_Line ("Raw data start:");
               declare
                  Show_Length : constant Natural := Natural'Min (Content_Length, 100);
               begin
                  Put_Line (Data_Str (1 .. Show_Length));
               end;
            end;
         end;
      end if;
      
      -- Send response
      declare
         Response : constant String := 
            "HTTP/1.1 200 OK" & Cr_Lf &
            "Content-Type: text/plain" & Cr_Lf &
            "Content-Length: 26" & Cr_Lf &
            Cr_Lf &
            "Data received successfully";
      begin
         Send (Socket, Response);
      end;
   end Handle_Request;
   
begin
   Put_Line ("Simple HTTP Server - Port 8080");
   Put_Line ("Target: http://10.0.0.146:8080/data");
   
   -- Create server socket
   Create_Socket (Server_Socket);
   Address := (Family => Family_Inet, 
               Addr   => Inet_Addr ("10.0.0.146"),
               Port   => 8080);
   Bind_Socket (Server_Socket, Address);
   Listen_Socket (Server_Socket);
   
   Put_Line ("Server ready, waiting for connections...");
   
   -- Accept connections
   loop
      Accept_Socket (Server_Socket, Client_Socket, Client_Addr);
      Put_Line ("Connection from: " & Image (Client_Addr.Addr));
      
      Handle_Request (Client_Socket);
      Close_Socket (Client_Socket);
   end loop;
   
exception
   when others =>
      Close_Socket (Server_Socket);
      Put_Line ("Server stopped");
end Simple_HTTP_Server;
