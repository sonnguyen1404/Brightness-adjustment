`timescale 1ns / 1ps
module EXT #(
    parameter IN_WIDTH = 19,
    parameter OUT_WIDTH = 32
)(
    input wire [IN_WIDTH-1:0] in_data,
    output wire [OUT_WIDTH-1:0] out_data
);
    assign out_data = {{(OUT_WIDTH - IN_WIDTH){in_data[IN_WIDTH-1]}}, in_data};
endmodule