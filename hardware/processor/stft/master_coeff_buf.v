module master_coeff_buf(
    input clk,
    input rst_n,
    input slave_full, // If slave buffer is full, then time to shift coeffs into master
    input [27:0] slave_coeff, // Coeff from slave buffer unit
    output reg read_sig, // Let ISTFT unit know that coeffs are being output
    output reg [27:0] master_coeff // Coeff from this unit
);

// A cached copy of the STFT coeffs
reg [27:0] master_copy [0:179];

// FSM states
localparam WAIT = 2'b00;
localparam READ = 2'b01;
localparam COPY = 2'b10;
localparam LOAD = 2'b11;

reg [1:0] state = WAIT;
reg [1:0] nxt_state = WAIT;

//reg read_sig = 1'b0; // Start reading from this buffer
reg copy_sig = 1'b0; // Start copying from slave buffer
reg rst_counter = 1'b0; // Reset counter for reads and writes
reg load_sig = 1'b0; // Load all zeros into memory
//reg read_sig = 1'b0; // Detect when reading should begin
reg count_done_set = 1'b0; // Lag one cycle when count is done

reg [7:0] coeff_num = 8'h0; // Keep track of which STFT coeff we are on

always @(posedge clk) begin
    if (~rst_n)
        coeff_num <= 8'h0;
    else if (rst_counter)
        coeff_num <= 8'h0;
    else if (read_sig || copy_sig || load_sig)
        coeff_num <= coeff_num + 1;
    else
        coeff_num <= coeff_num;
end

always @(posedge clk)
    if (read_sig)
        master_coeff <= master_copy[coeff_num];
    else
        master_coeff <= 28'h0;
        
always @(posedge clk)
    if (copy_sig)
        master_copy[coeff_num] <= slave_coeff;
        
always @(posedge clk)
    if (load_sig)
        master_copy[coeff_num] <= 28'h0;

wire count_done;
assign count_done = (coeff_num == 8'd180); // Detect when all coeffs shifted in

/*always @(posedge clk) begin
    if (~rst_n)
        read_sig_set <= 1'b0;
    else
        read_sig_set <= read_sig;
end*/

always @(posedge clk) begin
    if (~rst_n)
        count_done_set <= 1'b0;
    else
        count_done_set <= count_done;
end

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
    rst_counter = 1'b0;
    copy_sig = 1'b0;
    load_sig = 1'b0;
    
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
        // Wait until coeffs are ready
        WAIT : begin
            if (slave_full) begin
                rst_counter = 1'b1;
                nxt_state = READ;
            end else begin
                nxt_state = WAIT;
            end
        end
        // Spit out all coeffs in order
        READ : begin
            if (count_done_set) begin
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