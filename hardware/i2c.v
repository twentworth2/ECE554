// Date created: March 5, 2020
// Last Date Modified: March 5, 2020
// Authors: Alex Jarnutowski
// Summary: This module contains the i2c controller that communicated between
// our audio buffers and the CODEC
module i2c(clk, I2C_CLOCK, reset, i2c_DATA, I2C_SDAT, SDO, output_buf_ne, AudOutputData, i2c_CLK, ack, AudInputData, new_aud_sample, act, GO, END, BCLK, ADC_DAT, DAC_DAT);
  // port definitions
  input clk, reset, output_buf_ne, GO, I2C_CLOCK, act; 	// we pass in our normal clk for operating the audio data transfer, and a second I2C_CLOCK for
							// operating the I2C control functions
  input[15:0] i2c_DATA;					// represent data to be sent to the CODEC
  input[15:0] AudOutputData;				// processed audio data we will send serial to the CODEC
  output i2c_CLK, ack, new_aud_sample, END, SDO;
  output[15:0] AudInputData;
  inout I2C_SDAT;
  // wire declarations  
  //wire[4:0] ADC_Counter;

  reg[5:0] SD_counter;
  wire[23:0] SD;
  reg SDO;
  reg SCLK;
  reg END;
  input BCLK;

  // registers and wires for audio tx/rx
  reg Aud_state;
  reg Aud_nxt_state;
  reg[15:0] ADC_data_shift, DAC_data_shift;
  input ADC_DAT; 
  output reg DAC_DAT;
  //reg[5:0] BCLK_counter; // counts up to 60 for switching bit clock
  reg[4:0] codec_counter; // counts the number of BCLK cycles in this issue
  //reg new_aud_sample;
  reg[15:0] AudInputData;
  
  // assigns for I2C control
  assign i2c_CLK = SCLK | ( (SD_counter >= 3) & (SD_counter <= 30)) ? ~I2C_CLOCK : 1'b0; // was SD_counter >= 4
  assign I2C_SDAT = 1'bz; 

  reg ACK1, ACK2, ACK3;

  assign ack = ACK1 | ACK2 | ACK3;
  assign SD = {8'h34, i2c_DATA};

  assign new_aud_sample = (codec_counter == 16); 
  // increment the counters when we have new data
  
  always@(negedge reset, posedge I2C_CLOCK) begin
    if(~reset) begin
      SD_counter = 6'b111111;
      
    end
    else begin
      Aud_state = Aud_nxt_state;
      if(GO == 0) begin
	SD_counter = 0;
      end
      else begin
	if(SD_counter < 6'b111111) begin
	  SD_counter = SD_counter + 1;
	end
      end
    end
  end

  // sending of commands to the CODEC
  always@(negedge reset, posedge I2C_CLOCK) begin
    if(!reset) begin
      SCLK = 1;
      SDO = 1;
      ACK1 = 0;
      ACK2 = 0;
      ACK3 = 0;
      END = 1;
    end	    
    else
      case (SD_counter)
	6'd0 : begin
	  ACK1 = 0;
	  ACK2 = 0;
	  ACK3 = 0;
	  END = 0;
	  SDO = 1;
	  SCLK = 1;
  	end
	6'd1 : begin
	  
	  SDO = 0;
  	end
	6'd2 : SCLK = 0;
	6'd3 : SDO = SD[23];
	6'd4 : SDO = SD[22];
	6'd5 : SDO = SD[21];
	6'd6 : SDO = SD[20];
	6'd7 : SDO = SD[19];
	6'd8 : SDO = SD[18];
	6'd9 : SDO = SD[17];
	6'd10 : SDO = SD[16];
	6'd11 : SDO = 1'b1;//ACK

	6'd12 : begin
	  SDO = SD[15];
	  ACK1 = I2C_SDAT;
  	end
	6'd13 : SDO = SD[14];
	6'd14 : SDO = SD[13];
	6'd15 : SDO = SD[12];
	6'd16 : SDO = SD[11];
	6'd17 : SDO = SD[10];
	6'd18 : SDO = SD[9];
	6'd19 : SDO = SD[8];
	6'd20 : SDO = 1'b1;//ACK

	6'd21 : begin
	  SDO = SD[7];
	  ACK2 = I2C_SDAT;
  	end
	6'd22 : SDO = SD[6];
	6'd23 : SDO = SD[5];
	6'd24 : SDO = SD[4];
	6'd25 : SDO = SD[3];
	6'd26 : SDO = SD[2];
	6'd27 : SDO = SD[1];
	6'd28 : SDO = SD[0];
	6'd29 : SDO = 1'b1;//ACK

	6'd30 : begin
	  SDO = 1'b0;
	  SCLK = 1'b0;
	  ACK3 = I2C_SDAT;
  	end
	6'd31 : SCLK = 1'b1;
	6'd32 : begin
	  SDO = 1'b1;
	  END = 1;
  	end
      endcase
  end

  // code for audio data send and recieve
  always@(posedge clk, negedge reset) begin
    if(!reset) begin
      Aud_state = 1'b0;
      //BCLK_counter = 6'h00;
    end
    else begin
      Aud_state = Aud_nxt_state;
      /*if(BCLK_counter == 6'h3D) begin
	BCLK_counter = 6'h00;
	//BCLK = ~BCLK;
      end
      else begin
	BCLK_counter = BCLK_counter + 1;
      end*/
    end
  end

  always@(posedge BCLK, negedge reset) begin
    if(!reset) begin
      codec_counter = 5'h00;
    end
    else if(act && (Aud_state)) begin
      if(codec_counter == 5'h10) begin
        codec_counter = 5'h01;
      end
      else begin
	codec_counter = codec_counter + 1;
      end
    end
  end

  always@(posedge BCLK, negedge reset) begin
    if(!reset) begin
      
      Aud_nxt_state = 1'b0;
     // new_aud_sample = 1'b0;
    end
    else begin
      case(Aud_state)			// initial/wait state
	1'b0: begin
	  if(act) begin
	    Aud_nxt_state = 1'b1;
	    if(output_buf_ne) begin
	      DAC_data_shift = AudOutputData;
	      ADC_data_shift = {ADC_data_shift[14:0], ADC_DAT};
	      
	    end
	  end
	  else begin
	    Aud_nxt_state = 1'b0;
	  end
	end
	1'b1: begin			// receive state
	  if((codec_counter > 0) && (codec_counter <= 16)) begin
	    ADC_data_shift = {ADC_data_shift[14:0], ADC_DAT};
	    DAC_DAT = DAC_data_shift[15];
	    DAC_data_shift = {DAC_data_shift[14:0], 1'b0};
	    Aud_nxt_state = 1'b1;
	  end
	  if(codec_counter == 16) begin
	    AudInputData = ADC_data_shift;
	   // new_aud_sample = 1'b1;
	    //Aud_nxt_state = 1'b0;
	    Aud_nxt_state = 1'b1; 	// we stay in this state unless we reset because we will not issue a deactivate command to the codec
	    if(output_buf_ne) begin
	      DAC_data_shift = AudOutputData;
	    end
	  end
	  else begin
	    Aud_nxt_state = 1'b1;
	  end
	end
	default: begin
	  Aud_nxt_state = 1'b0;
	  //new_aud_sample = 1'b0;
	end
      endcase
    end
  end

endmodule