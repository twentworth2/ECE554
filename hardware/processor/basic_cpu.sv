`timescale 1 ps / 1 ps

module basic_cpu_tb();

reg rst_n, clk; 
wire [15:0] pc;
wire hlt; 

cpu CPU(.clk(clk), .rst_n(rst_n), .pc(pc), .hlt(hlt)); 

initial begin 
clk = 0; 
rst_n = 1; 
repeat(5) @(posedge clk); 
rst_n = 0; 
repeat(10) @(posedge clk); 
rst_n = 1; 
for (integer i = 0; i < 20; i = i + 1) begin 
@(posedge clk);
$display("////////////////////////////"); 
$display("opcode %B", CPU.opcode);
$display("new_reg data %D", CPU.new_reg);
$display("write_addr_in %D", CPU.write_addr_in);
$display("wren_in %B", CPU.wren_in); 
if (hlt) break; 

end

$stop; 
end
always 
#5 clk = ~clk; 

endmodule


