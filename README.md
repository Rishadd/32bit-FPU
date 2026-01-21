\# IEEE 754 Floating Point Unit (FPU)



This project implements a 32-bit (single precision) IEEE 754-compliant Floating Point Unit that supports both addition/subtraction and multiplication operations. The FPU consists of modular Verilog code designed for simulation and a synthesizable design for FPGA implementation.



\## Features



\- IEEE 754 single-precision floating-point compliance

\- Supports addition, subtraction, and multiplication

\- Handles special cases:

&nbsp; - NaN (Not a Number)

&nbsp; - Infinity

&nbsp; - Zero

&nbsp; - Denormalized numbers

\- Modular design for scalability and testing

\- Easily synthesizable with tools like Vivado and simulatable with ModelSim



\## Operation Mode



The top-level module `alu.v` takes a 1-bit `opcode`:

\- `opcode = 0` → perform addition/subtraction

\- `opcode = 1` → perform multiplication



\## Testbenches



Each major module includes a dedicated testbench:

\- `tb\_adder\_32bit.v`: Includes test cases for addition, subtraction, and edge cases (NaN, inf, etc.)

\- `tb\_multiplier\_32bit.v`: Covers regular and special multiplication cases

\- `tb\_alu.v`: Verifies the whole ALU with control signal



