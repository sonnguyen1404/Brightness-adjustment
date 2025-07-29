`timescale 1ns / 1ps
module PP_gen #(parameter PP_WIDTH = 19 )// Ch? thay ??i ??u ra, còn input luôn 16-bit
(
    input  [15:0] a,             // ??u vào c? ??nh 16 bit
    input  [3:0]  sel,           // ??u vào h? s? Booth
    output reg [PP_WIDTH-1:0] pp, // ??u ra thay ??i: 17 ho?c 19 bit
    output       sign_bit
);
always @(*) begin
        case (sel[2:0])
            3'b000: pp = {PP_WIDTH{1'b0}};
            3'b001: pp = {{(PP_WIDTH-16){a[15]}}, a};              // a (sign-extended)
            3'b010: pp = {{(PP_WIDTH-17){a[15]}}, a, 1'b0};        // 2a (sign-extended)
            3'b011: pp = {{(PP_WIDTH-17){a[15]}}, a, 1'b0} + {{(PP_WIDTH-16){a[15]}}, a}; // 3a
            3'b100: pp = {{(PP_WIDTH-18){a[15]}}, a, 2'b00};       // 4a (sign-extended)
            default: pp = {PP_WIDTH{1'b0}};
        endcase
    end
assign sign_bit = sel[3];  // 1 n?u là s? âm, 0 n?u là s? d??ng
endmodule
