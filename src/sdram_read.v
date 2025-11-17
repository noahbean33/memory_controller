module sdram_read(
    input  wire         sys_clk,        // System clock
    input  wire         sys_rst_n,      // Active-low system reset
    input  wire         init_end,       // SDRAM initialization completion signal
    input  wire         rd_en,          // Read enable signal
    input  wire [24:0]  rd_addri,       // Read address: [24:23] - Bank, [22:11] - Row, [10] - Auto-precharge, [9:8] - Reserved, [7:0] - Column
    input  wire [15:0]  rd_din,         // Data input from SDRAM
    input  wire [7:0]   rd_blength,     // SDRAM read burst length
    
    output reg          rd_valid,       // Read valid signal (data ready)
    output wire         rd_end,         // Read operation end signal
    output reg  [3:0]   rd_cmdo,        // Command to SDRAM
    output reg  [1:0]   rd_bao,         // Bank address to SDRAM
    output reg  [11:0]  rd_addro,       // Address to SDRAM
    output wire [15:0]  rd_datao        // Output read data
);
 
// --------------------------------------------------
// SDRAM Timing Parameters
// --------------------------------------------------
parameter TRCD_COUNT       = 10'd2;    // RAS to CAS delay
parameter TCAS_COUNT       = 10'd3;    // CAS latency
parameter TRP_COUNT        = 10'd2;    // Precharge time
parameter AFTER_STOP_COUNT = 10'd2;    // Delay after burst termination
 
// --------------------------------------------------
// FSM States
// --------------------------------------------------
parameter IDLE      = 4'b0000,
          ACTIVE    = 4'b0001,
          WAIT_TRCD = 4'b0011,
          READ      = 4'b0010,
          WAIT_CAS  = 4'b0100,
          READ_DATA = 4'b0101,
          PRECHARGE = 4'b0111,
          WAIT_TRP  = 4'b0110,
          END       = 4'b1000;
 
// --------------------------------------------------
// SDRAM Command Codes
// --------------------------------------------------
parameter CMD_NOP       = 4'b0111,
          CMD_ACTIVE    = 4'b0011,
          CMD_READ      = 4'b0101,
          CMD_BURST_TER = 4'b0110,
          CMD_PRECHARGE = 4'b0010;
 
// --------------------------------------------------
// Internal Registers
// --------------------------------------------------
reg [3:0]  read_state;
reg [9:0]  cnt_clk;
reg        cnt_clk_rst;
reg [15:0] rd_data_reg;
 
// --------------------------------------------------
// Data Latch from SDRAM
// --------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        rd_data_reg <= 16'd0;
    else
        rd_data_reg <= rd_din;
end
 
// --------------------------------------------------
// Read End Indicator
// --------------------------------------------------
assign rd_end = (read_state == END);
 
// --------------------------------------------------
// Timing Flags
// --------------------------------------------------
wire trcd_end   = (read_state == WAIT_TRCD) && (cnt_clk == TRCD_COUNT);
wire trp_end    = (read_state == WAIT_TRP)  && (cnt_clk == TRP_COUNT);
wire tcas_end   = (read_state == WAIT_CAS)  && (cnt_clk == TCAS_COUNT - 1);
wire tread_end  = (read_state == READ_DATA) && (cnt_clk == rd_blength - 4);
 
// --------------------------------------------------
// Clock Counter for Timings
// --------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        cnt_clk <= 10'd0;
    else if (cnt_clk_rst)
        cnt_clk <= 10'd0;
    else
        cnt_clk <= cnt_clk + 1'b1;
end
 
// --------------------------------------------------
// Counter Reset Control Based on Read State
// --------------------------------------------------
always @(*) begin
    case (read_state)
        IDLE, READ, END : cnt_clk_rst = 1'b1;
        WAIT_TRCD       : cnt_clk_rst = trcd_end;
        WAIT_CAS        : cnt_clk_rst = tcas_end;
        READ_DATA       : cnt_clk_rst = tread_end;
        WAIT_TRP        : cnt_clk_rst = trp_end;
        default         : cnt_clk_rst = 1'b0;
    endcase
end
 
// --------------------------------------------------
// After Burst Terminate Tracking (2 Cycles)
// --------------------------------------------------
reg [1:0] after_stop;
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        after_stop <= 2'd0;
    else if (tread_end)
        after_stop <= 2'd0;
    else
        after_stop <= after_stop + 1'b1;
end
 
// --------------------------------------------------
// FSM for SDRAM Read Operation
// --------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        read_state <= IDLE;
    else begin
        case (read_state)
            IDLE: begin
                if (rd_en && init_end)
                    read_state <= ACTIVE;
            end
            ACTIVE:
                read_state <= WAIT_TRCD;
            WAIT_TRCD: begin
                if (trcd_end)
                    read_state <= READ;
            end
            READ:
                read_state <= WAIT_CAS;
            WAIT_CAS: begin
                if (tcas_end)
                    read_state <= READ_DATA;
            end
            READ_DATA: begin
                if (tread_end) begin
                    if (rd_addri[10])   // Auto-precharge enabled
                        read_state <= WAIT_TRP;
                    else
                        read_state <= PRECHARGE;
                end
            end
            PRECHARGE:
                read_state <= WAIT_TRP;
            WAIT_TRP: begin
                if (trp_end)
                    read_state <= END;
            end
            END:
                read_state <= IDLE;
            default:
                read_state <= IDLE;
        endcase
    end
end
 
// --------------------------------------------------
// SDRAM Command/Address/Bank Selection and rd_valid Control
// --------------------------------------------------
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        rd_cmdo   <= CMD_NOP;
        rd_bao    <= 2'b11;
        rd_addro  <= 12'hFFF;
        rd_valid  <= 1'b0;
    end else begin
        case (read_state)
            IDLE, WAIT_TRCD: begin
                rd_cmdo   <= CMD_NOP;
                rd_bao    <= 2'b11;
                rd_addro  <= 12'hFFF;
                rd_valid  <= 1'b0;
            end
            ACTIVE: begin
                rd_cmdo   <= CMD_ACTIVE;
                rd_bao    <= rd_addri[24:23];         // Bank address
                rd_addro  <= rd_addri[22:11];         // Row address
                rd_valid  <= 1'b0;
            end
            READ: begin
                rd_cmdo   <= CMD_READ;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= {4'b0000, rd_addri[7:0]};
                rd_valid  <= 1'b0;
            end
            WAIT_CAS: begin
                rd_cmdo   <= CMD_NOP;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= tcas_end ? 1'b1 : rd_valid;
            end
            READ_DATA: begin
                rd_cmdo   <= tread_end ? CMD_BURST_TER : CMD_NOP;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= 1'b1;
            end
            PRECHARGE: begin
                rd_cmdo   <= CMD_PRECHARGE;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= 1'b1;
            end
            WAIT_TRP: begin
                rd_cmdo   <= CMD_NOP;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= (after_stop == 2'd2) ? 1'b0 : 1'b1;
            end
            END: begin
                rd_cmdo   <= CMD_NOP;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= 1'b0;
            end
            default: begin
                rd_cmdo   <= CMD_NOP;
                rd_bao    <= rd_addri[24:23];
                rd_addro  <= rd_addri[11:0];
                rd_valid  <= 1'b0;
            end
        endcase
    end
end
 
// --------------------------------------------------
// Final Read Data Output
// --------------------------------------------------
assign rd_datao = rd_valid ? rd_data_reg : 16'b0;
 
endmodule