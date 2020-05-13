`timescale 1 ps / 1 ps
module decode_tb(); 

reg clk, rst_n, wren_in; 
reg [15:0] new_reg, D_instr; 
reg [2:0] write_addr_in; 
wire[2:0] write_addr_out; 
wire[15:0] alu_in1, alu_in2; 
wire[4:0] opcode; 
wire wren_out; 

decode DECODE(.clk(clk), .rst_n(rst_n), .wren_in(wren_in), .new_reg(new_reg), .write_addr_in(write_addr_in), .write_addr_out(write_addr_out),
				.curr_instr(D_instr), .alu_in1(alu_in1), .alu_in2(alu_in2), .opcode(opcode), .wren_out(wren_out));
				
initial begin 
clk = 0; 
rst_n = 1;
D_instr = 16'h0000; 
wren_in = 1; 
new_reg = 1; 
write_addr_in = 16'h2;  
repeat(5) @(posedge clk); 
rst_n = 0; 
repeat(5) @(posedge clk); 
rst_n = 1; 
D_instr = 16'h5202; 
@(posedge clk); //D_instr = 16'h5101; 
@(posedge clk); //D_instr = 16'h3723;
@(posedge clk); 
$stop; 

end

always
#1 clk = ~clk;

endmodule
