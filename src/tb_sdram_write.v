`timescale 1ns / 1ps
 
module tb_sdram_write;
 
  // --------------------------------------------------
  // Clock and Reset Generation
  // --------------------------------------------------
  reg sys_clk   = 0;
  reg sys_rst_n = 0;
  reg wr_wait = 0;
 
  // Clock: 100 MHz (Period = 10ns)
  always #5 sys_clk = ~sys_clk;
 
  // Reset pulse for 3 clock cycles
  initial begin
    sys_rst_n = 0;
    repeat(3) @(posedge sys_clk);
    sys_rst_n = 1;
  end
 
  // --------------------------------------------------
  // SDRAM Initialization Module Signals
  // --------------------------------------------------
  wire [3:0]  init_cmd;
  wire [1:0]  init_ba;
  wire [11:0] init_addr;
  wire        init_done;
 
  // SDRAM Initialization Module Instance
  sdram_init sdram_init_inst (
    .sys_clk     (sys_clk),        // System clock
    .sys_rst_n   (sys_rst_n),       // Active-low reset
    .init_cmd    (init_cmd),     // Command output
    .init_ba     (init_ba),      // Bank address output
    .init_addr   (init_addr),    // Address bus output
    .init_done   (init_done)     // Initialization done signal
  );
 
  // --------------------------------------------------
  // DUT Inputs (sdram_write module)
  // --------------------------------------------------
  reg         wr_en;
  reg [24:0]  wr_addri;
  reg [15:0]  wr_din;
  reg [9:0]   wr_blength;
  reg         wr_dqm_in;
 
  // --------------------------------------------------
  // DUT Outputs
  // --------------------------------------------------
  wire        apply_data;
  wire        wr_end;
  wire [3:0]  wr_cmd;
  wire [1:0]  wr_ba;
  wire [11:0] wr_addro;
  wire        wr_dqm_out;
  wire [15:0] data_written;
  wire        trans_err;
 
  // --------------------------------------------------
  // DUT Instance: Modified sdram_write Module
  // --------------------------------------------------
  sdram_write uut (
    .sys_clk     (sys_clk),
    .sys_rst_n   (sys_rst_n),
    .init_done   (init_done),
    .wr_en       (wr_en),
    .wr_addri    (wr_addri),
    .wr_din      (wr_din),
    .wr_blength  (wr_blength),
    .wr_dqm_in   (wr_dqm_in),
    .wr_wait(wr_wait),
    .apply_data  (apply_data),
    .wr_end      (wr_end),
    .wr_cmd      (wr_cmd),
    .wr_ba       (wr_ba),
    .wr_addro    (wr_addro),
    .wr_dqm_out  (wr_dqm_out),
    .data_written(data_written),
    .trans_err(trans_err)
  );
 
  // --------------------------------------------------
  // Address/Command Multiplexer (init or write control)
  // --------------------------------------------------
  wire [3:0]  cmd;
  wire [1:0]  ba;
  wire [11:0] addr;
 
  assign cmd  = (init_done) ? wr_cmd   : init_cmd;
  assign ba   = (init_done) ? wr_ba    : init_ba;
  assign addr = (init_done) ? wr_addro : init_addr;
 
  // --------------------------------------------------
  // SDRAM Model Instance
  // --------------------------------------------------
  sdram_model_plus sdram_model_plus_inst (
    .Dq     (data_written),
    .Addr   (addr),
    .Ba     (ba),
    .Clk    (sys_clk),
    .Cke    (1'b1),
    .Cs_n   (cmd[3]),
    .Ras_n  (cmd[2]),
    .Cas_n  (cmd[1]),
    .We_n   (cmd[0]),
    .Dqm    (wr_dqm_out),
    .Debug  (1'b1)
  );
 
  // --------------------------------------------------
  // Write Operation Stimulus
  // --------------------------------------------------
  initial begin
    // Initial values
    wr_en      = 0;
    wr_addri   = 0;
    wr_din     = 0;
    wr_blength = 0;
    wr_dqm_in  = 0;
 
    // Wait for SDRAM initialization to complete
    @(posedge init_done);
    
    ///////without wait
    @(posedge sys_clk);
 
    // Begin Write Operation
    wr_en       = 1;
    wr_addri    = 25'b11_000000000001_0_00_00000001; // Bank=3, Row=1, Col=1, Auto-precharge=0
    wr_blength  = 10'd8;
    wr_dqm_in   = 0;
    wr_wait = 0;
 
    // Send data only when apply_data signal is high
    @(posedge sys_clk);
    wait(apply_data);
    wr_din = 16'h01;
    @(posedge sys_clk);
    wait(apply_data);
    // Send remaining 7 data words
    repeat(8) begin
      wr_din = wr_din + 1;
      @(posedge sys_clk);
    end
    wr_en = 0;
    // Deassert write enable after last data 
    @(posedge wr_end);
    @(posedge sys_clk);
    
    ///////////with wait
    
    @(posedge sys_clk);
    // Begin Write Operation
    wr_en       = 1;
    wr_addri    = 25'b11_000000000001_0_00_00000001; // Bank=3, Row=1, Col=1, Auto-precharge=0
    wr_blength  = 10'd8;
    wr_dqm_in   = 0;
 
    // Send data only when apply_data signal is high
    @(posedge sys_clk);
    wait(apply_data);
    wr_din = 16'h01;
    @(posedge sys_clk);
     wait(apply_data);
    // Send remaining 7 data words
    repeat(4) begin
      wr_din = wr_din + 1;
      @(posedge sys_clk);
    end
    wr_wait = 1;
    repeat(4) @(posedge sys_clk);
    wr_en = 0;
    // Deassert write enable after last data 
    @(posedge wr_end);
    @(posedge sys_clk);
 
 
    // End simulation
    $finish;
  end
 
endmodule