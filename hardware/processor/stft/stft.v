module stft(
    input clk,
    input rst_n,
    input full, // Signal from circular buffer (CB) indicating
                // CB is ready for a read
    output reg done, // Let CB know it can read more data
    output reg ready, // Let ISTFT unit know the coeff is ready
    output reg all_done, // Let ISTFT buffer know all coeffs are done
    input istft_ack, // ISTFT unit will acknowledge new coeff ready
    input signed [15:0] datum, // Data unit to be shifted in from the CB
    output [27:0] coeff // Current coefficient calculated by this unit
);

// Keep track of which entry we are on
reg [11:0] buf_count = 12'h0;

// Assert when copying from CB is finished
reg shft_done = 1'b0;
reg shft_sig = 1'b0;

// A local copy of the circular buffer
reg signed [15:0] cb_copy [0:2047];

// FSM signals
reg proc_sig = 1'b0; // Currently processing data
reg coeff_sig = 1'b0; // Does nothing at the time
wire coeff_done; // When the magnitude finding is finished
reg coeff_proc_set = 1'b0; // Wait for last value to be added in
reg cache_angle = 1'b0; // Indicate to cache the current angle from the table
reg cache_angle_set = 1'b0; // Anticipate delay of memory when reading value
reg start_sqrt = 1'b0; // When to start the magnitude finding using SQRT

// Shift bit counter and set flag when finished
always @(posedge clk) begin
    if (~rst_n) begin
        buf_count <= 12'h0;
        shft_done <= 1'b0;
    end else if (shft_sig) begin
        if (buf_count < 12'd2048) begin
            buf_count <= buf_count + 12'h1;
            shft_done <= 1'b0;
        end else begin
            buf_count <= 12'h0;
            shft_done <= 1'b1;
        end
    end else begin
        buf_count <= 12'h0;
        shft_done <= 1'b0;
    end
end

// Current DFT coefficient number
reg [7:0] k = 8'h0; // 0 to 179
// Current sample index number
reg [10:0] n = 11'h0; // 0 to 2047
// Cache angle value stored in memory for each coeff
reg [15:0] curr_single_angle = 16'h0;
//wire [15:0] exp_2to22;

// Avoid expensive memory access by caching current k-angle
always @(posedge clk) begin
    if (~rst_n)
        curr_single_angle <= 16'h0;
    else if (all_done)
        curr_single_angle <= 16'h0;
    else if (cache_angle_set)
        curr_single_angle <= curr_single_angle + 360;
    else
        curr_single_angle <= curr_single_angle;
end

// Keep track of total angle to input to sin/cos
reg [27:0] curr_accum_angle = 28'h0;
reg [9:0] curr_half_angle = 10'h0;

wire [27:0] curr_accum_angle_next = curr_accum_angle + curr_single_angle;

always @(posedge clk) begin
    if (~rst_n)
        curr_accum_angle <= 28'h0;
    else if (proc_sig)
        if (curr_accum_angle_next > 28'd737_280)
            curr_accum_angle <= curr_accum_angle_next - 28'd737_280;
        else
            curr_accum_angle <= curr_accum_angle_next;
    else
        curr_accum_angle <= 28'h0;
end

always @(posedge clk) begin
    if (~rst_n)
        curr_half_angle <= 10'h0;
    else if (proc_sig)
        curr_half_angle <= (curr_accum_angle >> 10) +
            {9'h0, curr_accum_angle[9]};// Check next lowest bit to round
    else
        curr_half_angle <= 10'h0;
end

//assign curr_64th_angle = curr_accum_angle >> 16;

// Store real component
reg signed [27:0] sum_real_cos = 28'h0;
wire signed [15:0] cos_2to14;
//reg cos_en = 1'b0;

// Intermediate register to keep product of signal and cos
wire signed [31:0] prod_real_cos;
assign prod_real_cos = cos_2to14 * cb_copy[n];

// Accumulate total real magnitude
always @(posedge clk) begin
    if (~rst_n)
        sum_real_cos <= 28'h0;
    else if (proc_sig)
        if (prod_real_cos < 0)
            sum_real_cos <= sum_real_cos + ~((~prod_real_cos + 1) >> 14) + 1;
        else
            sum_real_cos <= sum_real_cos + (prod_real_cos >> 14);
    else
        sum_real_cos <= 28'h0;
end

// Continue to increment the current index
always @(posedge clk) begin
    if (~rst_n)
        n <= 11'h0;
    else if (proc_sig)
        n <= n + 1;
    else
        n <= 11'h0;
end

// Keep incrementing the coeff number
always @(posedge clk) begin
    if (~rst_n)
        k <= 8'h0;
    else if (start_sqrt)
        k <= k + 1;
    else if (all_done)
        k <= 8'h0;
    else
        k <= k;
end

reg coeff_proc;

always @(posedge clk) begin
    if (~rst_n)
        coeff_proc <= 1'b0;
    else
        coeff_proc <= (n == 11'd2047);
end
//assign coeff_proc = (n == 11'd2047);

// Store imaginary component
reg signed [27:0] sum_imag_sin = 28'h0;
wire signed [15:0] sin_2to14;
//reg [15:0] sin_2to14 = 16'h0;


//reg sin_en = 1'b0;
// Intermediate register to keep product of signal and cos
wire signed [31:0] prod_imag_sin;
assign prod_imag_sin = sin_2to14 * cb_copy[n];

wire signed [17:0] inter_prod_imag_sin;
assign inter_prod_imag_sin = ~((~prod_imag_sin + 1) >> 14) + 1;

// Accumulate total real magnitude
always @(posedge clk) begin
    if (~rst_n)
        sum_imag_sin <= 28'h0;
    else if (proc_sig)
        if (prod_imag_sin < 0)
            sum_imag_sin <= sum_imag_sin - inter_prod_imag_sin;//~((~prod_imag_sin + 1) >> 14) + 1;
        else
            sum_imag_sin <= sum_imag_sin - (prod_imag_sin >> 14);
    else
        sum_imag_sin <= 28'h0;
end

// Compute magnitue of complex number
reg [54:0] total_mag = 55'h0;

always @(posedge clk) begin
    if (~rst_n)
        total_mag <= 55'h0;
    else if (coeff_proc_set)
        total_mag <= (sum_imag_sin * sum_imag_sin) + (sum_real_cos * sum_real_cos);
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
        cb_copy[buf_count] <= datum;
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
        coeff_proc_set <= 1'b0;
    else
        coeff_proc_set <= coeff_proc;
end

// FSM implementation
always @(*) begin
    shft_sig = 1'b0;
    done = 1'b0;
    proc_sig = 1'b0;
    coeff_sig = 1'b0;
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
                done = 1'b1;
                nxt_state = N_PROC;
            end else begin
                shft_sig = 1'b1;
                nxt_state = SHFT;
            end
        end
        // Accumulate magnitude for each coeff
        N_PROC : begin
            if (coeff_proc_set) begin
                nxt_state = K_PROC;
                start_sqrt = 1'b1;
            end else begin
                proc_sig = 1'b1;
                nxt_state = N_PROC;
            end
        end
        K_PROC : begin
            if (coeff_done) begin
                ready = 1'b1;
                if (k >= 8'd180) begin
                    all_done = 1'b1;
                    nxt_state = INIT;
                end else begin
                    cache_angle = 1'b1;
                    nxt_state = N_PROC;
                end
            end else begin
                coeff_sig = 1'b1;
                nxt_state = K_PROC;
            end
        end
    endcase
end

stft_cos iCOS(.clk(clk), .en(proc_sig), .deg_half(curr_half_angle), .cos_2to14(cos_2to14));
stft_sin iSIN(.clk(clk), .en(proc_sig), .deg_half(curr_half_angle), .sin_2to14(sin_2to14));
//stft_exp iEXP(.clk(clk), .en(cache_angle), .k(k), .exp_2to22(exp_2to22));
sqrt iSQRT(.clk(clk), .rst_n(rst_n), .in(total_mag), .start(start_sqrt), .finished(coeff_done), .res(coeff));

endmodule