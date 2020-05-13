module sqrt_tb();

reg clk, rst_n;
reg start;

reg [54:0] find_sqrt;

wire finished;
wire [27:0] sqrt_res;

sqrt iSQRT(.clk(clk), .rst_n(rst_n), .in(find_sqrt), .start(start),
            .finished(finished), .res(sqrt_res));
            

always #10 clk = ~clk;

integer f; // File to store results
int passed;

initial begin

    // Set up testing environment
    passed = 0;
    
    rst_n = 1'b0;
    clk = 1'b0;
    start = 1'b0;
    
    f = $fopen("sqrt_test_results.out");
    
    repeat (2) @(posedge clk);
    
    rst_n = 1'b1;
    
    // Start feeding in values to find sqrt
    
    find_sqrt = 55'd8464; // 92 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd92) begin
        $fwrite(f, "(PASS) Square root of 8464 is 92\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 8464 is %d?\n", sqrt_res);
        
    @(posedge clk);
    
    find_sqrt = 55'd149_769; // 387 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd387) begin
        $fwrite(f, "(PASS) Square root of 149,769 is 387\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 149,769 is %d?\n", sqrt_res);
        
    @(posedge clk);
    
    find_sqrt = 55'd1_234_321; // 1111 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd1111) begin
        $fwrite(f, "(PASS) Square root of 1,234,321 is 1111\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 1,234,321 is %d?\n", sqrt_res);
        
    @(posedge clk);
    
    find_sqrt = 55'd268_435_455; // 16,383 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd16_383) begin
        $fwrite(f, "(PASS) Square root of 268,435,455 is 16,383\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 268,435,455 is %d?\n", sqrt_res);
        
    @(posedge clk);
    
    find_sqrt = 55'd0; // 0 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd0) begin
        $fwrite(f, "(PASS) Square root of 0 is 0\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 0 is %d?\n", sqrt_res);
        
    @(posedge clk);
    
    find_sqrt = 55'd4; // 2 squared
    start = 1'b1;
    
    repeat (2) @(negedge clk);
    
    start = 1'b0;
    
    @(posedge finished);
    
    if (sqrt_res == 28'd2) begin
        $fwrite(f, "(PASS) Square root of 4 is 2\n");
        passed++;
    end else
        $fwrite(f, "(FAIL) Square root of 4 is %d?\n", sqrt_res);
        
        
    $fwrite(f, "Results: %d / 6 passed (%d failed)", passed, 6 - passed);
        
    $fclose(f);
    $finish;

end

endmodule