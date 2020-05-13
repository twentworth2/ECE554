module haz(
    input memread_id, // Whether a read from memory is occuring in the EX stage (IDEX flop)
    input [2:0] r_id_rd, // Destination of the read from memory
    input [2:0] r_if_1, /// Two possible regs that could be impacted by the read
    input [2:0] r_if_2, /// (Second reg)
    output stall // Whether to stall in decode
);

assign stall = memread_id && ((r_id_rd == r_if_1) || (r_id_rd == r_if_2));

endmodule