`timescale 1ns / 1ps
module MUL_16bit(
    input  [15:0] a,  // Multiplicand
    input  [15:0] b,  // Multiplier
    output [31:0] P32 // Final Product
);
	 // Internal signals
	wire [3:0] sel [0:5];
    wire [18:0] pp [0:4];       // pp[0] ??n pp[4] là 19-bit
    wire [16:0] pp_5;           // pp[5] riêng, 17-bit
    wire sign_bit [0:5];
    wire [18:0] pp_mux [0:4];   // output from MUX
    wire [16:0] pp_mux_5;       // muxed pp_5
//    wire [31:0] ext_pp [0:5];
    wire [31:0] ext_pp_0;
    wire [28:0] ext_pp_1;
    wire [25:0] ext_pp_2;
    wire [22:0] ext_pp_3;
    wire [19:0] ext_pp_4;
    wire [16:0] sum_17b [0:4];
    wire [2:0]  sum_3b [0:9];
    wire carry_out [0:9];
    
    
	 
	 // Booth Encoding for each 4-bit segment of b
Booth_e booth_0 (
    .b_in({b[2], b[1], b[0], 1'b0}),
    .sel(sel[0])
);

Booth_e booth_1 (
    .b_in({b[5], b[4], b[3], b[2]}),
    .sel(sel[1])
);

Booth_e booth_2 (
    .b_in({b[8], b[7], b[6], b[5]}),
    .sel(sel[2])
);

Booth_e booth_3 (
    .b_in({b[11], b[10], b[9], b[8]}),
    .sel(sel[3])
);

Booth_e booth_4 (
    .b_in({b[14], b[13], b[12], b[11]}),
    .sel(sel[4])
);

Booth_e booth_5 (
    .b_in({2'b00, b[15], b[14]}),
    .sel(sel[5])
);

	
	// Partial Product Generation
PP_gen #(.PP_WIDTH(19)) pp_gen_0 (
    .a(a),
    .sel(sel[0]),
    .pp(pp[0]),
    .sign_bit(sign_bit[0])
);

PP_gen #(.PP_WIDTH(19)) pp_gen_1 (
    .a(a),
    .sel(sel[1]),
    .pp(pp[1]),
    .sign_bit(sign_bit[1])
);

PP_gen #(.PP_WIDTH(19)) pp_gen_2 (
    .a(a),
    .sel(sel[2]),
    .pp(pp[2]),
    .sign_bit(sign_bit[2])
);

PP_gen #(.PP_WIDTH(19)) pp_gen_3 (
    .a(a),
    .sel(sel[3]),
    .pp(pp[3]),
    .sign_bit(sign_bit[3])
);

PP_gen #(.PP_WIDTH(19)) pp_gen_4 (
    .a(a),
    .sel(sel[4]),
    .pp(pp[4]),
    .sign_bit(sign_bit[4])
);

// Tr??ng h?p ??c bi?t cu?i cùng: PP_WIDTH = 17
PP_gen #(.PP_WIDTH(17)) pp_gen_5 (
    .a(a),
    .sel(sel[5]),
    .pp(pp_5),
    .sign_bit(sign_bit[5])
);

	
	// Multiplexer to select positive/negative partial product
	MUX #(.WIDTH(19)) mux_0 (.pp(pp[0]), .sign(sign_bit[0]), .out(pp_mux[0]));
    MUX #(.WIDTH(19)) mux_1 (.pp(pp[1]), .sign(sign_bit[1]), .out(pp_mux[1]));
    MUX #(.WIDTH(19)) mux_2 (.pp(pp[2]), .sign(sign_bit[2]), .out(pp_mux[2]));
    MUX #(.WIDTH(19)) mux_3 (.pp(pp[3]), .sign(sign_bit[3]), .out(pp_mux[3]));
    MUX #(.WIDTH(19)) mux_4 (.pp(pp[4]), .sign(sign_bit[4]), .out(pp_mux[4]));
    
    //Tr??ng h?p ??c bi?t
    MUX #(.WIDTH(17)) mux_5 (.pp(pp_5),  .sign(sign_bit[5]), .out(pp_mux_5));

	
	   // Half Adder for first PP (Before EXT)
    wire [18:0] pp_sum;
    half_adder ha_18b (
        .pp(pp_mux[0][17:0]), 
        .sign_bit(sign_bit[0]), 
        .sum(pp_sum)
    );
    // Sign extension for the first PP (After Half Adder)
    assign ext_pp_0 = {{13{pp_sum[18]}}, pp_sum}; 
	
	    // Sign extension using EXT module
EXT #(.IN_WIDTH(19), .OUT_WIDTH(29)) ext_1 (
    .in_data(pp_mux[1]),
    .out_data(ext_pp_1)
);

EXT #(.IN_WIDTH(19), .OUT_WIDTH(26)) ext_2 (
    .in_data(pp_mux[2]),
    .out_data(ext_pp_2)
);

EXT #(.IN_WIDTH(19), .OUT_WIDTH(23)) ext_3 (
    .in_data(pp_mux[3]),
    .out_data(ext_pp_3)
);

EXT #(.IN_WIDTH(19), .OUT_WIDTH(20)) ext_4 (
    .in_data(pp_mux[4]),
    .out_data(ext_pp_4)
);

	 
	  //Transverse carry array
	 
	 RCA_3bit U1 (
    .A(ext_pp_1[2:0]),
    .B(ext_pp_0[5:3]),
    .Cin(sign_bit[1]),
    .Sum(sum_3b[0]),
    .Cout(carry_out[0])
	 );

	 RCA_3bit U2 (
    .A(ext_pp_2[2:0]),
    .B(ext_pp_1[5:3]),
    .Cin(carry_out[0]),
    .Sum(sum_3b[1]),
    .Cout(carry_out[1])
	 );
		
	 RCA_3bit U3 (
    .A(ext_pp_0[8:6]),
    .B(sum_3b[1]),
    .Cin(sign_bit[2]),
    .Sum(sum_3b[2]),
    .Cout(carry_out[2])
	 );

	RCA_3bit U4 (
    .A(ext_pp_3[2:0]),
    .B(ext_pp_2[5:3]),
    .Cin(carry_out[1]),
    .Sum(sum_3b[3]),
    .Cout(carry_out[3])
	 );

	 RCA_3bit U5 (
    .A(sum_3b[3]),
    .B(ext_pp_1[8:6]),
    .Cin(carry_out[2]),
    .Sum(sum_3b[4]),
    .Cout(carry_out[4])
	 );
	 
	 RCA_3bit U6 (
    .A(sum_3b[4]),
    .B(ext_pp_0[11:9]),
    .Cin(sign_bit[3]),
    .Sum(sum_3b[5]),
    .Cout(carry_out[5])
	 );
	 
	 RCA_3bit U7 (
    .A(ext_pp_4[2:0]),
    .B(ext_pp_3[5:3]),
    .Cin(carry_out[3]),
    .Sum(sum_3b[6]),
    .Cout(carry_out[6])
	 );
	 
	 RCA_3bit U8 (
    .A(sum_3b[6]),
    .B(ext_pp_2[8:6]),
    .Cin(carry_out[4]),
    .Sum(sum_3b[7]),
    .Cout(carry_out[7])
	 );
	 
	 RCA_3bit U9 (
    .A(sum_3b[7]),
    .B(ext_pp_1[11:9]),
    .Cin(carry_out[5]),
    .Sum(sum_3b[8]),
    .Cout(carry_out[8])
	 );
	 
	 RCA_3bit U10 (
    .A(sum_3b[8]),
    .B(ext_pp_0[14:12]),
    .Cin(sign_bit[4]),
    .Sum(sum_3b[9]),
    .Cout(carry_out[9])
	 );
	 
	 RCA_17bit U11 (
    .A(pp_mux_5[16:0]),
    .B(ext_pp_4[19:3]),
    .Cin(carry_out[6]),
    .Sum(sum_17b[0]),
    .Cout()
	 );
	 
	 RCA_17bit U12 (
    .A(sum_17b[0]),
    .B(ext_pp_3[22:6]),
    .Cin(carry_out[7]),
    .Sum(sum_17b[1]),
    .Cout()
	 );
	 
	 RCA_17bit U13 (
    .A(sum_17b[1]),
    .B(ext_pp_2[25:9]),
    .Cin(carry_out[8]),
    .Sum(sum_17b[2]),
    .Cout()
	 );
	 
	 RCA_17bit U14 (
    .A(sum_17b[2]),
    .B(ext_pp_1[28:12]),
    .Cin(carry_out[9]),
    .Sum(sum_17b[3]),
    .Cout()
	 );
	 
	 RCA_17bit U15 (
    .A(sum_17b[3]),
    .B(ext_pp_0[31:15]),
    .Cin(sign_bit[5]),
    .Sum(sum_17b[4]),
    .Cout()
	 );
	 
	 assign P32[2:0] = ext_pp_0[2:0];
	 assign P32[5:3] = sum_3b[0];
	 assign P32[8:6] = sum_3b[2];
	 assign P32[11:9] = sum_3b[5];
	 assign P32[14:12] = sum_3b[9];
	 assign P32[31:15] = sum_17b[4];
endmodule
