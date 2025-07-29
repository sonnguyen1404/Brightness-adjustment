`timescale 1ns / 1ps
module Booth_e (
    input [3:0] b_in,   // Nh?n ?úng 4-bit t? b
    output reg [3:0] sel  // Ch?n h? s? nhân (0, a, 2a, 3a, 4a) + bit d?u
);
 always @(*) begin
        case (b_in)
            4'b0000, 4'b1111: sel = 4'b0000; // 0
            4'b0001, 4'b0010: sel = 4'b0001; // +a
            4'b0011, 4'b0100: sel = 4'b0010; // +2a
            4'b0101, 4'b0110: sel = 4'b0011; // +3a
            4'b0111:          sel = 4'b0100; // +4a
            4'b1000:          sel = 4'b1100; // -4a (MSB=1 ?? báo hi?u âm)
			4'b1001, 4'b1010: sel = 4'b1011; // -3a
            4'b1011, 4'b1100: sel = 4'b1010; // -2a
            4'b1101, 4'b1110: sel = 4'b1001; // -a
            default: sel = 4'b0000; // 0
        endcase
    end
endmodule
