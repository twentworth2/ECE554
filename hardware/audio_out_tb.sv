`timescale 1 ps / 1 ps
module audio_out_tb();

reg clk, rst_n, enable, write, new_data; 
reg[15:0] buffer_data, aud_data; 
aud_data_out OUT(.clk(clk), .rst_n(rst_n), .ack(enable), .write(write), .aud_data(aud_data), .buffer_data(buffer_data), .new_data(new_data)); 

fake_i2c I2C(.rst_n(rst_n), .clk(clk), .aud_data_in(), .enable(enable), .buffer_data(buffer_data), .new_data(new_data));
initial begin 
clk = 0; 
rst_n = 1; 
aud_data = 16'h000;
write = 0;  
@(posedge clk) 
rst_n = 0; 
repeat(5) @(posedge clk); 
rst_n = 1; 
for (integer i = 0; i < 2048; i = i + 1) begin 
	@(posedge clk)
	aud_data = i+1; 
	write = 1; 
end
@(posedge clk) 
write = 0; 
@(negedge new_data); 
if(buffer_data == 16'h800) 
	$display("Correct final value, test passed"); 
else
	$display("incorrect final value, test failed"); 
$stop; 
end

always
#1 clk = ~clk; 

endmodule 