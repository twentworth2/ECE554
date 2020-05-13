module OCT_n2 ( // Octave -2 : has H_s = 128
    input clk,
    input rst_n,
    input full, // Notify when to start shifting in windowed coeffs
    input signed [15:0] hann_aud, // Must divide this by 8 before using
    input next_set, // Tell unit(s) when to start prefetching
    output reg signed [15:0] aud_out
);

// Store current audio state buffer
reg signed [15:0] curr_cb [0:2047];

reg [11:0] buf_count = 12'd0;

reg shft_sig = 1'b0; // Decide when to fill windowed buffer
reg inc_sample = 1'b0; // Increment the current output sample index
reg set_is_undef = 1'b0; // Clear the undefined signal when buffer filled
reg is_undef = 1'b1; // Detect if buffer has been filled yet

always @(posedge clk) begin
    if (~rst_n)
        buf_count <= 12'd0;
    else if (shft_sig)
        buf_count <= buf_count + 1;
    else
        buf_count <= 12'd0;
end

always @(posedge clk) begin
    if (shft_sig) begin
        if (is_undef)
            curr_cb[buf_count] <= hann_aud >>> 3;
        else if (buf_count + 12'd128 < 12'd2048)
            curr_cb[buf_count] <= curr_cb[buf_count + 12'd128] + (hann_aud >>> 3);
        else
            curr_cb[buf_count] <= hann_aud >>> 3;
    end
end

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

reg [8:0] curr_sample = 9'd0;

always @(posedge clk) begin
    if (~rst_n)
        curr_sample <= 9'd0;
    else if (inc_sample)
        curr_sample <= curr_sample + 9'd1;
    else
        curr_sample <= 9'd0;
end

always @(posedge clk) begin
    if (inc_sample) begin
        if (is_undef)
            aud_out <= 16'h0000;
        else
            aud_out <= curr_cb[curr_sample[8:2]] * (3'h4 - curr_sample[1:0]) +
                                curr_cb[curr_sample[8:2] + 7'd1] * curr_sample[1:0];
    end else
        aud_out <= 16'h0000;
end

localparam INIT = 2'b00;
localparam PFTC = 2'b01;
localparam IDLE = 2'b10;
localparam SHFT = 2'b11;

reg [1:0] state = INIT;
reg [1:0] nxt_state = INIT;

// STFT state machine
always @(posedge clk) begin
    if (~rst_n)
        state <= INIT;
    else
        state <= nxt_state;
end

// FSM implementation
always @(*) begin
    shft_sig = 1'b0;
    inc_sample = 1'b0;
    nxt_state = INIT;
    
    case (state)
        // Wait until CB is ready
        INIT : begin
            if (next_set) begin
                nxt_state = PFTC;
            end else begin
                nxt_state = INIT;
            end
        end
        // Precompute signal output
        PFTC : begin
            if (curr_sample == 9'd511) begin
                nxt_state = IDLE;
            end else begin
                nxt_state = PFTC;
                inc_sample = 1'b1;
            end
        end
        // Wait for CB to become ready
        IDLE : begin
            if (full) begin
                nxt_state = SHFT;
            end else begin
                nxt_state = IDLE;
            end
        end
        // Keep shifting in entire buffer
        SHFT : begin
            if (buf_count == 12'd2048) begin
                set_is_undef = 1'b1;
                nxt_state = INIT;
            end else begin
                shft_sig = 1'b1;
                nxt_state = SHFT;
            end
        end
    endcase
end

endmodule