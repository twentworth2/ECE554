module OCT_tb();

//reg en_window = 1'b1;
reg clk, rst_n;
reg full_set, next_set_set;
reg [15:0] hann_aud_set;

wire [15:0] aud_out_mon;

always #10 clk = ~clk;

//SPU_window iWIN(.clk(clk), .en(en_window), .sig_num(sig_num_set), .hann_coeff(hann_coeff_mon));

OCT_n3 iOCT_n3(.clk(clk), .rst_n(rst_n), .full(full_set), .hann_aud(hann_aud_set), .next_set(next_set_set),
                .aud_out(aud_out_mon));

reg signed [15:0] sine_64 [0:2047];

initial begin

    $readmemb("signed_double_sine.txt", sine_64);
    
    clk = 1'b0;
    rst_n = 1'b0;
    next_set_set = 1'b1;
    
    repeat (2) @(posedge clk);
    
    rst_n = 1'b1;
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (2048) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        hann_aud_set = sine_64[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (2048) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        hann_aud_set = sine_64[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (2048) @(posedge clk);
    
    $stop;
    
end

endmodule