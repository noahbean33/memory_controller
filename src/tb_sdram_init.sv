`timescale 1ns / 1ps
 
module tb_sdram_init;
 
  // --------------------------------------------------
  // Clock and Reset Declarations
  // --------------------------------------------------
  logic             s_clk    = 0;     // System clock
  logic             s_rstn   = 0;     // Active-low reset
 
  // --------------------------------------------------
  // SDRAM Initialization Controller Outputs
  // --------------------------------------------------
  logic [3:0]       init_cmd;        // SDRAM command signals (CS, RAS, CAS, WE)
  logic [1:0]       init_ba;         // Bank address
  logic [11:0]      init_addr;       // Address bus
  logic             init_done;       // Initialization done signal
 
  // --------------------------------------------------
  // Clock Generation: 100 MHz clock with 10ns period
  // --------------------------------------------------
  always #5 s_clk = ~s_clk;
 
  // --------------------------------------------------
  // Reset Generation: Assert for 3 clock cycles
  // --------------------------------------------------
  initial begin
    s_rstn = 1'b0;
    repeat(3) @(posedge s_clk);
    s_rstn = 1'b1;
  end
 
  // --------------------------------------------------
  // Simulation End Condition
  // --------------------------------------------------
  initial begin
    @(posedge init_done);   // Wait until initialization completes
    @(posedge s_clk);       // Wait one more cycle
    $finish;                // End simulation
  end
 
  // --------------------------------------------------
  // Instantiate DUT: SDRAM Initialization Controller
  // --------------------------------------------------
  sdram_init sdram_init_inst (
    .sys_clk     (s_clk),        // System clock
    .sys_rst_n   (s_rstn),       // Active-low reset
    .init_cmd    (init_cmd),     // Command output
    .init_ba     (init_ba),      // Bank address output
    .init_addr   (init_addr),    // Address bus output
    .init_done   (init_done)     // Initialization done signal
  );
 
  // --------------------------------------------------
  // Optional: Instantiate SDRAM Model for Command Monitoring
  // --------------------------------------------------
  sdram_model_plus sdram_model_plus_inst (
    .Dq     (/* unused for init */),    // Data bus not used during init
    .Addr   (init_addr),               // SDRAM address
    .Ba     (init_ba),                 // SDRAM bank address
    .Clk    (s_clk),                   // Clock
    .Cke    (1'b1),                    // Clock enable (always ON)
    .Cs_n   (init_cmd[3]),             // Chip select
    .Ras_n  (init_cmd[2]),             // Row address strobe
    .Cas_n  (init_cmd[1]),             // Column address strobe
    .We_n   (init_cmd[0]),             // Write enable
    .Dqm    (2'b00),                   // Data mask (disabled)
    .Debug  (1'b1)                     // Debug mode ON
  );
 
endmodule