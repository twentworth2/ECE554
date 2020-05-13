module decode(
input clk, 
input rst_n, 
input wren_in,
input [15:0] new_reg,
input [2:0] write_addr_in, 
input [15:0] curr_instr,
output [15:0] alu_in1,
output [15:0] alu_in2,
output [2:0] write_addr_out,
output [2:0] read1_reg, // Register number of first ALU op
output [2:0] read2_reg, // Register number of second ALU op
output [4:0] opcode,
output wren_out,
output wren_mem, 
output ren_mem,
output [7:0] imm,
output is_branch,
output hlt, 
output set_r7, 
output [15:0] r7_value

); 

wire[3:0] read1_addr, read2_addr; 
wire[15:0] source1; 
wire r_type, m_type, j_type, i_type;

assign read1_reg = read1_addr[2:0];
assign read2_reg = read2_addr[2:0];

localparam ST = 5'b10010;
localparam LD = 5'b10000;
localparam HLT = 5'b11111; 
localparam LL = 5'b01000;
localparam LH = 5'b01001;

assign hlt = (opcode == HLT); 

assign set_r7 = (opcode == LL & curr_instr[10:8] == 3'd7)  | (opcode == LH & curr_instr[10:8] == 3'd7); 
assign r7_value = (opcode == LL) ? {8'h00, imm} :
				(opcode == LH) ? {imm, 8'h00} :
				16'h00; 
				


assign is_branch = j_type;

assign wren_mem = (opcode == ST); 
assign ren_mem = (opcode == LD); 

wire wren_in_; 
assign wren_in_ = (write_addr_in == 3'd7) ? 1'b0 : wren_in; 


//read rs
rf RF_1(.clock(clk), .data(new_reg), .rdaddress(read1_addr), .wraddress({1'b0, write_addr_in}), .wren(wren_in_), .q(alu_in1)); 
//read rt
rf RF_2(.clock(clk), .data(new_reg), .rdaddress(read2_addr), .wraddress({1'b0, write_addr_in}), .wren(wren_in_), .q(alu_in2)); 

//instruction decode 
//assign read2_addr = {1'b0, curr_instr[2:0]};
assign write_addr_out = curr_instr[10:8];
assign opcode = curr_instr[15:11]; 
assign imm = curr_instr[7:0]; 

assign r_type = (opcode[4:3] == 2'b11); 
assign m_type = (opcode[4:3] == 2'b10); 
assign i_type = (opcode[4:3] == 2'b01); 
assign j_type = (opcode[4:3] == 2'b00); 
//halt and noop not handled


assign read1_addr = (i_type | (m_type & opcode == 5'b10011) | (m_type & opcode == 5'b10100) | (m_type & opcode == 5'b10010)) ? 
					{1'b0, curr_instr[10:8]} : {1'b0, curr_instr[6:4]};
					
assign read2_addr = (r_type) ? {1'b0, curr_instr[2:0]} : {1'b0, curr_instr[6:4]};

assign wren_out = (set_r7) ? 1'b0 : 
					(opcode == 5'b01010 | opcode == 5'b10100 | opcode == 5'b10010 | opcode == 5'b00000 | j_type) ? 1'b0 : 1'b1;
					

					
endmodule 
										

					
					