module slave_coeff_buf(
    input clk,
    input rst_n,
    input ready, // Alerted when next coeff ready
    input [27:0] coeff, // Coeff from STFT unit
    output reg read_sig, // Let ISTFT unit know that coeffs are being output
    output reg slave_full, // If slave buffer is full, then time to shift coeffs into master
    output reg [27:0] slave_coeff // Coeff from this unit
);

// A cached copy of the STFT coeffs
reg [27:0] slave_copy [0:179];

// FSM states
localparam WAIT = 2'b00;
localparam READ = 2'b01;
localparam COPY = 2'b10;
localparam LOAD = 2'b11;

reg [1:0] state = LOAD;
reg [1:0] nxt_state = LOAD;

//reg read_sig = 1'b0; // Start reading from this buffer
reg copy_sig = 1'b0; // Start copying to master buffer
reg rst_counter = 1'b0; // Reset counter for reads and writes
reg load_sig = 1'b0; // Load all zeros into memory
//reg read_sig = 1'b0; // Detect when reading should begin

reg [7:0] coeff_num = 8'h0; // Keep track of which STFT coeff we are on

always @(posedge clk) begin
    if (~rst_n)
        coeff_num <= 8'h0;
    else if (rst_counter)
        coeff_num <= 8'h0;
    else if (ready || read_sig || copy_sig || load_sig)
        coeff_num <= coeff_num + 1;
    else
        coeff_num <= coeff_num;
end

always @(posedge clk)
    if (ready)
        slave_copy[coeff_num] <= coeff;
    else if (load_sig)
        slave_copy[coeff_num] <= 28'h0;

always @(posedge clk)
    if (read_sig | copy_sig)
        slave_coeff <= slave_copy[coeff_num];
    else
        slave_coeff <= 28'h0;
        
/*always @(posedge clk)
    if (copy_sig)
        slave_coeff <= slave_copy[coeff_num];
        
always @(posedge clk)
    if (load_sig)
        slave_copy[coeff_num] <= 28'h0;*/

wire count_done = (coeff_num == 8'd180); // Detect when all coeffs shifted in

/*always @(posedge clk) begin
    if (~rst_n)
        read_sig_set <= 1'b0;
    else
        read_sig_set <= read_sig;
end*/

// MCB state machine
always @(posedge clk) begin
    if (~rst_n)
        state <= LOAD;
    else
        state <= nxt_state;
end

// FSM implementation
always @(*) begin
    read_sig = 1'b0;
    slave_full = 1'b0;
    load_sig = 1'b0;
    rst_counter = 1'b0;
    copy_sig = 1'b0;
    
    nxt_state = WAIT;
    
    case (state)
        // Load all zeros into memory
        LOAD : begin
            if (count_done) begin
                rst_counter = 1'b1;
                nxt_state = WAIT;
            end else begin
                load_sig = 1'b1;
                nxt_state = LOAD;
            end
        end
        // Be alert for new coeffs from STFT unit
        WAIT : begin
            if (count_done) begin
                rst_counter = 1'b1;
                slave_full = 1'b1;
                nxt_state = READ;
            end else begin
                nxt_state = WAIT;
            end
        end
        // Spit out all coeffs in order
        READ : begin
            if (count_done) begin
                rst_counter = 1'b1;
                nxt_state = COPY;
            end else begin
                read_sig = 1'b1;
                nxt_state = READ;
            end
        end
        // Read in coeffs from slave buffer
        COPY : begin
            if (count_done) begin
                nxt_state = WAIT;
                rst_counter = 1'b1;
            end else begin
                copy_sig = 1'b1;
                nxt_state = COPY;
            end
        end
    endcase
end

endmodule 