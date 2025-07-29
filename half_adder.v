`timescale 1ns / 1ps
module half_adder(
	input wire [17:0] pp,   // Tích t?ng ph?n (Partial Product) 18-bit
   	input wire sign_bit,     // Bit d?u (Sign bit)
   	output wire [18:0] sum   // K?t qu? c?ng (19-bit)
);
wire [17:0] sum_18b; // K?t qu? c?ng 18-bit tr??c khi m? r?ng

assign sum_18b = pp + sign_bit;    // C?ng tr??c
assign sum = {sum_18b[17], sum_18b}; // M? r?ng theo MSB c?a t?ng

endmodule