module branch_calc(
	input [15:0] Dinstr, pc, r7, 
	input[2:0] flags, 
	//input is_branch; 
	output [15:0] branch_addr, 
	output should_branch
	); 
	
	
//if Disntr is branch, check flags, decide between Finstr and branch calc 
localparam BRE = 5'b00001;
localparam BRG = 5'b00010;

wire p, z, n; 

assign p = flags[2]; 
assign z = flags[1]; 
assign n = flags[0]; 

assign should_branch = (Dinstr[15:11] == BRE & z) | (Dinstr[15:11] == BRG & p); 

assign branch_addr = (should_branch) ? r7 : pc + 1; 

	
endmodule 