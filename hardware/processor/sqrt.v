// Compute the floor of the square root
// of a given 55 bit number
module sqrt(
    input clk,
    input rst_n,
    input [54:0] in,
    input start,
    output reg finished = 1'b0,
    output reg [27:0] res = 28'h800_0000
);

// One-hot encoding of bit being inspected
reg [27:0] curr_bit = 28'h000_0000;

// State markers for sqrt process code
reg prod_sig, clr_sig;

// FSM states
localparam PROD = 1'b0;
localparam IDLE = 1'b1;

reg state = IDLE;
reg nxt_state = IDLE;

// Keep track of tentative product
wire [54:0] curr_prod;
// TODO: Interesting... the FPGA has
// 27 x 27 multipliers but not
// 28 x 28 so for now we will truncate
// the lowest bit and lose a bit of
// precision, later we can test the full
// 28 x 28 multiplier.
assign curr_prod = ((res[27:1] * res[27:1]) << 2) | {{27{1'b0}}, res[0]};

always @(posedge clk) begin
    if (~rst_n | clr_sig) begin
        res <= 28'h800_0000;
        finished <= 1'b0;
    end else if (prod_sig) begin
        finished <= 1'b0;
        // If the product is too large
        // then the bit was set incorrectly
        // so clear it
        if (curr_prod > in)
            res <= res & (~curr_bit) | (curr_bit >> 1); 
        // Otherwise set the next lower bit
        // to give the multiplier time
        // to find the product
        else
            res <= res | (curr_bit >> 1);
    end else begin
        finished <= 1'b1;
    end
end

// Convert the current count to one-hot
always @(posedge clk) begin
    if (prod_sig) begin
        case (curr_bit)
            28'h000_0000 : curr_bit <= 28'h800_0000;
            default : curr_bit <= curr_bit >> 1;
        endcase
    end
end

// Multiplication state machine
always @(posedge clk) begin
    if (~rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
end

// FSM implementation
always @(*) begin
    prod_sig = 1'b0;
    clr_sig = 1'b0;
    nxt_state = IDLE;
    
    case (state)
        // Wait until told to start
        IDLE : begin
            if (start) begin
                prod_sig = 1'b1;
                clr_sig = 1'b1;
                nxt_state = PROD;
            end else begin
                nxt_state = IDLE;
            end
        end
        // Entire number has been found
        PROD : begin
            if (curr_bit == 28'h000_0000) begin
                nxt_state = IDLE;
            end else begin
                prod_sig = 1'b1;
                nxt_state = PROD;
            end
        end
    endcase
end

endmodule