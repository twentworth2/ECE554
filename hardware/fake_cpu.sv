module fake_cpu(
		input rst_n, 
		input clk, 
		input[15:0] aud_data_out,
		output write
		); 

reg[15:0] cntr;

assign aud_data_out = cntr; 
assign write = (~rst_n) ? 1'b0 : 1'b1; 

always@(posedge clk) begin 
	if (~rst_n) 
		cntr <= 16'h000;  
	else if (cntr == 11'd2047)
		cntr <= 16'h000; 
	else 
		cntr <= cntr + 1; 
end 




endmodule 

