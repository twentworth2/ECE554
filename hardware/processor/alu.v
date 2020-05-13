// ECE 554 Spring 2020
// The Music Group
// non-STFT ALU portion of the CPU
// Ilhan Bok

module ALU(
    input signed [15:0] in1, // First alu operand
    input signed [15:0] in2, // Second alu operand
    input   [4:0] opcode, // Full opcode of instruction
    output signed [15:0] out, // alu output
    output  [2:0] flags, // Positive, zero, and negative flags
    output  set_flags // Whether the instruction updates the flags or not
    );

// Instruction opcodes for reference
localparam LL = 5'b01000;
localparam LH = 5'b01001;
localparam SHL = 5'b01101;
localparam SHR = 5'b01110;
localparam AND = 5'b11000;
localparam NOT = 5'b10011;
localparam OR = 5'b11011;
localparam XOR = 5'b11100;
localparam ADDR = 5'b11001; 
localparam SUBR = 5'b11010; 
localparam ADD = 5'b01011;
localparam SUB = 5'b01100; 
localparam CMP = 5'b01010; 
localparam CMPR = 5'b10100;


// Set convention for flags
wire P, Z, N;

assign flags[2] = P;
assign flags[1] = Z;
assign flags[0] = N;

// Negate second operand for SUB instructions
wire [15:0] add2;
//assign add2 = opcode[1] ? ~in2 + 1'b1 : in2;
assign add2 = (opcode == SUB | opcode == SUBR | opcode == CMP | opcode == CMPR) ? ~in2 + 1'b1 : in2; 
wire signed [15:0] shr_res = in1 >>> in2;

// Notify if flags changed
assign set_flags = (opcode == CMP | opcode == CMPR | opcode == ADD | opcode == ADDR | opcode == SUB | opcode == SUBR);

assign N = (set_flags & (in1 < in2)) ? 1'b1 : 1'b0; 
assign Z = (set_flags & (in1 == in2)) ? 1'b1 : 1'b0;
assign P = (set_flags & (in1 > in2))  ? 1'b1 : 1'b0;

// Bulk of the ALU computation happens here
assign out = (opcode == LL) ? {in1[15:8], in2[7:0]} : // Load lower
             (opcode == LH) ? {in2[15:8], in1[7:0]} : // Load higher
             (opcode == ADD | opcode == ADDR | opcode == SUB | opcode == SUBR | opcode == CMP | opcode == CMPR) ? in1 + add2 : // ADD or SUB
             (opcode == SHL) ? in1 << in2 : // SHL
             (opcode == SHR) ? shr_res : // SHR
             (opcode == AND) ? in1 & in2 : // AND
             (opcode == NOT) ? ~in1 : // NOT
             (opcode == OR) ? in1 | in2 : // OR
             (opcode == XOR) ? in1 ^ in2 : //XOR
             (opcode == 5'b00000) ? 16'h0000 : //noop
			 in1; // No opcode matched

endmodule