module tb_sdram_self_refresh ();

    logic           s_clk       = 0;   // System Clock
    logic           s_rstn      = 0;   // Active-Low Reset
    logic           self_ref_en = 0;   // Self-Refresh Enable
    
    logic           sdram_cke;         // SDRAM Clock Enable
    logic [3:0]     sdram_cmd;         // SDRAM Command Bus
    logic [1:0]     sdram_ba;          // SDRAM Bank Address
    logic [11:0]    sdram_addr;        // SDRAM Address Bus
    logic           self_ref_done;     // Self-Refresh Done Signal
    
    logic [15:0]    sdram_dq;          // Bi-Directional Data Bus
    logic           init_done;
    
        assign init_done = 1;
    
    // Generate 100MHz clock (10ns period)
    always #5 s_clk = ~s_clk;

    // Reset Sequence
    initial begin
        s_rstn = 1'b0;
        repeat(5) @(posedge s_clk);
        s_rstn = 1'b1;
    end
 
    // Trigger Self-Refresh
    initial begin
        repeat(10) @(posedge s_clk);
        self_ref_en = 1'b1; // Enable Self-Refresh
        repeat(15) @(posedge s_clk);
        self_ref_en = 1'b0; // Disable Self-Refresh (Exit)
    end
 
    // Monitor Self-Refresh Completion
    initial begin
        @(posedge self_ref_done);
        $display("Self-Refresh Completed!");
        @(posedge s_clk);
        $finish;
    end
 
    // Instantiate Self-Refresh Module
    sdram_self_refresh  sdram_self_refresh_inst (
        .sys_clk        (s_clk),
        .sys_rst_n      (s_rstn),
        .self_ref_en    (self_ref_en),
        .sdram_init     (init_done),
        .sdram_cke      (sdram_cke),
        .sdram_cmd      (sdram_cmd),
        .sdram_ba       (sdram_ba),
        .sdram_addr     (sdram_addr),
        .self_ref_done  (self_ref_done)
    );
 
    // Instantiate SDRAM Model
    sdram_model_plus  sdram_model_plus_inst (
        .Dq         (sdram_dq),        // Bi-directional Data Bus
        .Addr       (sdram_addr),      // Address Bus
        .Ba         (sdram_ba),        // Bank Address
        .Clk        (s_clk),           // Clock
        .Cke        (sdram_cke),       // Clock Enable
        .Cs_n       (sdram_cmd[3]),    // Chip Select
        .Ras_n      (sdram_cmd[2]),    // Row Address Strobe
        .Cas_n      (sdram_cmd[1]),    // Column Address Strobe
        .We_n       (sdram_cmd[0]),    // Write Enable
        .Dqm        (2'b00),           // Data Mask
        .Debug      (1'b1)             // Debug Mode
    );
 
endmodule