module transformer(
    input en, // Enable coefficient generation
    input [27:0] slave_coeff, // Coeff from slave buffer unit
    input [27:0] master_coeff, // Coeff from master buffer unit
    
    output [27:0] quarter, // Ratio in terms of master buffer (older sound)
    output [27:0] half,
    output [27:0] three_quarters
);

wire [29:0] quarter_prec = master_coeff + (3 * slave_coeff);
assign quarter = quarter_prec >> 2;

wire [28:0] half_prec = master_coeff + slave_coeff;
assign half = half_prec >> 1;

wire [29:0] three_quarters_prec = (3 * master_coeff) + slave_coeff;
assign three_quarters = three_quarters_prec >> 2;

endmodule