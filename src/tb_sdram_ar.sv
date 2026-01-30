module tb_sdram_ar;

    // Clock and reset
  logic sys_clk   = 0;
  logic sys_rst_n = 0;
 
  always #5 sys_clk = ~sys_clk; // 100MHz clock
 
  initial begin
    sys_rst_n = 1'b0;
    repeat(3) @(posedge sys_clk);
    sys_rst_n = 1'b1;
  end
 
  // --------------------------------------------------
  // SDRAM Initialization Module Signals
  // --------------------------------------------------
  logic [3:0]  init_cmd;
  logic [1:0]  init_ba;
  logic [11:0] init_addr;
  logic        init_done;
 
  // SDRAM Initialization Module Instance
  sdram_init sdram_init_inst (
    .sys_clk     (sys_clk),        // System clock
    .sys_rst_n   (sys_rst_n),       // Active-low reset
    .init_cmd    (init_cmd),     // Command output
    .init_ba     (init_ba),      // Bank address output
    .init_addr   (init_addr),    // Address bus output
    .init_done   (init_done)     // Initialization done signal
  );
 
 
 
   logic        ar_en;

    // DUT outputs
    logic        ar_end;
    logic [3:0]  ar_cmdo;
    logic [1:0]  ar_bao;
    logic [11:0] ar_addro;

    // Signals to SDRAM model
    logic [3:0]  sdram_cmd;
    logic [1:0]  sdram_ba;
    logic [11:0] sdram_addr;
 
    // DUT instantiation
    sdram_ar dut (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .init_done(init_done),
        .ar_en(ar_en),
        .ar_end(ar_end),
        .ar_cmdo(ar_cmdo),
        .ar_bao(ar_bao),
        .ar_addro(ar_addro)
    );
 
    // Initialization block
    initial begin
        sys_rst_n = 0;
        ar_en = 0;
        #30;
        sys_rst_n = 1;
 
        // Wait for few clocks, then set init_done
        repeat(3) @(posedge sys_clk);
 
        // Enable auto-refresh
        @(posedge sys_clk);
        ar_en = 1;
 
        // Wait for auto-refresh to complete
        wait(ar_end == 1);
          
        @(posedge sys_clk);
        $finish;
    end
 
    // Command/address routing: only valid after init_done
    assign sdram_cmd  = (init_done) ? ar_cmdo  : init_cmd; // 1111 = NOP
    assign sdram_ba   = (init_done) ? ar_bao   :init_ba;
    assign sdram_addr = (init_done) ? ar_addro : init_addr;
 
    // SDRAM model instantiation
    sdram_model_plus sdram_model_plus_inst (
        .Dq(),                       // Not connected for now
        .Addr(sdram_addr),
        .Ba(sdram_ba),
        .Clk(sys_clk),
        .Cke(1'b1),
        .Cs_n(sdram_cmd[3]),
        .Ras_n(sdram_cmd[2]),
        .Cas_n(sdram_cmd[1]),
        .We_n(sdram_cmd[0]),
        .Dqm(2'b00),
        .Debug(1'b1)
    );
 
endmodule