module istft(
    input clk,
    input rst_n,
    input full, // Signal from slave buffer (CB) indicating
                // it is ready for a read
    //output reg done, // Let CB know it can read more data // Not needed, ISTFT is too slow
    output reg ready, // Let windowing buffer know next audio sample is ready
    output reg all_done, // Let windowing buffer know all samples are done
    // input istft_ack, // ISTFT unit will acknowledge new samp ready // Not needed atm
    input signed [27:0] coeff_one, // Data unit to be shifted in from the buffers
    output signed [15:0] aud_out // Current audio sample calculated by this unit
);

// Keep track of which entry we are on
reg [7:0] buf_count = 8'h0;

// Assert when copying from CB is finished
reg shft_done = 1'b0;
reg shft_sig = 1'b0;

// A local copy of the master/slave buffers
reg signed [27:0] smb_copy [0:179];

reg signed [27:0] smb_copy_prev;
reg signed [27:0] smb_copy_prev_2;
reg signed [27:0] smb_copy_prev_3;

// FSM signals
reg proc_sig = 1'b0; // Currently processing data
reg samp_sig = 1'b0; // Does nothing at the time
wire samp_done; // When the sample finding is finished
reg samp_proc_set = 1'b0; // Wait for last value to be added in
reg cache_angle = 1'b0; // Indicate to cache the current angle from the table
reg cache_angle_set = 1'b0; // Anticipate delay of memory when reading value
reg start_sqrt = 1'b0; // When to start the magnitude finding using SQRT

// Shift bit counter and set flag when finished
always @(posedge clk) begin
    if (~rst_n) begin
        buf_count <= 8'h0;
        shft_done <= 1'b0;
    end else if (shft_sig) begin
        if (buf_count < 8'd180) begin
            buf_count <= buf_count + 8'h1;
            shft_done <= 1'b0;
        end else begin
            buf_count <= 8'h0;
            shft_done <= 1'b1;
        end
    end else begin
        buf_count <= 8'h0;
        shft_done <= 1'b0;
    end
end

// Current DFT sample number
reg [7:0] k = 8'h0; // 0 to 180
// Current sample index number
reg [10:0] n = 11'h0; // 0 to 2047
// Cache angle value stored in memory for each samp
reg [16:0] curr_single_angle = 17'h0;
//wire [15:0] exp_2to22;

//wire [8:0] curr_single_angle_next = curr_single_angle + 360;

// k is off by a cycle! Cache the previous coeff.
always @(posedge clk) begin
    if (~rst_n) begin
        smb_copy_prev <= 28'h0;
    end else if (proc_sig) begin
        smb_copy_prev <= smb_copy[k];
    end else begin
        smb_copy_prev <= 28'h0;
    end
end

// k is off by a cycle! Cache the previous coeff.
always @(posedge clk) begin
    if (~rst_n) begin
        smb_copy_prev_2 <= 28'h0;
    end else if (proc_sig) begin
        smb_copy_prev_2 <= smb_copy_prev;
    end else begin
        smb_copy_prev_2 <= 28'h0;
    end
end

// k is off by a cycle! Cache the previous coeff.
always @(posedge clk) begin
    if (~rst_n) begin
        smb_copy_prev_3 <= 28'h0;
    end else if (proc_sig) begin
        smb_copy_prev_3 <= smb_copy_prev_2;
    end else begin
        smb_copy_prev_3 <= 28'h0;
    end
end

// Adjust k value due to register delays
//wire [7:0] k_2;
//assign k_2 = k < 3 ? 0 : k - 3;

// Avoid expensive memory access by caching current k-angle
always @(posedge clk) begin
    if (~rst_n)
        curr_single_angle <= 17'h0;
    else if (all_done)
        curr_single_angle <= 17'h0;
    else if (cache_angle_set)
        curr_single_angle <= curr_single_angle + 45;
    else
        curr_single_angle <= curr_single_angle;
end

// Keep track of total angle to input to sin/cos
reg [16:0] curr_accum_angle = 17'h0;
reg [9:0] curr_half_angle = 10'h0;

wire [17:0] curr_accum_angle_next = curr_accum_angle + curr_single_angle;

always @(posedge clk) begin
    if (~rst_n)
        curr_accum_angle <= 17'h0;
    else if (proc_sig)
        if (curr_accum_angle_next > 18'd92_160)
            curr_accum_angle <= curr_accum_angle_next - 18'd92_160;
        else
            curr_accum_angle <= curr_accum_angle_next;
    else
        curr_accum_angle <= 17'h0;
end

always @(posedge clk) begin
    if (~rst_n)
        curr_half_angle <= 10'h0;
    else if (proc_sig)
        curr_half_angle <= (curr_accum_angle >> 7) +
            {9'h0, curr_accum_angle[6]};// Check next lowest bit to round
    else
        curr_half_angle <= 10'h0;
end
//assign curr_64th_angle = curr_accum_angle >> 16;

// Store real component
reg signed [36:0] sum_real_cos = 37'h0;
wire signed [15:0] cos_2to14;
//reg cos_en = 1'b0;

// Intermediate register to keep product of signal and cos
wire signed [43:0] prod_real_cos;
assign prod_real_cos = (cos_2to14 * smb_copy_prev_3) >>> 8;// / 180;

// Accumulate total real magnitude
always @(posedge clk) begin
    if (~rst_n)
        sum_real_cos <= 37'h0;
    else if (proc_sig)
        if (prod_real_cos < 0)
            sum_real_cos <= sum_real_cos + ~((~prod_real_cos + 1) >> 14) + 1;
        else
            sum_real_cos <= sum_real_cos + (prod_real_cos >> 14);
    else
        sum_real_cos <= 37'h0;
end

// Continue to increment the current index
always @(posedge clk) begin
    if (~rst_n)
        k <= 8'h0;
    else if (proc_sig)
        k <= k + 1;
    else
        k <= 8'h0;
end

// Keep incrementing the samp number
always @(posedge clk) begin
    if (~rst_n)
        n <= 11'h0;
    else if (start_sqrt)
        n <= n + 1;
    else if (all_done)
        n <= 11'h0;
    else
        n <= n;
end

reg samp_proc;

always @(posedge clk) begin
    if (~rst_n)
        samp_proc <= 1'b0;
    else
        samp_proc <= (k == 8'd179);
end
//assign samp_proc = (n == 11'd2047);
/*
// Store imaginary component
reg signed [18:0] sum_imag_sin = 19'h0;
wire signed [15:0] sin_2to14;
//reg [15:0] sin_2to14 = 16'h0;


//reg sin_en = 1'b0;
// Intermediate register to keep product of signal and cos
wire signed [32:0] prod_imag_sin;
assign prod_imag_sin = (sin_2to14 * smb_copy[k]) >> 11;

wire signed [18:0] inter_prod_imag_sin;
assign inter_prod_imag_sin = ~((~prod_imag_sin + 1) >> 14) + 1;

// Accumulate total real magnitude
always @(posedge clk) begin
    if (~rst_n)
        sum_imag_sin <= 19'h0;
    else if (proc_sig)
        if (prod_imag_sin < 0)
            sum_imag_sin <= sum_imag_sin - inter_prod_imag_sin;//~((~prod_imag_sin + 1) >> 14) + 1;
        else
            sum_imag_sin <= sum_imag_sin - (prod_imag_sin >> 14);
    else
        sum_imag_sin <= 19'h0;
end*/



// Store real component
reg signed [37:0] sum_imag_sin = 38'h0;
wire signed [15:0] sin_2to14;
//reg cos_en = 1'b0;

// Intermediate register to keep product of signal and cos
wire signed [43:0] prod_imag_sin;
assign prod_imag_sin = (sin_2to14 * smb_copy_prev_3) / 180;

// Accumulate total real magnitude
always @(posedge clk) begin
    if (~rst_n)
        sum_imag_sin <= 38'h0;
    else if (proc_sig)
        if (prod_imag_sin < 0)
            sum_imag_sin <= sum_imag_sin + ~((~prod_imag_sin + 1) >> 14) + 1;
        else
            sum_imag_sin <= sum_imag_sin + (prod_imag_sin >> 14);
    else
        sum_imag_sin <= 38'h0;
end










// Compute magnitue of complex number
reg signed [54:0] total_mag = 55'h0;

always @(posedge clk) begin
    if (~rst_n)
        total_mag <= 55'h0;
    else if (samp_proc)//_set)
        total_mag <= sum_real_cos;// * sum_real_cos;//(sum_imag_sin * sum_imag_sin) + (sum_real_cos * sum_real_cos);
    else
        total_mag <= total_mag;
end

//assign total_mag = (sum_imag_sin * sum_imag_sin) + (sum_real_cos * sum_real_cos);

// FSM states
localparam INIT = 2'b00;
localparam SHFT = 2'b01;
localparam N_PROC = 2'b10;
localparam K_PROC = 2'b11;
//localparam IDLE = 2'b11;

reg [1:0] state = INIT;
reg [1:0] nxt_state = INIT;

always @(posedge clk) begin
    if (shft_sig)
        smb_copy[buf_count] <= coeff_one;
end

// STFT state machine
always @(posedge clk) begin
    if (~rst_n)
        state <= INIT;
    else
        state <= nxt_state;
end

// Wait for the exp table to be read
always @(posedge clk) begin
    if (~rst_n)
        cache_angle_set <= 1'b0;
    else
        cache_angle_set <= cache_angle;
end

always @(posedge clk) begin
    if (~rst_n)
        samp_proc_set <= 1'b0;
    else
        samp_proc_set <= samp_proc;
end

// FSM implementation
always @(*) begin
    shft_sig = 1'b0;
    proc_sig = 1'b0;
    samp_sig = 1'b0;
    cache_angle = 1'b0;
    ready = 1'b0;
    start_sqrt = 1'b0;
    all_done = 1'b0;
    
    nxt_state = INIT;
    
    case (state)
        // Wait until CB is ready
        INIT : begin
            if (full) begin
                //ack_cb = 1'b1; // CB is always lagging so this shouldn't be necessary
                nxt_state = SHFT;
            end else begin
                nxt_state = INIT;
            end
        end
        // Keep shifting in entire buffer
        SHFT : begin
            if (shft_done) begin
                cache_angle = 1'b1;
                nxt_state = N_PROC;
            end else begin
                shft_sig = 1'b1;
                nxt_state = SHFT;
            end
        end
        // Accumulate magnitude for each samp
        N_PROC : begin
            if (samp_proc) begin//_set) begin
                nxt_state = K_PROC;
                ready = 1'b1;
                start_sqrt = 1'b1;
            end else begin
                proc_sig = 1'b1;
                nxt_state = N_PROC;
            end
        end
        K_PROC : begin
            if (n == 11'd2047) begin
                all_done = 1'b1;
                nxt_state = INIT;
            end else begin
                cache_angle = 1'b1;
                nxt_state = N_PROC;
            end
        end
    endcase
end

//wire [9:0] curr_accum_angle_shft = curr_accum_angle << 1;
//wire [11:0] junk;
assign aud_out = total_mag >>> 2;

stft_cos iCOS(.clk(clk), .en(proc_sig), .deg_half(curr_half_angle), .cos_2to14(cos_2to14));
stft_sin iSIN(.clk(clk), .en(proc_sig), .deg_half(curr_half_angle), .sin_2to14(sin_2to14));
//stft_exp iEXP(.clk(clk), .en(cache_angle), .k(k), .exp_2to22(exp_2to22));
//sqrt iSQRT(.clk(clk), .rst_n(rst_n), .in(total_mag), .start(start_sqrt), .finished(samp_done), .res({junk, aud_out}));

endmodule