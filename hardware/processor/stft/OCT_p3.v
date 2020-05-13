module OCT_p3 ( // Octave +3 : has H_s = 1024
    input clk,
    input rst_n,
    input full, // Notify when to start shifting in windowed coeffs
    input ready, // Notify when audio samples ready from ISTFT
    //output reg start_fill, // Tell SPU when ISTFT unit can start reading
    input signed [15:0] istft_quarter, // Audio signal with 0.25:0.75 avg coeffs
    input signed [15:0] istft_half, // 0.5:0.5
    input signed [15:0] istft_3quarter, // 0.75:0.25
    input signed [15:0] hann_aud, // Can use right away
    output reg signed [15:0] aud_out
);

// Store current audio state buffer (store accum samples)
reg signed [15:0] curr_cb [0:2047];

// Store ISTFT output (incoming processed audio)
reg signed [15:0] istft_quarter_cb [0:2047];
reg signed [15:0] istft_half_cb [0:2047];
reg signed [15:0] istft_3quarter_cb [0:2047];

reg [11:0] buf_count = 12'd0;

reg shft_sig = 1'b0; // Decide when to fill windowed buffer
reg inc_sample = 1'b0; // Increment the current output sample index
reg set_is_undef = 1'b0; // Clear the undefined signal when buffer filled
reg is_undef = 1'b1; // Detect if buffer has been filled yet
reg buf_fill = 1'b0; // When to start filling direct audio buffer
reg istft_fill = 1'b0; // When to fill ISTFT samples buffer

// So... why use a flop to decide
// if memory is unassigned or not?
// I could have used extra FSM states,
// but this actually is lower area/power.
// Not the most elegant implementation though.
always @(posedge clk) begin
    if (~rst_n)
        is_undef <= 1'b1;
    else if (set_is_undef)
        is_undef <= is_undef & 1'b0;
end

// Keep track of where we are while prefetching
reg [8:0] curr_sample = 9'd0;

always @(posedge clk) begin
    if (~rst_n)
        curr_sample <= 9'd0;
    else if (inc_sample)
        curr_sample <= curr_sample + 9'd1;
    else
        curr_sample <= 9'd0;
end

// Spit out every 4th buffer content when prefetching
always @(posedge clk) begin
    if (inc_sample) begin
        if (is_undef) begin
            if (curr_sample < 9'd256)
                aud_out <= 16'h0000;
            else
                aud_out <= istft_half_cb[{(curr_sample - 9'd256), 2'b00}];
        end else begin
            if (curr_sample < 9'd128)
                aud_out <= curr_cb[{curr_sample, 3'b000}];
            else if (curr_sample < 9'd256)
                aud_out <= curr_cb[{curr_sample, 3'b000}] + istft_quarter_cb[{(curr_sample - 9'd128), 3'b000}];
            else if (curr_sample < 9'd384)
                aud_out <= istft_quarter_cb[{(curr_sample - 9'd128), 3'b000}] +
                            istft_half_cb[{(curr_sample - 9'd256), 3'b000}];
            else
                aud_out <= istft_half_cb[{(curr_sample - 9'd256), 3'b000}] +
                            istft_3quarter_cb[{(curr_sample - 9'd384), 3'b000}];
        end
    end else
        aud_out <= 16'h0000;
end

// Read in the overlap of ISTFT samples and audio data into the buffer
always @(posedge clk) begin
    if (shft_sig && buf_fill) begin
        if (buf_count < 12'd1024)
            curr_cb[buf_count] <= hann_aud + istft_3quarter_cb[12'd1024 + buf_count];
        else
            curr_cb[buf_count] <= hann_aud;
    end
end

always @(posedge clk) begin
    if (~rst_n)
        buf_count <= 12'd0;
    else if (istft_fill) begin
        if (ready && shft_sig)
            buf_count <= buf_count + 1;
    end else if (shft_sig)
        buf_count <= buf_count + 1;
    else
        buf_count <= 12'd0;
end

always @(posedge clk) begin
    if (istft_fill && ready) begin
        istft_quarter_cb[buf_count] <= istft_quarter;
        istft_half_cb[buf_count] <= istft_half;
        istft_3quarter_cb[buf_count] <= istft_3quarter;
    end
end

localparam WAIT = 3'b000;
localparam READ = 3'b001;
localparam PFTC = 3'b010;
localparam IDLE = 3'b011;
localparam SHFT = 3'b100;

reg [2:0] state = WAIT;
reg [2:0] nxt_state = WAIT;

// STFT state machine
always @(posedge clk) begin
    if (~rst_n)
        state <= WAIT;
    else
        state <= nxt_state;
end

// FSM implementation
always @(*) begin
    shft_sig = 1'b0;
    inc_sample = 1'b0;
    istft_fill = 1'b0;
    buf_fill = 1'b0;
    //start_fill = 1'b0;
    nxt_state = WAIT;
    
    case (state)
        // Wait for ISTFT samples
        WAIT : begin
            if (ready) begin
                nxt_state = READ;
            end else begin
                nxt_state = WAIT;
            end
        end
        // Read all 2048 samples in
        READ : begin
            if (buf_count == 12'd2046) begin
                nxt_state = PFTC;
            end else begin
                shft_sig = 1'b1;
                istft_fill = 1'b1;
                nxt_state = READ;
            end
        end
        // Precompute signal output
        PFTC : begin
            if (curr_sample == 9'd511) begin
                //start_fill = 1'b1;
                nxt_state = SHFT;
            end else begin
                nxt_state = PFTC;
                inc_sample = 1'b1;
            end
        end
        // Keep shifting in entire buffer
        SHFT : begin
            if (buf_count == 12'd2046) begin
                set_is_undef = 1'b1;
                nxt_state = WAIT;
            end else begin
                shft_sig = 1'b1;
                buf_fill = 1'b1;
                nxt_state = SHFT;
            end
        end
    endcase
end

endmodule