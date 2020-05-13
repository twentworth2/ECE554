module i2c_tb();
  //inputs and outputs
  reg clk, BCLK, reset, output_buf_ne, ADC_DAT, act;
  reg[15:0] AudOutputData;
  wire DAC_DAT, i2c_CLK, ack, new_aud_sample, END, SDO;
  wire[15:0] AudInputData, i2c_DATA; 

  wire GO, I2C_CLOCK, MCLK, I2C_SDAT;

  always begin
    #5 clk = ~clk;
  end

  always begin
    #150 BCLK = ~BCLK; //attempt to set BCLK to run ~38 cycles for every 44.1khz cycle
  end
  
  i2c iDUT(.clk(clk), .reset(reset), .act(act), .BCLK(BCLK), .output_buf_ne(output_buf_ne), .GO(GO), .I2C_CLOCK(I2C_CLOCK), .ADC_DAT(ADC_DAT), .I2C_SDAT(I2C_SDAT), .i2c_DATA(i2c_DATA), .AudOutputData(AudOutputData), .AudInputData(AudInputData), .DAC_DAT(DAC_DAT), .i2c_CLK(i2c_CLK), .ack(ack), .new_aud_sample(new_aud_sample), .END(END), .SDO(SDO));
  CLOCK_500 CL(.CLOCK(clk), .RESET(reset), .CLOCK_500(I2C_CLOCK), .DATA(i2c_DATA), .END(END), .GO(GO), .CLOCK_2(MCLK));

  initial begin
    reset = 0;
    BCLK = 0;
    clk = 0;
    output_buf_ne = 0;
    ADC_DAT = 0;
    act = 0;
    AudOutputData = 16'h03d6;
    
    #20 reset = 1;
    
    $stop;
  end

endmodule
