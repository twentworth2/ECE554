module ALU_demo();

localparam LL = 5'b01010;
localparam LH = 5'b01011;
localparam CMP = 5'b00110;
localparam CMPR = 5'b00111;
localparam ADD = 5'b10000;
localparam ADDR = 5'b10001;
localparam SUB = 5'b10010;
localparam SUBR = 5'b10011;
localparam SHL = 5'b10100;
localparam SHR = 5'b10101;
localparam AND = 5'b10110;
localparam NOT = 5'b10111;
localparam OR = 5'b11000;
localparam XOR = 5'b11001;

int ops[14];

assign ops = '{LL, LH, CMP, CMPR, ADD, ADDR, SUB, SUBR,
               SHL, SHR, AND, NOT, OR, XOR};

localparam ITERS = 100;
localparam WAIT = 20;

// Vectors holding random numbers
reg signed [31:0] stim;
reg signed [15:0] stim1, stim2;

// Hold current opcode being tested
reg [4:0] opcode = 5'b00000;

// Keep track of ALU outputs
wire signed [15:0] out;
wire [2:0] flags;
wire set_flags;

// Instantiate the DUT
ALU iALU(.in1(stim1), .in2(stim2), .opcode(opcode), .out(out), .flags(flags), .set_flags(set_flags));

reg [15:0] LL_res, LH_res;
wire [2:0] flags_res;

assign stim1 = stim[31:16];
assign stim2 = stim[15:0];

// Mock ALU results
assign LL_res = {stim1[15:8], stim2[7:0]};
assign LH_res = {stim2[15:8], stim1[7:0]};

// Positive flag
assign flags_res[2] = stim1 < stim2;
// Zero flag
assign flags_res[1] = stim1 == stim2;
// Negative flag
assign flags_res[0] = stim1 > stim2;

reg signed [15:0] add_res,
           sub_res,
           shl_res,
           shr_res,
           and_res,
           not_res,
           or_res,
           xor_res;

// Apply the ALU operations for comparison
assign add_res = stim1 + stim2;
assign sub_res = stim1 - stim2;
assign shl_res = stim1 << stim2;
assign shr_res = stim1 >>> stim2;
assign and_res = stim1 & stim2;
assign not_res = ~stim1;
assign or_res = stim1 | stim2;
assign xor_res = stim1 ^ stim2;

integer f;
int errors = 0;

initial begin

    f = $fopen("alu_demo_results.out");

    // Add AAAA and 5555
    
    stim[31:0] = 32'hAAAA5555;
    opcode = ADD;
    #WAIT;
    
    if (out != add_res) begin
        $fwrite(f, "AAAA + 5555 was not FFFF");
        errors++;
    end
    
    // And AAAA and 5555
    
    stim[31:0] = 32'hAAAA5555;
    opcode = AND;
    #WAIT;
    
    if (out != and_res) begin
        $fwrite(f, "AAAA && 5555 was not 0000");
        errors++;
    end
    
    // Shift 0x8000 right by 0xF
    
    stim[31:0] = 32'h8000000F;
    opcode = SHR;
    #WAIT;
    
    if (out != shr_res) begin
        $fwrite(f, "8000 >>> 000F was not 0001");
        errors++;
    end
    
    // Custom operation
    
    stim[31:0] = 32'h8000000F;
    opcode = SHR;
    #WAIT;
    
    if (out != shr_res) begin
        $fwrite(f, "8000 >>> 000F was not FFFF");
        errors++;
    end
    /*
    // Iterate over all opcodes
    for (int i = 0; i < 14; i++) begin
        
        stim[31:0] = $random;
        opcode = ops[i];
        #WAIT;
        case (opcode)
        
            LL : begin
                if (out != LL_res) begin
                    $fwrite(f, "LL -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, LL_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            LH : begin
                if (out != LH_res) begin
                    $fwrite(f, "LH -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, LH_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            CMP : begin
                if (flags != flags_res) begin
                    $fwrite(f, "CMP -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", flags, flags_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            CMPR : begin
                if (flags != flags_res) begin
                    $fwrite(f, "CMPR -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", flags, flags_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            ADD : begin
                if (out != add_res) begin
                    $fwrite(f, "ADD -> ALU: %b (%d), TB: %b (%d) (in1: %b (%d), in2: %b (%d))\n", out, out, add_res, add_res, stim1, stim1, stim2, stim2);
                    errors++;
                    break;
                end
            end
            ADDR : begin
                if (out != add_res) begin
                    $fwrite(f, "ADDR -> ALU: %b (%d), TB: %b (%d) (in1: %b (%d), in2: %b (%d))\n", out, out, add_res, add_res, stim1, stim1, stim2, stim2);
                    errors++;
                    break;
                end
            end
            SUB : begin
                if (out != sub_res) begin
                    $fwrite(f, "SUB -> ALU: %b (%d), TB: %b (%d) (in1: %b (%d), in2: %b (%d))\n", out, out, sub_res, sub_res, stim1, stim1, stim2, stim2);
                    errors++;
                    break;
                end
            end
            SUBR : begin
                if (out != sub_res) begin
                    $fwrite(f, "SUBR -> ALU: %b (%d), TB: %b (%d) (in1: %b (%d), in2: %b (%d))\n", out, out, sub_res, sub_res, stim1, stim1, stim2, stim2);
                    errors++;
                    break;
                end
            end
            SHL : begin
                if (out != shl_res) begin
                    $fwrite(f, "SHL -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, shl_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            SHR : begin
                if (out != shr_res) begin
                    $fwrite(f, "SHR -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, shr_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            AND : begin
                if (out != and_res) begin
                    $fwrite(f, "AND -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, and_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            NOT : begin
                if (out != not_res) begin
                    $fwrite(f, "NOT -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, not_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            OR : begin
                if (out != or_res) begin
                    $fwrite(f, "OR -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, or_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            XOR : begin
                if (out != xor_res) begin
                    $fwrite(f, "XOR -> ALU: %b, TB: %b (in1: %b, in2: %b)\n", out, xor_res, stim1, stim2);
                    errors++;
                    break;
                end
            end
            default: begin
                $fwrite(f, "Illegal case -> opcode: %b\n", opcode);
                errors++;
                break;
            end
        endcase
    
    end
    */
    $fwrite(f, "All demo tests executed\n");
    $fwrite(f, "Errors: %d\n", errors);
    if (!errors)
        $fwrite(f, "All tests passed!\n");
    
    $fclose(f);
    $finish;

end

endmodule