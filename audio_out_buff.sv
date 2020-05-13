`include "ip_buffer512.v"
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
reg[3:0] cntr; 
typedef enum reg {INIT, SEND} state_t; 
state_t state, nxt_state; 

always@(posedge clk) begin 
	if (~rst_n)  
		state <= INIT; 
	else	
		state <= nxt_state; 
end

ip_buffer ip_buffer_inst (.clock(clk), .data(aud_data), .rdreq(new_data), .sclr(~rst_n), .wrreq(write), .empty(empty), .full(), .q(buffer_data), .usedw()); 

always@(posedge BCLK) begin 
	if (~rst_n) 
		cntr <= 4'h0; 
	else 
		cntr <= cntr + 1; 
end


always_comb begin 
new_data = 0; 
case(state) 
	INIT: 	if (act)  
				nxt_state = SEND; 
			else
				nxt_state = INIT; 
	SEND: 	if (~empty & cntr == 4'hF) begin 
				new_data = 1'b1; 
				nxt_state = SEND; 
			end
			else begin 
				new_data = 1'b0; 
				nxt_state = SEND; 
			end
			
endcase 
end

endmodule 