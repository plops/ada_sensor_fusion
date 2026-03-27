-- SPARK Pure Math Library for Sensor Fusion
-- Quaternion operations with formal verification contracts

pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;

package Math_Library is

   -- Global epsilon for floating point comparisons
   Epsilon : constant Float := 1.0E-6;
   
   -- Quaternion type for orientation representation
   type Quaternion is record
      W : Float;  -- Scalar component
      X : Float;  -- Vector X component
      Y : Float;  -- Vector Y component  
      Z : Float;  -- Vector Z component
   end record;
   
   -- 3D Vector type (redefined from Sensors for independence)
   type Vector_3D is record
      X : Float;
      Y : Float;
      Z : Float;
   end record;
   
   -- 3x3 Matrix type for rotation operations
   type Matrix_3x3 is array (1 .. 3, 1 .. 3) of Float;
   
   -- Identity quaternion (no rotation)
   Identity_Quaternion : constant Quaternion := (1.0, 0.0, 0.0, 0.0);
   
   -- Basic quaternion operations with SPARK contracts
   
   -- Compute quaternion magnitude squared (avoids sqrt for proofs)
   function Magnitude_Squared (Q : Quaternion) return Float
     with Post => Magnitude_Squared'Result >= 0.0;
   
   -- Compute quaternion magnitude
   function Magnitude (Q : Quaternion) return Float
     with Post => Magnitude'Result >= 0.0;
   
   -- Normalize quaternion to unit length
   -- Pre: Magnitude must be greater than epsilon to avoid division by zero
   -- Post: Result has unit magnitude within tolerance
   function Normalize (Q : Quaternion) return Quaternion
     with 
       Pre => Magnitude_Squared (Q) > Epsilon,
       Post => abs (Magnitude_Squared (Normalize'Result) - 1.0) < Epsilon * 10.0;
   
   -- Quaternion conjugate (inverse for unit quaternions)
   function Conjugate (Q : Quaternion) return Quaternion;
   
   -- Quaternion multiplication (Hamilton product)
   function Multiply (Q1, Q2 : Quaternion) return Quaternion;
   
   -- Convert quaternion to 3x3 rotation matrix
   function To_Rotation_Matrix (Q : Quaternion) return Matrix_3x3;
   
   -- Vector rotation using quaternion
   function Rotate_Vector (V : Vector_3D; Q : Quaternion) return Vector_3D
     with Pre => Magnitude_Squared (Q) > Epsilon;
   
   -- Madgwick filter update function
   -- Integrates gyroscope data and corrects with accelerometer/magnetometer
   function Update_Madgwick
     (Current_Q : Quaternion;
      Accel     : Vector_3D;
      Gyro      : Vector_3D;
      DT        : Float) return Quaternion
     with 
       Pre => (DT > 0.0 and DT < 0.2) and then
            Magnitude_Squared (Current_Q) > Epsilon,
       Post => Magnitude_Squared (Update_Madgwick'Result) > Epsilon;
   
   -- Helper functions for Madgwick algorithm
   
   -- Compute gradient descent step for accelerometer correction
   function Compute_Accel_Gradient
     (Q : Quaternion;
      Accel : Vector_3D) return Quaternion;
   
   -- Compute gradient descent step for magnetometer correction  
   function Compute_Mag_Gradient
     (Q : Quaternion;
      Mag : Vector_3D) return Quaternion;
   
   -- Time conversion utilities
   
   -- Convert nanoseconds to seconds
   function Nanoseconds_To_Seconds (Ns : Long_Integer) return Float
     with Post => Nanoseconds_To_Seconds'Result >= 0.0;
   
   -- Compute delta time in seconds from nanosecond timestamps
   function Compute_Delta_Time
     (Current_Ns, Previous_Ns : Long_Integer) return Float
     with 
       Pre => Current_Ns >= Previous_Ns,
       Post => Compute_Delta_Time'Result >= 0.0;
   
-- Safe square root with domain checking
   function Safe_Sqrt (X : Float) return Float
     with Pre => X >= 0.0,
          Post => Safe_Sqrt'Result >= 0.0;
   
   -- Safe division with zero checking
   function Safe_Divide (Num, Denom : Float) return Float
     with Pre => abs (Denom) > Epsilon;

end Math_Library;
