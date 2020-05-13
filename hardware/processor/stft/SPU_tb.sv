`timescale 1 ps / 1 ps
module SPU_tb();

//reg en_window = 1'b1;
reg clk, rst_n;
reg full_set, next_set_set;
reg [15:0] aud_in_set;

reg [6:0] octaves;
reg octaves_en;

wire [15:0] aud_out_mon;
wire data_ready_mon;

always #10 clk = ~clk;

SPU iSPU(.clk(clk), .rst_n(rst_n), .full(full_set), .done(), .aud_in(aud_in_set),
            .data_ready(data_ready_mon), .aud_out(aud_out_mon), .collect(), .octaves(octaves), .octaves_en(octaves_en));

reg signed [15:0] sine_64 [0:2047];
reg signed [15:0] sine_512 [0:2047];

initial begin

    $readmemb("signed_64_sine.txt", sine_64);
    $readmemb("signed_512_sine.txt", sine_512);
    
    clk = 1'b0;
    rst_n = 1'b0;
    
    repeat (2) @(posedge clk);
    
    rst_n = 1'b1;
    
    repeat (2048) @(posedge clk);
    
    full_set = 1'b1;
    octaves = 7'b1111111;
    octaves_en = 1'b1;
    
    @(posedge clk);
    
    octaves_en = 1'b0;
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        aud_in_set = sine_64[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (500_000) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        aud_in_set = sine_512[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (500_000) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        aud_in_set = sine_512[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (500_000) @(posedge clk);
    
    full_set = 1'b1;
    
    @(posedge clk);
    
    full_set = 1'b0;
    
    // Load in sound waveform
    for (int i = 0; i < 2048; i++) begin
        aud_in_set = sine_512[i];
        @(posedge clk);
    end
    
    repeat (2) @(posedge clk);
    
    next_set_set = 1'b1;
    
    @(posedge clk);
    
    next_set_set = 1'b0;
    
    repeat (500_000) @(posedge clk);
    
    $stop;
    
end

endmodule