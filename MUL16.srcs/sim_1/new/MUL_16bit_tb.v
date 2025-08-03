`timescale 1ns / 1ps
module MUL_16bit_tb;

	// Inputs
	reg [15:0] a;
	reg [15:0] b;

	// Outputs
	wire [31:0] P32;

	// Instantiate the Unit Under Test (UUT)
	MUL_16bit uut (
		.a(a), 
		.b(b), 
		.P32(P32)
	);

	initial begin
		// Initialize Inputs
		a = 0;
		b = 0;

		// Wait 100 ns for global reset to finish
		#100;
		a = 1234;
		b = 1111;
		#100;
		
		a = 1404;
		b = 2002;
		#100;
		
		a = 3;
		b = 5;
		#100;
		
		a = 30;
		b = 50;
		#100;
		
        
		// Add stimulus here

	end
      
endmodule

