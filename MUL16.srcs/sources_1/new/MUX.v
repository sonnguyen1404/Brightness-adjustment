`timescale 1ns / 1ps
module MUX #(parameter WIDTH = 19) (  // WIDTH l� ?? r?ng c?a t�ch t?ng ph?n (PP)
    input wire [WIDTH-1:0] pp,      // T�ch t?ng ph?n ban ??u
    input wire sign,                // Bit d?u (ch?n PP ho?c PP_NEG)
    output wire [WIDTH-1:0] out      // ??u ra c?a MUX
);
    wire [WIDTH-1:0] pp_neg;
    assign pp_neg = ~pp;  // ??o pp ngay trong module
    assign out = (sign) ? pp_neg : pp;
endmodule