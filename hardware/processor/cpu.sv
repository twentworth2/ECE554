`timescale 1 ps / 1 ps

module cpu(clk, rst_n, pc, hlt, octaves, octaves_en);

// Instruction opcodes for reference
localparam LDR = 5'b10001;
localparam LD = 5'b10000;
localparam LL = 5'b01000;
localparam LH = 5'b01001;
localparam ST = 5'b10010;
localparam BRE = 5'b00001;
localparam BRG = 5'b00010;
localparam CMP = 5'b01010;
localparam CMPR = 5'b10100;
localparam ADD = 5'b01011;
localparam ADDR = 5'b11001;
localparam SUB = 5'b01100;
localparam SUBR = 5'b11010;
localparam SHL = 5'b01101;
localparam SHR = 5'b01110;
localparam AND = 5'b11000;
localparam NOT = 5'b10011;
localparam OR = 5'b11011;
localparam XOR = 5'b11100;
localparam NOOP = 5'b00000;
localparam HLT = 5'b11111;

input clk, rst_n; 
output [15:0] pc;
output hlt; 


output [6:0] octaves;
output octaves_en;

wire rst = ~rst_n;

wire[15:0] MW_out, MW_alu_out, mem_out, MW_mem_out, MEM_alu_out, MEM_out;
wire [15:0] iRD_MEM_out, iRD_WB_out;
wire regwrite_ex, regwrite_mem, regwrite_wb;

wire[15:0] new_PC, PC_plus1; 
wire mem_mux;
//Register PC
Register PC(.clk(clk), .rst(~rst_n), .D(new_PC), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(pc), .Bitline2());
wire[15:0] branch_addr; 
wire should_branch; 

assign new_PC = (should_branch) ? branch_addr : PC_plus1;

assign PC_plus1 = pc + 1; 
//adder PC_ADD(.dataa(pc), .result(new_PC));

wire[2:0] flags; 
wire[15:0] old_flags_; 
wire[2:0] old_flags; 

assign old_flags = old_flags_[2:0]; 

Register FLGS(.clk(clk), .rst(~rst_n), .D({13'h0000, flags}), .WriteReg(set_flags), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(old_flags_), .Bitline2()); 

wire[15:0] r7; 

////FETCH

wire[15:0] F_instr, D_instr, flush_F_instr; 
 
i_mem I_MEM(.address(pc), .clock(clk), .rden(1'b1), .q(F_instr)); 
assign flush_F_instr = (should_branch) ? 16'h0000 : F_instr;

branch_calc BRANCH(.Dinstr(D_instr), .pc(pc), .r7(r7), .flags(flags), .branch_addr(branch_addr), .should_branch(should_branch)); 

///DECODE
Register D_PC(.clk(clk), .rst(~rst_n), .D(flush_F_instr), .WriteReg(~stall_LTU), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(D_instr), .Bitline2()); 


wire [15:0] mem_new_reg, new_reg, alu_in1, alu_in2; 
wire wren_in, wren_out; //write to register control
wire [2:0] write_addr_in, write_addr_out; //which register to write to 

wire[4:0] opcode; 
wire [7:0] imm; 
wire ren_mem, wren_mem; 
wire set_r7; 
wire [15:0] r7_value; 

// Holds the register numbers for ALU operands
wire [2:0] r_rf1_ID, r_rf2_ID; // direct output of ID
wire [15:0] ID_REG_FWD_out; // After being flopped to EX

decode DECODE(.clk(clk), .rst_n(rst_n), .wren_in(regwrite_wb), .new_reg(new_reg), .write_addr_in(iRD_WB_out[2:0]), .write_addr_out(write_addr_out),
				.curr_instr(D_instr), .alu_in1(alu_in1), .alu_in2(alu_in2), .opcode(opcode), .wren_out(wren_out), .imm(imm), .ren_mem(ren_mem), .wren_mem(wren_mem),
				.is_branch(is_branch), .hlt(hlt),
    .read1_reg(r_rf1_ID), .read2_reg(r_rf2_ID), .set_r7(set_r7), .r7_value(r7_value)) ; 

wire [15:0] ID_out, ID_2_out; 



 Register R7(.clk(clk), .rst(~rst_n), .D(r7_value), .WriteReg(~stall_LTU), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(r7), .Bitline2());

Register ID(.clk(clk), .rst(~rst_n), .D({wren_mem, ren_mem, wren_out, imm, opcode}), .WriteReg(~stall_LTU), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(ID_out), .Bitline2()); 
Register ID_2(.clk(clk), .rst(~rst_n), .D({13'h0000, write_addr_out}), .WriteReg(~stall_LTU), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(ID_2_out), .Bitline2());

Register ID_REG_FWD(.clk(clk), .rst(~rst_n), .D({10'h000, r_rf1_ID, r_rf2_ID}), .WriteReg(~stall_LTU), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(ID_REG_FWD_out), .Bitline2());

///EXECUTE 
wire[15:0] alu_out; 

wire[15:0] EX_out, EX_alu_out; 
///// FORWARDING //>>>>>
wire [4:0] opcode_id; 
assign opcode_id = ID_out[4:0];
wire regwrite_id = !(opcode_id == ST || opcode_id == BRE || opcode_id == BRG || opcode_id == CMP || opcode_id == CMPR
                        || opcode_id == NOOP || opcode_id == HLT);
wire [15:0] iRD_EX_out;


wire x2x_1, x2x_2, m2x_1, m2x_2, wb2x_1, wb2x_2;

fwd iFWD(.r_rf1(ID_REG_FWD_out[5:3]), .r_rf2(ID_REG_FWD_out[2:0]), .r_ex(iRD_EX_out[2:0]), .r_mem(iRD_MEM_out[2:0]), .r_wb(iRD_WB_out[2:0]), 
        .regwrite_ex(regwrite_ex), .regwrite_mem(regwrite_mem), .x2x_1(x2x_1), .x2x_2(x2x_2), .m2x_1(m2x_1), .m2x_2(m2x_2), .wb2x_1(wb2x_1), .wb2x_2(wb2x_2), .regwrite_wb(regwrite_wb));

// FORWARDING /////<<<<<

///// HAZARD //>>>>>

haz iHAZ(.memread_id(opcode_id == LDR), .r_id_rd(ID_2_out[2:0]), .r_if_1(r_rf1_ID), .r_if_2(r_rf2_ID), .stall(stall_LTU));

// HAZARD /////<<<<<
/// setOctaves alias (LL R0, #imm)

assign octaves = ID_out[11:5]; // discard uppermost bit from immediate
assign octaves_en = (opcode_id == LL) && (ID_2_out[2:0] == 3'b000);

execute EXECUTE(.clk(clk), .rst_n(rst_n), .alu_in1(x2x_1 ? EX_alu_out : (m2x_1 ? mem_new_reg : (wb2x_1 ? new_reg : alu_in1))),
                .alu_in2(x2x_2 ? EX_alu_out : (m2x_2 ? mem_new_reg : (wb2x_2 ? new_reg : alu_in2))), .opcode(ID_out[4:0]), .alu_out(alu_out),
                .flags(flags), .set_flags(set_flags), .imm(ID_out[12:5])); 

Register EX(.clk(clk), .rst(~rst_n), .D({ID_out[15], ID_out[14], ID_out[13], ID_2_out[2:0], ID_2_out[4:3], 8'h00}), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(EX_out), .Bitline2()); 
Register EX_alu(.clk(clk), .rst(~rst_n), .D(alu_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(EX_alu_out), .Bitline2());

// Pass the regwrite signal from ID to EX
dff iREGW_EX(.clk(clk), .rst(~rst_n), .wen(1'b1), .d(regwrite_id), .q(regwrite_ex));

// Destination register for forwarding unit passed to EX stage
Register iRD_EX(.clk(clk), .rst(~rst_n), .D(ID_2_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(iRD_EX_out), .Bitline2());

//MEM

//mem MEM(.writeEn(EX_out[15]), .readEn(EX_out[14]), wraddr, .rdaddr); 

Register MEM_alu(.clk(clk), .rst(rst), .D(EX_alu_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(MEM_alu_out), .Bitline2());
Register MEM_data(.clk(clk), .rst(rst), .D(mem_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(MW_mem_out), .Bitline2());
Register MEM(.clk(clk), .rst(~rst_n), .D(MEM_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(MW_out), .Bitline2());

Register MW(.clk(clk), .rst(~rst_n), .D({2'b00, EX_out[13], EX_out[9:8], EX_out[12:10], 8'h00}), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(MEM_out), .Bitline2());
Register MW_new_reg(.clk(clk), .rst(rst), .D(MEM_alu_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(MW_alu_out), .Bitline2());

i_mem D_mem(.address(EX_alu_out), .clock(clk), .rden(1'b1), .q(mem_out));

// Pass the regwrite signal from EX to MEM
dff iREGW_MEM(.clk(clk), .rst(~rst_n), .wen(1'b1), .d(regwrite_ex), .q(regwrite_mem));
dff iREGW_WB(.clk(clk), .rst(~rst_n), .wen(1'b1), .d(regwrite_mem), .q(regwrite_wb)); 

// Destination register for forwarding unit passed to MEM stage
Register iRD_MEM(.clk(clk), .rst(~rst_n), .D(iRD_EX_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(iRD_MEM_out), .Bitline2());
Register iRD_WB(.clk(clk), .rst(~rst_n), .D(iRD_MEM_out), .WriteReg(1'b1), .ReadEnable1(1'b1), .ReadEnable2(), .Bitline1(iRD_WB_out), .Bitline2());
//WB
assign mem_mux = MW_out[12:8] == 5'b1001 ? 1'b1 : 1'b0;

assign wren_in = MW_out[13]; 
assign write_addr_in = MW_out[12:10]; 
assign new_reg = mem_mux ? MW_mem_out : MW_alu_out; 

assign mem_new_reg = MEM_out[12:8] == 5'b1001 ? mem_out : MEM_alu_out;

endmodule