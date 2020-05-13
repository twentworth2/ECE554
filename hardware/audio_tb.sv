`timescale 1 ps / 1 ps
module audio_tb(); 

reg clk, rst_n; 
reg[15:0] aud_data_in, aud_data_out; 
reg full, collect, enable; 

audio_in_buff AUDIO(.clk(clk), .rst_n(rst_n), .enable(enable), .collect(collect),
	.aud_data_in(aud_data_in), .aud_data_out(aud_data_out), .full(full)); 

//fake_cpu CPU(.rst_n(rst_n), .clk(clk), .aud_data_out(aud_data_out), .full(full), .collect(collect)); 
		
fake_i2c I2C(.rst_n(rst_n), .clk(clk), .aud_data_in(aud_data_in), .enable(enable), .buffer_data(), .new_data(new_data));

initial begin 
rst_n = 1'b1; 
clk = 1'b0; 
collect = 1'b0; 
repeat(5) @(posedge clk) 
rst_n = 1'b0; 
repeat(5) @(posedge clk) 
rst_n = 1'b1; 
collect = 1'b0;
@(negedge full) 
$display("BUFFER0 full"); 
 collect = 1; 
 wait(aud_data_out == 16'h001);
 $display("correct start value BUFFER0");
 wait(aud_data_out == 16'h200); 
 $display("correct end value BUFFER0"); 
collect = 1'b0;

@(posedge full) 
$display("BUFFER1 full"); 
collect = 1'b1; 
wait(aud_data_out == 16'h201);
$display("correct start value BUFFER1");
wait(aud_data_out == 16'h400); 
$display("correct end value BUFFER1"); 
collect = 1'b0;

@(posedge full) 
$display("BUFFER2 full");
collect = 1'b1; 
wait(aud_data_out == 16'h401);
$display("correct start value BUFFER2");
wait(aud_data_out == 16'h600); 
$display("correct end value BUFFER2");  
collect = 1'b0;

@(posedge full) 
$display("BUFFER3 full"); 
collect = 1'b1; 
 wait(aud_data_out == 16'h601);
 $display("correct start value BUFFER3");
 wait(aud_data_out == 16'h800); 
 $display("correct end value BUFFER3"); 
collect = 1'b0;

@(posedge enable); 
$display("restarting"); 

collect = 1'b0;
@(posedge full) 
$display("BUFFER0 full"); 
collect = 1'b1; 
repeat(512) @(posedge clk); 
collect = 1'b0;

@(posedge full) 
$display("BUFFER1 full"); 
collect = 1'b1; 
repeat(512) @(posedge clk); 
collect = 1'b0;

@(posedge full) 
$display("BUFFER2 full");
collect = 1'b1; 
repeat(512) @(posedge clk); 
collect = 1'b0;

@(posedge full) 
$display("BUFFER3 full"); 
collect = 1'b1; 
repeat(512) @(posedge clk); 
collect = 1'b0;
$stop;

end

always 
#1 clk = ~clk;

endmodule 

