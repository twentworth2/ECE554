module i2c_codec_tb();
  // input and output regs
  reg clk, reset, output_buf_ne;
  reg[15:0] AudOutputData;
  // internal wires
  wire BCLK, ADC_DAT, DAC_DAT, SDAT, SCLK, ack, END, SDO, new_aud_sample, GO, MCLK, I2C_CLOCK;
  wire[15:0] AudInputData, i2c_DATA;
  wire CH1, CH2;



  always begin
    #5 clk = ~clk;
  end

  i2c iDUT(.clk(clk), .reset(reset), .act(act), .BCLK(BCLK), .output_buf_ne(output_buf_ne), .GO(GO), .I2C_CLOCK(I2C_CLOCK), .ADC_DAT(ADC_DAT), .I2C_SDAT(SDAT), .i2c_DATA(i2c_DATA), .AudOutputData(AudOutputData), .AudInputData(AudInputData), .DAC_DAT(DAC_DAT), .i2c_CLK(i2c_CLK), .ack(ack), .new_aud_sample(new_aud_sample), .END(END), .SDO(SDO));
  CLOCK_500 CL(.CLOCK(clk), .RESET(reset), .CLOCK_500(I2C_CLOCK), .DATA(i2c_DATA), .END(END), .GO(GO), .CLOCK_2(MCLK));
  codec CDC(.mclk(clk), .act(act), .ADC_DAT(ADC_DAT), .DAC_DAT(DAC_DAT), .reset(reset), .CH1(CH1), .CH2(CH2), .SDI(SDO), .SCLK(i2c_CLK), .I2C_SDAT(SDAT), .BCLK(BCLK));

  initial begin

    
    clk = 0;
    reset = 0;
    output_buf_ne = 1;
    AudOutputData = 16'h0000;

            
    #20 reset = 1;
    @(posedge act);
    $display("The activate value of our codec is ", act);
    AudOutputData = 16'h1234;
    @(posedge DAC_DAT);
    $display("The DAC_DAT line value is ", DAC_DAT);
    $stop;
    
  end


endmodule
