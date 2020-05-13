module APU(
    input clk,
    input rst_n,
    input [6:0] octaves,
    input octaves_en,
    output act
);
wire ack, new_aud_sample, GO, I2C_CLOCK, ADC_DAT, DAC_DAT, END, MCLK, BCLK, i2c_CLK, new_data;
wire[15:0] buffer_data, i2c_DATA;
wire collect_spu, full_aib, data_ready_spu;
wire [15:0] aud_data_out_aib, aud_out_spu;
wire [15:0] aud_data_in_aib;

audio_in_buff iAIB(.clk(clk), .rst_n(rst_n), .enable_in(new_aud_sample), .collect(collect_spu), .aud_data_in(aud_data_in_aib),
                    .aud_data_out(aud_data_out_aib), .full(full_aib));
    
SPU iSPU(.clk(clk), .rst_n(rst_n), .full(/*act*/full_aib), .done(/*not needed*/), .aud_in(aud_data_out_aib), .data_ready(data_ready_spu),
            .aud_out(aud_out_spu), .collect(collect_spu), .octaves(octaves), .octaves_en(octaves_en));
    
audio_out_buff iAOB(.clk(clk), .BCLK(BCLK), .rst_n(rst_n), .act(act), .write(data_ready_spu), .aud_data(aud_out_spu),
                .buffer_data(buffer_data), .new_data(new_data));
				
				
i2c I2C(.clk(clk), .reset(rst_n), .act(act), .BCLK(BCLK), .output_buf_ne(new_data), .GO(GO), .I2C_CLOCK(I2C_CLOCK), .ADC_DAT(ADC_DAT), .I2C_SDAT(SDAT), .i2c_DATA(i2c_DATA),
  .AudOutputData(buffer_data), .AudInputData(aud_data_in_aib), .DAC_DAT(DAC_DAT), .i2c_CLK(i2c_CLK), .ack(ack), .new_aud_sample(new_aud_sample), .END(END), .SDO(SDO));

CLOCK_500 CL(.CLOCK(clk), .RESET(rst_n), .CLOCK_500(I2C_CLOCK), .DATA(i2c_DATA), .END(END), .GO(GO), .CLOCK_2(MCLK));

codec CDC(.mclk(clk), .reset(rst_n), .act(act), .ADC_DAT(ADC_DAT), .DAC_DAT(DAC_DAT), .CH1(CH1), .CH2(CH2), .SDI(SDO), .SCLK(i2c_CLK), .I2C_SDAT(SDAT), .BCLK(BCLK));	


endmodule