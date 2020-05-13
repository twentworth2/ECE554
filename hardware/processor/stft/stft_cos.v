module stft_cos(
    input clk,
    input en, // Allow a read
    input [9:0] deg_half, // Fixed-point angle in degrees,
                           // rounded to the nearest half
    output reg signed [15:0] cos_2to14 // 16 bit cosine value (must divide by 2^14)
);

reg [15:0] vals [0:720];

initial begin
    $readmemb("rough_cos_table.txt", vals);
end

always @(posedge clk) begin
    if (en)
        cos_2to14 <= vals[deg_half];
    else
        cos_2to14 <= 16'h0;
end

endmodule