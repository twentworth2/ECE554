`timescale 1 ps / 1 ps
`include "FIFO.v"

module SPU(
    input clk,
    input rst_n,
    input full, // Signal from circular buffer (CB) indicating
                // CB is ready for a read
    output done, // Let CB know it can read more data
    input signed [15:0] aud_in, // Data unit to be shifted in from the CB
    output reg data_ready, // Let AOB know there is data available
    output signed [15:0] aud_out, // Data to be passed to the AOB
    output reg collect, // Alert CB that CPU is waiting for next samples
    input [6:0] octaves, // one-hot octaves config, lowest bit is lowest octave
    input octaves_en // read or ignore provided octaves
);

// FSM controlled signals

reg shft_sig_Z, shft_sig_I2, shft_sig_SOLA, prefetch_SOLA, inc_sample_I2;
reg wind_sig_I;

// Hann windowing switches

reg en_window_SOLA;
reg en_window_ISTFT;

wire samp_ready_istft1;

// When to start reading in cached coeffs
wire start_fill;

wire [15:0] hann_coeff, hann_coeff_ISTFT;

reg [8:0] buf_count_SOLA_PFTC = 9'd0;

always @(posedge clk) begin
    if (~rst_n)
        buf_count_SOLA_PFTC <= 9'd0;
    else if (prefetch_SOLA)
        buf_count_SOLA_PFTC <= buf_count_SOLA_PFTC + 1;
    else
        buf_count_SOLA_PFTC <= 9'd0;
end

// The current value index to spit out of the SPU
reg [8:0] curr_sample_I2 = 9'd0;

always @(posedge clk) begin
    if (~rst_n)
        curr_sample_I2 <= 9'd0;
    else if (inc_sample_I2)
        curr_sample_I2 <= curr_sample_I2 + 1;
    else
        curr_sample_I2 <= 9'd0;
end

// All seven arrays necessary to hold pitched audio samples

wire signed [15:0] aud_out_n3;
wire signed [15:0] aud_out_n2;
wire signed [15:0] aud_out_n1;
wire signed [15:0] aud_out_p1;
wire signed [15:0] aud_out_p2;
wire signed [15:0] aud_out_p3;

reg signed [15:0] ch_n3;
reg signed [15:0] ch_n2;
reg signed [15:0] ch_n1;
reg signed [15:0] ch_z0;
reg signed [15:0] ch_p1;
reg signed [15:0] ch_p2;
reg signed [15:0] ch_p3;

reg signed [15:0] aud_p3 [0:511];
reg signed [15:0] aud_p2 [0:511];
reg signed [15:0] aud_p1 [0:511];
reg signed [15:0] aud_z0 [0:511];
reg signed [15:0] aud_n1 [0:511];
reg signed [15:0] aud_n2 [0:511];
reg signed [15:0] aud_n3 [0:511];

// Sets the octaves when enabled, otherwise
// maintaining previous value
reg [6:0] reg_octaves;

always @(posedge clk) begin
    if (~rst_n) begin
        reg_octaves <= 7'b1111111;
    end else if (octaves_en) begin
        reg_octaves <= octaves;
    end
end

// Cache audio samples so that ISTFT can run in parallel
reg signed [15:0] aud_ch [0:2047];
reg signed [15:0] aud_ch2 [0:2047];

always @(posedge clk) begin
    if (prefetch_SOLA) begin
        aud_n3[buf_count_SOLA_PFTC] <= aud_out_n3;
        aud_n2[buf_count_SOLA_PFTC] <= aud_out_n2;
        aud_n1[buf_count_SOLA_PFTC] <= aud_out_n1;
        aud_p1[buf_count_SOLA_PFTC] <= aud_out_p1;
    end
end

always @(posedge clk) begin
    if (~rst_n)
        data_ready <= 1'b0;
    else if (inc_sample_I2)
        data_ready <= 1'b1;
    else
        data_ready <= 1'b0;
end

always @(posedge clk) begin
    if (inc_sample_I2) begin
        ch_n3 <= reg_octaves[0] ? aud_n3[curr_sample_I2] : 16'd0;
        ch_n2 <= reg_octaves[1] ? aud_n2[curr_sample_I2] : 16'd0;
        ch_n1 <= reg_octaves[2] ? aud_n1[curr_sample_I2] : 16'd0;
        ch_z0 <= reg_octaves[3] ? aud_z0[curr_sample_I2] : 16'd0;
        ch_p1 <= reg_octaves[4] ? aud_p1[curr_sample_I2] : 16'd0;
        ch_p2 <= reg_octaves[5] ? aud_out_p2 : 16'd0;
        ch_p3 <= reg_octaves[6] ? aud_out_p3 : 16'd0;
    end else begin
        ch_n3 <= 16'd0;
        ch_n2 <= 16'd0;
        ch_n1 <= 16'd0;
        ch_z0 <= 16'd0;
        ch_p1 <= 16'd0;
        ch_p2 <= 16'd0;
        ch_p3 <= 16'd0;
    end
end

wire signed [18:0] aud_out_sum = ch_n3 + ch_n2 + ch_n1 + ch_z0 + ch_p1 + ch_p2 + ch_p3;
assign aud_out = aud_out_sum / 7;

wire all_done;

reg [8:0] buf_count_Z = 9'd0;

always @(posedge clk) begin
    if (~rst_n)
        buf_count_Z <= 9'd0;
    else if (shft_sig_Z)
        buf_count_Z <= buf_count_Z + 1;
    else
        buf_count_Z <= 9'd0;
end

reg [10:0] buf_count_SOLA = 11'd0;

always @(posedge clk) begin
    if (~rst_n)
        buf_count_SOLA <= 11'd0;
    else if (shft_sig_SOLA)
        buf_count_SOLA <= buf_count_SOLA + 1;
    else
        buf_count_SOLA <= 11'd0;
end

reg [10:0] buf_count_I = 11'd0;

always @(posedge clk) begin
    if (~rst_n)
        buf_count_I <= 11'd0;
    else if (wind_sig_I) begin
        if (samp_ready_istft1)
            buf_count_I <= buf_count_I + 1;
    end else
        buf_count_I <= 11'd0;
end

// Window ISTFT coeffs when they are ready

localparam IDLE_I = 1'b0;
localparam WIND_I = 1'b1;

reg state_I = IDLE_I;
reg nxt_state_I = IDLE_I;

// ISTFT state machine
always @(posedge clk) begin
    if (~rst_n)
        state_I <= IDLE_I;
    else
        state_I <= nxt_state_I;
end

// ISTFT FSM implementation
always @(*) begin
    wind_sig_I = 1'b0;
    en_window_ISTFT = 1'b0;
    nxt_state_I = IDLE_I;
    
    case (state_I)
        // Wait for CB to become ready
        IDLE_I : begin
            if (samp_ready_istft1) begin
                nxt_state_I = WIND_I;
            end else begin
                nxt_state_I = IDLE_I;
            end
        end
        // Directly window outputs of ISTFT units
        WIND_I : begin
            if (buf_count_I == 12'd2047) begin
                nxt_state_I = IDLE_I;
            end else begin
                wind_sig_I = 1'b1;
                en_window_ISTFT = 1'b1;
                nxt_state_I = WIND_I;
            end
        end
    endcase
end

reg [10:0] buf_count_I2 = 11'd0;

always @(posedge clk) begin
    if (~rst_n)
        buf_count_I2 <= 11'd0;
    else if (shft_sig_I2)
        buf_count_I2 <= buf_count_I2 + 1;
    else
        buf_count_I2 <= 11'd0;
end

// Start fetching cached samples for ISTFT
localparam IDLE_I2 = 2'b00;
localparam PFTC_I2 = 2'b01;
localparam READ_I2 = 2'b10;

reg [1:0] state_I2 = IDLE_I2;
reg [1:0] nxt_state_I2 = IDLE_I2;

// ISTFT state machine
always @(posedge clk) begin
    if (~rst_n)
        state_I2 <= IDLE_I2;
    else
        state_I2 <= nxt_state_I2;
end

// ISTFT FSM implementation
always @(*) begin
    shft_sig_I2 = 1'b0;
    inc_sample_I2 = 1'b0;
    nxt_state_I2 = IDLE_I2;
    
    case (state_I2)
        // Wait for CB to become ready
        IDLE_I2 : begin
            if (start_fill) begin
                nxt_state_I2 = PFTC_I2;
            end else begin
                nxt_state_I2 = IDLE_I2;
            end
        end
        PFTC_I2 : begin
            if (curr_sample_I2 == 9'd511) begin
                nxt_state_I2 = READ_I2;
            end else begin
                inc_sample_I2 = 1'b1;
                nxt_state_I2 = PFTC_I2;
            end
        end
        // Directly window outputs of ISTFT units
        READ_I2 : begin
            if (buf_count_I2 == 12'd2047) begin
                nxt_state_I2 = IDLE_I2;
            end else begin
                shft_sig_I2 = 1'b1;
                nxt_state_I2 = READ_I2;
            end
        end
    endcase
end

reg signed [15:0] cached_hann_prod;

always @(posedge clk) begin
    if (shft_sig_I2)
        cached_hann_prod <= aud_ch2[buf_count_I2];
    else
        cached_hann_prod <= 16'd0;
end


wire [27:0] coeff, coeff_one, slave_coeff, master_coeff, coeff_istft1, coeff_istft2, coeff_istft3;
wire signed [15:0] aud_out_istft1, aud_out_istft2, aud_out_istft3;


stft iSTFT(.clk(clk), .rst_n(rst_n), .full(full), .done(done),
            .ready(ready), .istft_ack(), .datum(aud_in), .coeff(coeff), .all_done(all_done));
  
slave_coeff_buf iSLV(.clk(clk), .rst_n(rst_n), .ready(ready), .coeff(coeff), .slave_full(slave_full),
            .slave_coeff(slave_coeff), .read_sig(slave_read_sig));
  
master_coeff_buf iMST(.clk(clk), .rst_n(rst_n), .slave_full(slave_full), .slave_coeff(slave_coeff),
            .read_sig(master_read_sig), .master_coeff(master_coeff));

transformer iTRF(.en(slave_read_sig), .slave_coeff(slave_coeff), .master_coeff(master_coeff),
            .quarter(coeff_istft1), .half(coeff_istft2), .three_quarters(coeff_istft3));

// The three ISTFT units (1/4, 1/2, 3/4)
istft iISTFT1(.clk(clk), .rst_n(rst_n), .full(slave_read_sig), .ready(samp_ready_istft1),
            .all_done(), .coeff_one(coeff_istft1), .aud_out(aud_out_istft1));
            
istft iISTFT2(.clk(clk), .rst_n(rst_n), .full(slave_read_sig), .ready(samp_ready_istft2),
            .all_done(), .coeff_one(coeff_istft2), .aud_out(aud_out_istft2));
            
istft iISTFT3(.clk(clk), .rst_n(rst_n), .full(slave_read_sig), .ready(samp_ready_istft3),
            .all_done(), .coeff_one(coeff_istft3), .aud_out(aud_out_istft3));

wire signed [16:0] hann_coeff_ISTFT_pos = {1'b0, hann_coeff_ISTFT};
wire signed [31:0] hann_prod_ISTFT1 = hann_coeff_ISTFT_pos * aud_out_istft1;
wire signed [31:0] hann_prod_ISTFT2 = hann_coeff_ISTFT_pos * aud_out_istft2;
wire signed [31:0] hann_prod_ISTFT3 = hann_coeff_ISTFT_pos * aud_out_istft3;
wire signed [15:0] norm_hann_prod_ISTFT1 = hann_prod_ISTFT1 >>> 16;
wire signed [15:0] norm_hann_prod_ISTFT2 = hann_prod_ISTFT2 >>> 16;
wire signed [15:0] norm_hann_prod_ISTFT3 = hann_prod_ISTFT3 >>> 16;

// FIFO for storing original signal to put back output

wire [15:0] AIB_cached;

FIFO iFIFO(
	.clock(clk),
	.data(aud_in),
	.rdreq(shft_sig_Z),
	.sclr(~rst_n),
	.wrreq(shft_sig_Z),
	.q(AIB_cached));
    
always @(posedge clk) begin
    if (shft_sig_Z)
        aud_z0[buf_count_Z] <= AIB_cached;
end
    
localparam IDLE_Z = 1'b0;
localparam SHFT_Z = 1'b1;

reg state_Z = IDLE_Z;
reg nxt_state_Z = IDLE_Z;

// FIFO state machine
always @(posedge clk) begin
    if (~rst_n)
        state_Z <= IDLE_Z;
    else
        state_Z <= nxt_state_Z;
end

// FIFO FSM implementation
always @(*) begin
    shft_sig_Z = 1'b0;
    nxt_state_Z = IDLE_Z;
    
    case (state_Z)
        // Wait for CB to become ready
        IDLE_Z : begin
            if (full) begin
                nxt_state_Z = SHFT_Z;
            end else begin
                nxt_state_Z = IDLE_Z;
            end
        end
        // Shift in 512 oldest samples into FIFO
        SHFT_Z : begin
            if (buf_count_Z == 9'd511) begin
                nxt_state_Z = IDLE_Z;
            end else begin
                shft_sig_Z = 1'b1;
                nxt_state_Z = SHFT_Z;
            end
        end
    endcase
end

// Hann windowing coefficient reader

SPU_window iWIN(.clk(clk), .en(en_window_SOLA), .sig_num(buf_count_SOLA), .hann_coeff(hann_coeff));
SPU_window iWIN3(.clk(clk), .en(en_window_ISTFT), .sig_num(buf_count_I), .hann_coeff(hann_coeff_ISTFT));

// Instantiate audio SOLA units

localparam PFTC_SOLA = 2'b00;
localparam IDLE_SOLA = 2'b01;
localparam SHFT_SOLA = 2'b10;

reg [1:0] state_SOLA = PFTC_SOLA;
reg [1:0] nxt_state_SOLA = PFTC_SOLA;

// SOLA state machine
always @(posedge clk) begin
    if (~rst_n)
        state_SOLA <= PFTC_SOLA;
    else
        state_SOLA <= nxt_state_SOLA;
end

// SOLA FSM implementation
always @(*) begin
    shft_sig_SOLA = 1'b0;
    en_window_SOLA = 1'b0;
    prefetch_SOLA = 1'b0;
    collect = 1'b0;
    nxt_state_SOLA = IDLE_SOLA;
    
    case (state_SOLA)
        PFTC_SOLA : begin
            if (buf_count_SOLA_PFTC == 9'd511) begin
                nxt_state_SOLA = IDLE_SOLA;
            end else begin
                prefetch_SOLA = 1'b1;
                nxt_state_SOLA = PFTC_SOLA;
            end
        end
        // Wait for CB to become ready
        IDLE_SOLA : begin
            if (full) begin
                nxt_state_SOLA = SHFT_SOLA;
            end else begin
                //collect = 1'b1;
                nxt_state_SOLA = IDLE_SOLA;
            end
        end
        // Shift in windowed samples into SOLA units
        SHFT_SOLA : begin
            if (buf_count_SOLA == 12'd2047) begin
                nxt_state_SOLA = PFTC_SOLA;
            end else begin
                //if (buf_count_SOLA[8:0] == 9'd0)
                collect = 1'b1;
                shft_sig_SOLA = 1'b1;
                en_window_SOLA = 1'b1;
                nxt_state_SOLA = SHFT_SOLA;
            end
        end
    endcase
end

wire signed [16:0] hann_coeff_pos = {1'b0, hann_coeff};
wire signed [31:0] hann_prod = hann_coeff_pos * aud_in;
wire signed [15:0] norm_hann_prod = hann_prod >>> 16;

// The SOLA group of octaves requires basically no DSP {-3, -2, -1, +1}
OCT_n3 i_n3(.clk(clk), .rst_n(rst_n), .full(full), .hann_aud(norm_hann_prod), .next_set(prefetch_SOLA),
                .aud_out(aud_out_n3));
OCT_n2 i_n2(.clk(clk), .rst_n(rst_n), .full(full), .hann_aud(norm_hann_prod), .next_set(prefetch_SOLA),
                .aud_out(aud_out_n2));
OCT_n1 i_n1(.clk(clk), .rst_n(rst_n), .full(full), .hann_aud(norm_hann_prod), .next_set(prefetch_SOLA),
                .aud_out(aud_out_n1));                
OCT_p1 i_p1(.clk(clk), .rst_n(rst_n), .full(full), .hann_aud(norm_hann_prod), .next_set(prefetch_SOLA),
                .aud_out(aud_out_p1));
                
// Cache current windowed audio for future use ISTFT
always @(posedge clk) begin
    if (shft_sig_SOLA) begin
        aud_ch[buf_count_SOLA] <= norm_hann_prod;
        aud_ch2[buf_count_SOLA] <= aud_ch[buf_count_SOLA];
    end
end

// The two upper octaves {+2, +3} require some extra effort
OCT_p2 i_p2(.clk(clk), .rst_n(rst_n), .full(full), .ready(samp_ready_istft2), .start_fill(start_fill), 
            .istft_half(norm_hann_prod_ISTFT2), .hann_aud(cached_hann_prod/*norm_hann_prod*/), .aud_out(aud_out_p2));
OCT_p3 i_p3(.clk(clk), .rst_n(rst_n), .full(full), .ready(samp_ready_istft2), .istft_quarter(norm_hann_prod_ISTFT1),
            .istft_half(norm_hann_prod_ISTFT2), .istft_3quarter(norm_hann_prod_ISTFT3), .hann_aud(cached_hann_prod),
            .aud_out(aud_out_p3));
                      
endmodule