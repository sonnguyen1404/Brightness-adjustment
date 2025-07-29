`timescale 1ns / 1ps
module RCA_3bit (
    input [2:0] A,  // S? h?ng th? nh?t (3-bit)
    input [2:0] B,  // S? h?ng th? hai (3-bit)
	 input 		  Cin,
    output [2:0] Sum, // T?ng (3-bit)
    output Cout     // Carry ra
);
	wire [2:0] carry; // ???ng truy?n carry n?i b?

    // Full adder cho bit ??u tiên
    full_adder FA0 (
        .a(A[0]), .b(B[0]), .cin(Cin),
        .sum(Sum[0]), .cout(carry[0])
    );
	 // T?o chu?i Ripple Carry Adder cho các bit còn l?i
    genvar i;
    generate
        for (i = 1; i < 3; i = i + 1) begin: RCA_LOOP
            full_adder FA (
                .a(A[i]), .b(B[i]), .cin(carry[i-1]),
                .sum(Sum[i]), .cout(carry[i])
            );
        end
    endgenerate
	 assign Cout = carry[2]; // Carry out cu?i cùng
	 
endmodule
