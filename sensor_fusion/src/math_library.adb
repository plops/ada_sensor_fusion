-- SPARK Pure Math Library Implementation for Sensor Fusion
-- Quaternion operations with formal verification

pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;

package body Math_Library is

   -- Compute quaternion magnitude squared (avoids sqrt for proofs)
   function Magnitude_Squared (Q : Quaternion) return Float is
   begin
      return Q.W * Q.W + Q.X * Q.X + Q.Y * Q.Y + Q.Z * Q.Z;
   end Magnitude_Squared;

   -- Compute quaternion magnitude
   function Magnitude (Q : Quaternion) return Float is
   begin
      return Safe_Sqrt (Magnitude_Squared (Q));
   end Magnitude;

   -- Normalize quaternion to unit length
   function Normalize (Q : Quaternion) return Quaternion is
      Mag_Sq : constant Float := Magnitude_Squared (Q);
      Inv_Mag : constant Float := Safe_Divide (1.0, Safe_Sqrt (Mag_Sq));
   begin
      return (Q.W * Inv_Mag, Q.X * Inv_Mag, Q.Y * Inv_Mag, Q.Z * Inv_Mag);
   end Normalize;

   -- Quaternion conjugate (inverse for unit quaternions)
   function Conjugate (Q : Quaternion) return Quaternion is
   begin
      return (Q.W, -Q.X, -Q.Y, -Q.Z);
   end Conjugate;

   -- Quaternion multiplication (Hamilton product)
   function Multiply (Q1, Q2 : Quaternion) return Quaternion is
   begin
      return (
        Q1.W * Q2.W - Q1.X * Q2.X - Q1.Y * Q2.Y - Q1.Z * Q2.Z,  -- W
        Q1.W * Q2.X + Q1.X * Q2.W + Q1.Y * Q2.Z - Q1.Z * Q2.Y,  -- X
        Q1.W * Q2.Y - Q1.X * Q2.Z + Q1.Y * Q2.W + Q1.Z * Q2.X,  -- Y
        Q1.W * Q2.Z + Q1.X * Q2.Y - Q1.Y * Q2.X + Q1.Z * Q2.W   -- Z
      );
   end Multiply;

   -- Convert quaternion to 3x3 rotation matrix
   function To_Rotation_Matrix (Q : Quaternion) return Matrix_3x3 is
   begin
      return (
        1 => (1 => 1.0 - 2.0 * (Q.Y * Q.Y + Q.Z * Q.Z),
              2 => 2.0 * (Q.X * Q.Y - Q.Z * Q.W),
              3 => 2.0 * (Q.X * Q.Z + Q.Y * Q.W)),
        2 => (1 => 2.0 * (Q.X * Q.Y + Q.Z * Q.W),
              2 => 1.0 - 2.0 * (Q.X * Q.X + Q.Z * Q.Z),
              3 => 2.0 * (Q.Y * Q.Z - Q.X * Q.W)),
        3 => (1 => 2.0 * (Q.X * Q.Z - Q.Y * Q.W),
              2 => 2.0 * (Q.Y * Q.Z + Q.X * Q.W),
              3 => 1.0 - 2.0 * (Q.X * Q.X + Q.Y * Q.Y))
      );
   end To_Rotation_Matrix;

   -- Vector rotation using quaternion: v' = q * v * q_conj
   function Rotate_Vector (V : Vector_3D; Q : Quaternion) return Vector_3D is
      -- Convert vector to quaternion (0, v)
      V_Q : constant Quaternion := (0.0, V.X, V.Y, V.Z);
      Q_Conj : constant Quaternion := Conjugate (Q);
      Result_Q : constant Quaternion := Multiply (Multiply (Q, V_Q), Q_Conj);
   begin
      return (Result_Q.X, Result_Q.Y, Result_Q.Z);
   end Rotate_Vector;

   -- Madgwick filter update function
   function Update_Madgwick
     (Current_Q : Quaternion;
      Accel     : Vector_3D;
      Gyro      : Vector_3D;
      DT        : Float) return Quaternion
   is
      -- Normalize accelerometer (assumes gravity magnitude = 1g)
      Accel_Norm : constant Float := Safe_Sqrt (Accel.X * Accel.X + Accel.Y * Accel.Y + Accel.Z * Accel.Z);
      Accel_Unit : constant Vector_3D := 
        (Safe_Divide (Accel.X, Accel_Norm),
         Safe_Divide (Accel.Y, Accel_Norm),
         Safe_Divide (Accel.Z, Accel_Norm));
      
      -- Compute gradient descent correction
      Gradient : constant Quaternion := Compute_Accel_Gradient (Current_Q, Accel_Unit);
      
      -- Apply gyroscope integration
      Gyro_Q : constant Quaternion := (0.0, Gyro.X * 0.5, Gyro.Y * 0.5, Gyro.Z * 0.5);
      Q_Dot : constant Quaternion := Multiply (Gyro_Q, Current_Q);
      
      -- Combine gyroscope prediction with accelerometer correction
      Q_Pred : constant Quaternion := 
        (Current_Q.W + Q_Dot.W * DT - Gradient.W * DT,
         Current_Q.X + Q_Dot.X * DT - Gradient.X * DT,
         Current_Q.Y + Q_Dot.Y * DT - Gradient.Y * DT,
         Current_Q.Z + Q_Dot.Z * DT - Gradient.Z * DT);
      
   begin
      return Normalize (Q_Pred);
   end Update_Madgwick;

   -- Compute gradient descent step for accelerometer correction
   -- Objective: align measured gravity with predicted gravity
   function Compute_Accel_Gradient
     (Q : Quaternion;
      Accel : Vector_3D) return Quaternion
   is
      -- Predicted gravity direction from quaternion
      F : constant Vector_3D := Rotate_Vector ((0.0, 0.0, 1.0), Q);
      
      -- Jacobian matrix elements
      J_11, J_12, J_13 : Float;
      J_21, J_22, J_23 : Float;
      J_31, J_32, J_33 : Float;
      
      -- Gradient components
      Grad_W, Grad_X, Grad_Y, Grad_Z : Float;
      
   begin
      -- Compute Jacobian
      J_11 := 2.0 * Q.Y;
      J_12 := -2.0 * Q.Z;
      J_13 := 0.0;
      
      J_21 := 2.0 * Q.X;
      J_22 := 2.0 * Q.Z;
      J_23 := -4.0 * Q.W;
      
      J_31 := 0.0;
      J_32 := -2.0 * Q.W;
      J_33 := 2.0 * Q.X;
      
      -- Compute gradient: J^T * (f - measured)
      Grad_W := J_21 * (F.X - Accel.X) + J_31 * (F.Y - Accel.Y);
      Grad_X := J_11 * (F.X - Accel.X) + J_21 * (F.Y - Accel.Y) + J_31 * (F.Z - Accel.Z);
      Grad_Y := J_12 * (F.X - Accel.X) + J_22 * (F.Y - Accel.Y) + J_32 * (F.Z - Accel.Z);
      Grad_Z := J_13 * (F.X - Accel.X) + J_23 * (F.Y - Accel.Y) + J_33 * (F.Z - Accel.Z);
      
      return (Grad_W, Grad_X, Grad_Y, Grad_Z);
   end Compute_Accel_Gradient;

   -- Compute gradient descent step for magnetometer correction
   function Compute_Mag_Gradient
     (Q : Quaternion;
      Mag : Vector_3D) return Quaternion
   is
      -- Simplified magnetometer correction (would be more complex in full implementation)
      -- This is a placeholder for proper magnetometer fusion
   begin
      return (0.0, 0.0, 0.0, 0.0);  -- No correction for now
   end Compute_Mag_Gradient;

   -- Convert nanoseconds to seconds
   function Nanoseconds_To_Seconds (Ns : Long_Integer) return Float is
   begin
      return Float (Ns) * 1.0E-9;
   end Nanoseconds_To_Seconds;

   -- Compute delta time in seconds from nanosecond timestamps
   function Compute_Delta_Time
     (Current_Ns, Previous_Ns : Long_Integer) return Float
   is
      Delta_Ns : constant Long_Integer := Current_Ns - Previous_Ns;
   begin
      return Nanoseconds_To_Seconds (Delta_Ns);
   end Compute_Delta_Time;

   -- Safe square root with domain checking
   function Safe_Sqrt (X : Float) return Float is
   begin
      if X < 0.0 then
         return 0.0;  -- Should never happen with proper preconditions
      else
         return Ada.Numerics.Elementary_Functions.Sqrt (X);
      end if;
   end Safe_Sqrt;

   -- Safe division with zero checking
   function Safe_Divide (Num, Denom : Float) return Float is
   begin
      if abs (Denom) < Epsilon then
         return 0.0;  -- Should never happen with proper preconditions
      else
         return Num / Denom;
      end if;
   end Safe_Divide;

end Math_Library;
