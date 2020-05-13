`include "ip_buffer512.v"
`timescale 1 ps / 1 ps

module audio_in_buff(
	input clk, 
	input rst_n, 
	input reg enable_in,//from i2c (new_aud_sample) 
	input collect,//from cpu 
	input[15:0] aud_data_in, 
	output[15:0] aud_data_out, 
	output reg full
	); 
reg enable;  
reg full1, full2, full3, full0; 
reg empty1, empty2, empty3, empty0; 
reg[8:0] usedw1, usedw2, usedw3, usedw0; 
reg collect1, collect2, collect3, collect0; 
reg enable1, enable2, enable3, enable0; 
reg[15:0] aud_data_out0, aud_data_out1, aud_data_out2, aud_data_out3; 

reg [15:0] cntr; 

typedef enum reg [2:0] {INIT, BUFFER0, BUFFER1, BUFFER2, BUFFER3} state_t; 
state_t write_state, nxt_write_state, read_state, nxt_read_state; 

//buffer BUFFER(.clk(clk), .we(enable), .waddr(write_ptr), .raddr(read_ptr), .wdata(aud_data_in), .rdata(aud_data_out)); 
ip_buffer512	IN_BUFFER0(.clock(clk), .data(aud_data_in), .rdreq(collect0), .sclr(~rst_n), .empty(empty0), .wrreq(enable0), .full(full0),
		.q(aud_data_out0), .usedw(usedw0));
ip_buffer512	IN_BUFFER1(.clock(clk), .data(aud_data_in), .rdreq(collect1), .sclr(~rst_n), .empty(empty1), .wrreq(enable1), .full(full1),
		.q(aud_data_out1), .usedw(usedw1));
ip_buffer512	IN_BUFFER2(.clock(clk), .data(aud_data_in), .rdreq(collect2), .sclr(~rst_n), .empty(empty2), .wrreq(enable2), .full(full2),
		.q(aud_data_out2), .usedw(usedw2));
ip_buffer512	IN_BUFFER3(.clock(clk), .data(aud_data_in), .rdreq(collect3), .sclr(~rst_n), .empty(empty3), .wrreq(enable3), .full(full3),
		.q(aud_data_out3), .usedw(usedw3));

assign aud_data_out = 	(read_state == BUFFER0) ? aud_data_out0 : 
						(read_state == BUFFER1) ? aud_data_out1 : 
						(read_state == BUFFER2) ? aud_data_out2 :
						(read_state == BUFFER3) ? aud_data_out3 :
						16'h000; 
						
always@(posedge clk, negedge rst_n) begin 
	if (~rst_n) 
		enable <= 1'b0; 
	else if (enable_in & cntr == 16'h000)
		enable <= 1'b1; 
	else 
		enable <= 1'b0; 
end 

always@(posedge clk, negedge enable_in) begin 
	if (~rst_n) 
		cntr <= 16'h000; 
	else if (~enable_in) 
		cntr <= 16'h000; 
	else 
		cntr <= cntr + 1; 
end 

//flop states 
always_ff@(posedge clk, negedge rst_n) begin 
	if (~rst_n) 
		write_state <= INIT; 
	else 
		write_state <= nxt_write_state; 
end

always_ff@(posedge clk, negedge rst_n) begin 
	if (~rst_n) 
		read_state <= INIT; 
	else
		read_state <= nxt_read_state; 
end

always_comb begin 
//default outputs
enable0 = 1'b0; 
enable1 = 1'b0; 
enable2 = 1'b0;
enable3 = 1'b0;
full = 1'b0;  
case (write_state) 
	INIT: 	if (enable & ~full0) begin 
				nxt_write_state = BUFFER0; 
				enable0 = 1'b1; 
			end
			else
				nxt_write_state = INIT; 
	BUFFER0:if(full0 & enable & ~full1) begin 
				nxt_write_state = BUFFER1; 
				enable1 = 1'b1;
				enable0 = 1'b0; 
				full = 1'b1; 
			end
			else if (enable & ~full0) begin 
				enable0 = 1'b1; 
				nxt_write_state = BUFFER0;
			end
			else begin 
				enable0 = 1'b0; 
				nxt_write_state = BUFFER0; 
			end
	BUFFER1: if(full1 & enable & ~full2) begin	
				nxt_write_state = BUFFER2; 
				enable2 = 1'b1;
				enable1 = 1'b0; 
				full = 1'b1; 
			end
			else if (enable & ~full1) begin 
				enable1 = 1'b1; 
				nxt_write_state = BUFFER1; 
			end
			else begin 
				enable1 = 1'b0; 
				nxt_write_state = BUFFER1; 
			end
	BUFFER2: if (full2 & enable & ~full3) begin 
				nxt_write_state = BUFFER3;
				enable3 = 1'b1; 
				enable2 = 1'b0; 
				full = 1'b1; 
			end
			else if (enable & ~full2) begin 
				enable2 = 1'b1; 
				nxt_write_state = BUFFER2; 
			end
			else begin 
				enable2 = 1'b0; 
				nxt_write_state = BUFFER2; 
			end
	BUFFER3: if (full3) begin 
				nxt_write_state = INIT;
				enable3 = 1'b0; 
				full = 1'b1; 
			end
			else if (enable & ~full3) begin 
				nxt_write_state = BUFFER3;
				enable3 = 1'b1; 
			end
			else begin 
				enable3 = 1'b0; 
				nxt_write_state = BUFFER3; 
			end
	default: begin 
			enable0 = 1'b0; 
			enable1 = 1'b0; 
			enable2 = 1'b0; 
			enable3 = 1'b0; 
			nxt_write_state = INIT; 
			end
endcase
end 

always_comb begin 
//default outputs
collect0 = 1'b0; 
collect1 = 1'b0; 
collect2 = 1'b0;
collect3 = 1'b0;
case(read_state) 
	INIT: if (full) begin  
			nxt_read_state = BUFFER0; 
			collect0 = collect; 
		end
		else begin 
			nxt_read_state = INIT; 
			//collect3 = 0; 
		end
	BUFFER0: if(empty0 & full) begin 
			nxt_read_state = BUFFER1;
			collect1 = collect; 
			collect0 = 1'b0; 
		end
		else begin 
			nxt_read_state = BUFFER0; 
			collect0 = collect;
		end
	BUFFER1: if(empty1 & full) begin 
				nxt_read_state = BUFFER2; 
				collect2 = collect; 
				collect1 = 1'b0; 
			end
			else begin 
			nxt_read_state = BUFFER1; 
			collect1 = collect; 
			//collect0 = 0; 
			end
	BUFFER2: if(empty2 & full) begin 
				nxt_read_state = BUFFER3; 
				collect3 = collect; 
				collect2 = 1'b0; 
			end
			else begin 
				nxt_read_state = BUFFER2; 
				collect2 = collect; 
				//collect1 = 0; 
			end
	BUFFER3: if (empty3 & full) begin 
				nxt_read_state = INIT; 
				collect3 = 1'b0; 
			end
			else begin 
				nxt_read_state = BUFFER3; 
				collect3 = collect;
				//collect2 = 0; 
			end
	default: begin 
				nxt_read_state = INIT; 
				collect0 = 1'b0; 
				collect1 = 1'b0; 
				collect2 = 1'b0; 
				collect3 = 1'b0; 
			end
			
endcase 
end 
		
endmodule

			