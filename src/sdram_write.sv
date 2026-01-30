`timescale 1ns / 1ps
 
module sdram_write (
    input  logic        sys_clk,       // System clock (100MHz)
    input  logic        sys_rst_n,     // Reset signal (active low)
    input  logic        init_done,     // Initialization completion signal
    input  logic        wr_en,         // Write enable signal
    input  logic [24:0] wr_addri,      // 24:23 - bank, 22:11 - row, 10 - auto precharge, 9:8 - unused, 7:0 - column
    input  logic [15:0] wr_din,        // Data to write to SDRAM
    input  logic [7:0]  wr_blength,    // Burst length
    input  logic        wr_dqm_in,     // Data mask input
    input  logic        wr_wait,       /// wait for auto ref

    output logic        apply_data,    // Indicates when controller is ready to accept new data
    output logic        wr_end,        // Write burst completion flag
    output logic [3:0]  wr_cmd,        // SDRAM command output
    output logic [1:0]  wr_ba,         // Bank address output
    output logic [11:0] wr_addro,      // Address bus output
    output logic        wr_dqm_out,   // Data mask output
    output logic [15:0] data_written,  // Data to be driven to SDRAM
    output logic        trans_err
);
 
    // ------------------------------------------------
    // Parameter Definitions
    // ------------------------------------------------
    parameter ACTIVE_DELAY        = 10'd2;
    parameter PRECHARGE_DELAY     = 10'd2;
    parameter WRITE_RECOV_DELAY   = 10'd2;
    parameter AFTER_WR_AUTO_PRE   = 10'd4;
 
    // State Encoding
    parameter IDLE                = 4'b0000,
              ACTIVE              = 4'b0001,
              WAIT_ACTIVE         = 4'b0011,
              START_WRITE         = 4'b0010,
              WRITING             = 4'b0100,
              PRECHARGE           = 4'b0101,
              WAIT_PRECHARGE      = 4'b0111,
              COMPLETE            = 4'b0110,
              WAIT_FOR_WRITE_REC_DEL = 4'b1000,
              WAIT_TWR            = 4'b1001,
              WAIT_FOR_AUTO_REF   = 4'b1010;
 
    // SDRAM Commands
    parameter CMD_NOP             = 4'b0111,
              CMD_ACTIVE          = 4'b0011,
              CMD_WRITE           = 4'b0100,
              CMD_BURST_STOP      = 4'b0110,
              CMD_PRECHARGE       = 4'b0010;
 
    // ------------------------------------------------
    // Internal Signals
    // ------------------------------------------------
    logic [3:0] current_state;
    logic [7:0] clock_counter;
    logic       reset_clock_counter;

    logic wait_active_done;
    logic write_cycle_done;
    logic wait_precharge_done;
    logic wait_write_rec_done;
 
    // Write completion condition
    assign wr_end = (current_state == COMPLETE);
    
        // ------------------------------------------------
    // Burst Counter Logic
    // ------------------------------------------------
    logic [7:0] burst_counter;
    
 
    // ------------------------------------------------
    // Clock Counter Logic
    // ------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            clock_counter <= 8'd0;
        else if (reset_clock_counter)
            clock_counter <= 8'd0;
        else
            clock_counter <= clock_counter + 1'b1;
    end
 
    // ------------------------------------------------
    // Clock Counter Reset Logic
    // ------------------------------------------------
    always_comb begin
        case (current_state)
            IDLE,
            START_WRITE,
            PRECHARGE,
            COMPLETE:
                reset_clock_counter = 1'b1;
 
            WAIT_ACTIVE:
                reset_clock_counter = (wait_active_done) ? 1'b1 : 1'b0;
 
            WRITING:
                reset_clock_counter = 1'b1;
 
            WAIT_FOR_WRITE_REC_DEL:
                reset_clock_counter = (wait_write_rec_done) ? 1'b1 : 1'b0;
 
            WAIT_PRECHARGE:
                reset_clock_counter = (wait_precharge_done) ? 1'b1 : 1'b0;
 
            WAIT_TWR:
                reset_clock_counter = (clock_counter == 2) ? 1'b1 : 1'b0;
 
            default:
                reset_clock_counter = 1'b1;
        endcase
    end
 
    // ------------------------------------------------
    // Timing Conditions
    // ------------------------------------------------
    assign wait_active_done     = (current_state == WAIT_ACTIVE)          && (clock_counter == ACTIVE_DELAY - 1);
    assign write_cycle_done     = (current_state == WRITING)              && (clock_counter == wr_blength - 1);
    assign wait_precharge_done  = (current_state == WAIT_PRECHARGE)       && (clock_counter == PRECHARGE_DELAY - 1);
    //assign wait_write_rec_done  = (current_state == WAIT_FOR_WRITE_REC_DEL) && (clock_counter == AFTER_WR_AUTO_PRE - 1);
 
    // ------------------------------------------------
    // State Machine Logic
    // ------------------------------------------------
    logic wr_wait_reg;
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            current_state <= IDLE;
            burst_counter <= 0;
            end
        else begin
            case (current_state)
                IDLE: begin
                    wr_wait_reg   <= 0;
                    burst_counter <= 0;
                    if (wr_en && init_done)
                        current_state <= ACTIVE;
                end
 
                ACTIVE:begin
                    wr_wait_reg <= 0;
                    current_state <= WAIT_ACTIVE;
                end
 
                WAIT_ACTIVE: begin
                    if (wait_active_done)
                        current_state <= START_WRITE;
                end
 
                START_WRITE: begin
                    current_state <= WRITING;
                    burst_counter <= 0;
                    end
 
                WRITING: begin
                    if(wr_wait == 1'b1) begin
                           current_state <= WAIT_TWR;
                           wr_wait_reg   <= wr_wait;
                    end
                    else if (burst_counter == wr_blength - 1) begin
                            if (wr_addri[10])  // Auto precharge enabled
                                current_state <= WAIT_FOR_WRITE_REC_DEL;
                            else
                                current_state <= WAIT_TWR;
                    end
                    else begin
                            current_state <= WRITING;
                            burst_counter <= burst_counter + 1;
                    end
                end
 
                WAIT_FOR_WRITE_REC_DEL: begin
                    if (wait_write_rec_done)
                        current_state <= COMPLETE;
                end
 
                WAIT_TWR: begin
                    if (clock_counter == 1)
                        current_state <= PRECHARGE;
                end
 
                PRECHARGE:
                    current_state <= WAIT_PRECHARGE;
 
                WAIT_PRECHARGE: begin
                    if (wait_precharge_done) begin
                            current_state <= COMPLETE;
                    end
                 end
  
  
                COMPLETE:
                    current_state <= IDLE;
 
                default:
                    current_state <= IDLE;
            endcase
        end
    end
 
    // ------------------------------------------------
    // SDRAM Command Control Logic
    // ------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            wr_cmd      <= CMD_NOP;
            wr_ba       <= 2'b11;
            wr_addro    <= 12'hFFF;
            apply_data  <= 1'b0;
        end else begin
            case (current_state)
                IDLE,
                WAIT_ACTIVE,
                WAIT_PRECHARGE:
                    begin
                        wr_cmd     <= CMD_NOP;
                        wr_ba      <= 2'b11;
                        wr_addro   <= 12'hFFF;
                        apply_data <= 1'b0;
                    end
 
                ACTIVE:
                    begin
                        wr_cmd     <= CMD_ACTIVE;
                        wr_ba      <= wr_addri[24:23];         // Bank address
                        wr_addro   <= wr_addri[22:11];         // Row address
                        apply_data <= 1'b0;
                    end
 
                START_WRITE:
                    begin
                        wr_cmd     <= CMD_WRITE;
                        wr_ba      <= wr_addri[24:23];
                        wr_addro   <= {4'b0000, wr_addri[7:0]}; // Column address
                        apply_data <= 1'b1;
                    end
 
                WRITING:
                    begin
                        if(wr_wait == 1'b1) begin
                            wr_cmd     <= CMD_BURST_STOP;
                            wr_ba      <= wr_addri[24:23];
                            wr_addro   <= wr_addri[11:0];
                            apply_data <= 1'b0;
                    end
                    else if (burst_counter == wr_blength - 1) begin
                            wr_cmd     <= CMD_BURST_STOP;
                            apply_data <= 1'b0;
                    end
                    else begin
                            wr_cmd     <= CMD_NOP;
                            wr_ba      <= wr_addri[24:23];
                            wr_addro   <= wr_addri[11:0]; // Don't care
                        end
                    end
 
                WAIT_FOR_WRITE_REC_DEL,
                WAIT_TWR:
                    begin
                        wr_cmd     <= CMD_NOP;
                        wr_ba      <= wr_addri[24:23];
                        wr_addro   <= wr_addri[11:0];
                        apply_data <= 1'b0;
                    end
 
                PRECHARGE:
                    begin
                        wr_cmd     <= CMD_PRECHARGE;
                        wr_ba      <= wr_addri[24:23];
                        wr_addro   <= wr_addri[11:0];
                        apply_data <= 1'b0;
                    end
 
                COMPLETE:
                    begin
                        wr_cmd     <= CMD_NOP;
                        wr_ba      <= wr_addri[24:23];
                        wr_addro   <= wr_addri[11:0];
                        apply_data <= 1'b0;
                    end
 
                default:
                    begin
                        wr_cmd     <= CMD_NOP;
                        wr_ba      <= wr_addri[24:23];
                        wr_addro   <= wr_addri[11:0];
                        apply_data <= 1'b0;
                    end
            endcase
        end
    end
 
    // ------------------------------------------------
    // Data Mask Output Control
    // ------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            wr_dqm_out <= 1'b0;
        else
            wr_dqm_out <= wr_dqm_in;
    end
 
    // ------------------------------------------------
    // Data Output Assignment (Tri-state behavior)
    // ------------------------------------------------
    assign data_written = (wr_dqm_in == 1'b0) ? wr_din : 16'hZZZZ;
    assign trans_err    = ((current_state == COMPLETE) && (burst_counter != wr_blength - 1)) ? 1'b1 : 1'b0;
 
endmodule