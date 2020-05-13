module execute(
	input clk, 
	input rst_n, 
	input [7:0] imm, 
	input [15:0] alu_in1, 
	input [15:0] alu_in2, 
	input [4:0] opcode,
	output [15:0] alu_out, 
	output[2:0] flags, 
	output set_flags
	//output [15:0] branch_out
); 
wire[15:0] in2; 
wire r_type, m_type, j_type, i_type; 

assign r_type = (opcode[4:3] == 2'b11); 
assign m_type = (opcode[4:3] == 2'b10); 
assign i_type = (opcode[4:3] == 2'b01); 
assign j_type = (opcode[4:3] == 2'b00);

assign in2 = (i_type) ? {{8{imm[7]}}, imm[7:0]} : 
			(m_type & (opcode[4:1] == 4'b0100)) ? 16'h0000 : 
			alu_in2; 
			

ALU alu(.in1(alu_in1), .in2(in2), .opcode(opcode), .out(alu_out), .flags(flags), .set_flags(set_flags)); 
 

endmodule 