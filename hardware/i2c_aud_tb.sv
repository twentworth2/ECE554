`timescale 1 ps / 1 ps
module i2c_aud_tb();
  // inputs and outputs
  reg clk, rst_n; 



/*  collect, write;
  
   internal wires
  wire ack, new_aud_sample, GO, I2C_CLOCK, ADC_DAT, DAC_DAT, END, MCLK, BCLK, i2c_CLK, new_data;
  wire[15:0] aud_data_in, aud_data_out, aud_data, buffer_data, i2c_DATA;
   
   test signals
  wire CH1, CH2;
  
   modules
  
  audio_out_buff AOB(.clk(clk), .BCLK(BCLK), .rst_n(reset), .act(act), /*from i2c*/// .write(write), .aud_data(aud_data), .buffer_data(buffer_data), .new_data(new_data));
 /* audio_in_buff AIB(.clk(clk), .rst_n(reset), .enable_in(new_aud_sample), .collect(collect), .aud_data_in(aud_data_in), .aud_data_out(aud_data_out), .full(full));
  i2c iDUT(.clk(clk), .reset(reset), .act(act), .BCLK(BCLK), .output_buf_ne(new_data), .GO(GO), .I2C_CLOCK(I2C_CLOCK), .ADC_DAT(ADC_DAT), .I2C_SDAT(SDAT), .i2c_DATA(i2c_DATA),
  .AudOutputData(buffer_data), .AudInputData(aud_data_in), .DAC_DAT(DAC_DAT), .i2c_CLK(i2c_CLK), .ack(ack), .new_aud_sample(new_aud_sample), .END(END), .SDO(SDO));
  CLOCK_500 CL(.CLOCK(clk), .RESET(reset), .CLOCK_500(I2C_CLOCK), .DATA(i2c_DATA), .END(END), .GO(GO), .CLOCK_2(MCLK));
  codec CDC(.mclk(clk), .act(act), .ADC_DAT(ADC_DAT), .DAC_DAT(DAC_DAT), .reset(reset), .CH1(CH1), .CH2(CH2), .SDI(SDO), .SCLK(i2c_CLK), .I2C_SDAT(SDAT), .BCLK(BCLK));
 
 fake_cpu CPU(.rst_n(reset), .clk(clk), .aud_data_out(aud_data), .write(write)); 
  SPU iSPU(.clk(clk), .rst_n(rst_n), .full(full), .done(/*not needed*//*), .aud_in(aud_data_out), .data_ready(write),
            .aud_out(aud_data), .collect(collect));
	*/
APU apu(.clk(clk), .rst_n(rst_n)); 
  
  // clock
  always begin
    #5 clk = ~clk;
  end
  
  // test
 initial begin
    clk = 1'b0;
    rst_n = 1'b0;

 

    #100 rst_n = 1'b1;
	@(posedge apu.act) 
	$display("act recieved"); 
	
  end
  
endmodule