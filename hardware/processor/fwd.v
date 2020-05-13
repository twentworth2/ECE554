module fwd(
    input [2:0] r_rf1, // First register being read from reg file
    input [2:0] r_rf2, // Second register being read from reg file
    input [2:0] r_ex, // Register being output from EX stage
    input [2:0] r_mem, // Register written to from memory
	input [2:0] r_wb, //Register written to from wb
    
    input regwrite_ex, // If the result of the EX stage is written back; otherwise
                       // no need to forward because it shouldn't even be there
    input regwrite_mem, // Same for the result of the MEM stage
	input regwrite_wb, // And WB
    
    output x2x_1, // Whether to forward from ex to ex for first ALU register
    output x2x_2, // Whether to forward from ex to ex for second ALU register
    output m2x_1, // Whether to forward from mem to ex for first ALU register
    output m2x_2, // Whether to forward from mem to ex for second ALU register
	
	output wb2x_1,// Whether to forward from wb to ex for first ALU register
	output wb2x_2// Whether to forward from wb to ex for second ALU register
);

assign x2x_1 = regwrite_ex && (r_rf1 == r_ex) && (|r_ex);
assign x2x_2 = regwrite_ex && (r_rf2 == r_ex) && (|r_ex);

assign m2x_1 = regwrite_mem && (!x2x_1) && (r_rf1 == r_mem) && (|r_mem);
assign m2x_2 = regwrite_mem && (!x2x_2) && (r_rf2 == r_mem) && (|r_mem);

assign wb2x_1 = regwrite_wb && (!x2x_1) && (!m2x_1) && (r_rf1 == r_wb) && (|r_wb);
assign wb2x_2 = regwrite_wb && (!x2x_2) && (!m2x_2) && (r_rf2 == r_wb) && (|r_wb);  

endmodule