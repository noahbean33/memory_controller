`timescale 1ns / 1ps
 
module tb_sdram_read;
 
  // --------------------------------------------------
  // Clock and Reset Declarations
  // --------------------------------------------------
  reg sys_clk    = 0;     // System clock
  reg sys_rst_n  = 0;     // Active-low reset
 
  // Clock Generation: 100MHz (10ns period)
  always #5 sys_clk = ~sys_clk;
 
  // Reset Pulse Generation
  initial begin
    sys_rst_n = 0;
    repeat(3) @(posedge sys_clk);
    sys_rst_n = 1;
  end
 
  // --------------------------------------------------
  // SDRAM Initialization Interface Wires
  // --------------------------------------------------
  wire [3:0]  init_cmd;
  wire [1:0]  init_bank;
  wire [11:0] init_addr;
  wire        init_done;
 
  // SDRAM Initialization Instance
  sdram_init sdram_init_inst (
    .sys_clk       (sys_clk),
    .sys_rst_n     (sys_rst_n),
    .init_cmd      (init_cmd),
    .init_ba       (init_bank),
    .init_addr     (init_addr),
    .init_done     (init_done)
  );
 
  // --------------------------------------------------
  // Inputs to SDRAM Read Controller (Modified)
  // --------------------------------------------------
  reg         rd_en;
  reg [24:0]  rd_addri;
  wire [15:0] rd_din;        // From SDRAM model
  reg [7:0]   rd_blength;
 
  // --------------------------------------------------
  // Outputs from SDRAM Read Controller (Modified)
  // --------------------------------------------------
  wire        rd_valid;
  wire        rd_end;
  wire [3:0]  rd_cmdo;
  wire [1:0]  rd_bao;
  wire [11:0] rd_addro;
  wire [15:0] rd_datao;
 
  // --------------------------------------------------
  // Instantiate Modified SDRAM Read Controller (UUT)
  // --------------------------------------------------
  sdram_read uut (
    .sys_clk     (sys_clk),
    .sys_rst_n   (sys_rst_n),
    .init_end    (init_done),
    .rd_en       (rd_en),
    .rd_addri    (rd_addri),
    .rd_din      (rd_din),
    .rd_blength  (rd_blength),
    .rd_valid    (rd_valid),
    .rd_end      (rd_end),
    .rd_cmdo     (rd_cmdo),
    .rd_bao      (rd_bao),
    .rd_addro    (rd_addro),
    .rd_datao    (rd_datao)
  );
 
  // --------------------------------------------------
  // MUX for SDRAM command interface (init or read mode)
  // --------------------------------------------------
  wire [3:0]  cmd;
  wire [1:0]  ba;
  wire [11:0] addr;
 
  assign cmd  = (init_done) ? rd_cmdo  : init_cmd;
  assign ba   = (init_done) ? rd_bao   : init_bank;
  assign addr = (init_done) ? rd_addro : init_addr;
 
  // --------------------------------------------------
  // SDRAM Model Instance
  // --------------------------------------------------
  sdram_model_plus sdram_model_plus_inst (
    .Dq     (rd_din),         // Data coming from model to controller
    .Addr   (addr),           // SDRAM address
    .Ba     (ba),             // SDRAM bank
    .Clk    (sys_clk),        // SDRAM clock
    .Cke    (1'b1),           // Clock enable
    .Cs_n   (cmd[3]),
    .Ras_n  (cmd[2]),
    .Cas_n  (cmd[1]),
    .We_n   (cmd[0]),
    .Dqm    (1'b0),           // No data masking
    .Debug  (1'b1)
  );
 
  // --------------------------------------------------
  // Stimulus Block for Read Operation
  // --------------------------------------------------
  initial begin
    // Initial Inputs
    rd_en      = 0;
    rd_addri   = 25'b00_000000000001_0_00_00000001; // Sample bank/row/col
    rd_blength = 8'd8;
 
    // Wait for SDRAM Initialization to Complete
    @(posedge init_done);
    @(posedge sys_clk);
 
    // Start Read Operation
    rd_en = 1;
 
    // Wait for First Data Valid Signal
    @(posedge rd_valid);
 
    // Wait for entire burst read to finish
    repeat(8) @(posedge sys_clk);
 
    // Deassert Read Enable
    rd_en = 0;
 
    // Wait for Read Completion
    wait(rd_end);
 
    @(posedge sys_clk);
    $finish;
  end
 
endmodule