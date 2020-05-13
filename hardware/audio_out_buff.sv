
`timescale 1 ps / 1 ps

module audio_out_buff(
	input clk, 
	input rst_n, 
	input BCLK, 
	input act, //from i2c
	input write, //from cpu
	input[15:0] aud_data, 
	output[15:0] buffer_data, 
	output reg new_data
	);

wire empty; 
reg[4:0] bclk_cntr; 
reg[31:0] cntr; 
typedef enum reg {INIT, SEND} state_t; 
state_t state, nxt_state; 

reg new_data_;

assign new_data = ~empty; 

always@(posedge clk) begin 
	if (~rst_n)  
		state <= INIT; 
	else	
		state <= nxt_state; 
end

ip_buffer ip_buffer_inst (.clock(clk), .data(aud_data), .rdreq(new_data_), .sclr(~rst_n), .wrreq(write), .empty(empty), .full(), .q(buffer_data), .usedw()); 

always@(posedge BCLK, negedge rst_n) begin 
	if (~rst_n) 
		bclk_cntr <= 5'h00; 
	else if (bclk_cntr == 5'h10)
		bclk_cntr <= 5'h00; 
	else 
		bclk_cntr <= bclk_cntr + 1; 
end


always@(posedge clk, negedge BCLK, negedge rst_n) begin 
	if (~rst_n) 
		cntr <= 32'h000000; 
	else if (~BCLK) 
		cntr <= 32'h000000; 
	else 
		cntr <= cntr + 1; 
end 


always_comb begin 
new_data_ = 0; 
case(state) 
	INIT: 	if (act)  
				nxt_state = SEND; 
			else
				nxt_state = INIT; 
	SEND: 	if (~empty & (bclk_cntr == 5'h10 & cntr == 32'h00000000 & BCLK)) begin 
				new_data_ = 1'b1; 
				nxt_state = SEND; 
			end
			else begin 
				new_data_ = 1'b0; 
				nxt_state = SEND; 
			end
			
endcase 
end

endmodule 