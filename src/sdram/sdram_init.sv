module sdram_init (
    input  logic        sys_clk,     // System Clock
    input  logic        sys_rst_n,   // Active-Low Reset
    output logic [3:0]  init_cmd,    // SDRAM Command
    output logic [1:0]  init_ba,     // Bank Address
    output logic [11:0] init_addr,   // Address Bus
    output logic        init_done    // Initialization Done Flag
);

    // ----------------------------------------------------
    // Power-On Delay Counter: Wait 150us (required by SDRAM)
    // ----------------------------------------------------
    parameter count_power_on = 14'd15000;  // 150us / 10ns = 15000 clock cycles
    logic [13:0] count_150us;
    logic        power_on_wait_done;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            count_150us <= 14'd0;
        else if (count_150us == count_power_on)
            count_150us <= 14'd0;
        else
            count_150us <= count_150us + 1'b1;
    end

    assign power_on_wait_done = (count_150us == count_power_on);

    // ----------------------------------------------------
    // FSM State Encoding
    // ----------------------------------------------------
    parameter WAIT_150U       = 3'd0,
              PRECHARGE       = 3'd1,
              WAIT_TRP        = 3'd2,
              AUTOREFRESH     = 3'd3,
              WAIT_TRFC       = 3'd4,
              LOAD_MODE       = 3'd5,
              WAIT_TMRD       = 3'd6,
              INIT_DONE       = 3'd7;

    logic [2:0] init_state;       // FSM State Register

    // ----------------------------------------------------
    // Clock Cycle Counter for TRP, TRFC, TMRD Waits
    // ----------------------------------------------------
    logic [2:0] count_clock;
    logic       rst_clock_count;

    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            count_clock <= 3'd0;
        else if (rst_clock_count)
            count_clock <= 3'd0;
        else if (count_clock != 3'd7)  // Avoid overflow
            count_clock <= count_clock + 1'b1;
    end

    // ----------------------------------------------------
    // Wait Completion Flags Based on SDRAM Timing Constraints
    // ----------------------------------------------------
    parameter TRP_COUNT   = 3'd2; // Precharge wait cycles
    parameter TRFC_COUNT  = 3'd7; // Auto-refresh wait cycles
    parameter TMRD_COUNT  = 3'd2; // Mode Register Set wait cycles

    logic trp_end   = (init_state == WAIT_TRP)  && (count_clock == TRP_COUNT);
    logic trfc_end  = (init_state == WAIT_TRFC) && (count_clock == TRFC_COUNT);
    logic tmrd_end  = (init_state == WAIT_TMRD) && (count_clock == TMRD_COUNT);

    // ----------------------------------------------------
    // Reset Counter Logic Based on State
    // ----------------------------------------------------
    always_comb begin
        rst_clock_count = 1'b1; // Default reset enabled
        case (init_state)
            WAIT_150U   : rst_clock_count = 1'b1;
            WAIT_TRP    : rst_clock_count = trp_end  ? 1'b1 : 1'b0;
            WAIT_TRFC   : rst_clock_count = trfc_end ? 1'b1 : 1'b0;
            WAIT_TMRD   : rst_clock_count = tmrd_end ? 1'b1 : 1'b0;
            default     : rst_clock_count = 1'b1;
        endcase
    end
 
    // ----------------------------------------------------
    // Auto-Refresh Counter: 8 Auto-Refresh Cycles Required
    // ----------------------------------------------------
    logic [2:0] cnt_auto_ref;
 
    // ----------------------------------------------------
    // Initialization FSM Implementation
    // ----------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            init_state     <= WAIT_150U;
            cnt_auto_ref   <= 3'd0;
        end else begin
            case (init_state)
                WAIT_150U: begin
                    cnt_auto_ref <= 3'd0;
                    if (power_on_wait_done)
                        init_state <= PRECHARGE;
                end
 
                PRECHARGE:
                    init_state <= WAIT_TRP;
 
                WAIT_TRP:
                    if (trp_end)
                        init_state <= AUTOREFRESH;
 
                AUTOREFRESH:
                    init_state <= WAIT_TRFC;
 
                WAIT_TRFC: begin
                    if (trfc_end) begin
                        if (cnt_auto_ref == 3'd7)  // After 8 refreshes (0 to 7)
                            init_state <= LOAD_MODE;
                        else begin
                            init_state   <= AUTOREFRESH;
                            cnt_auto_ref <= cnt_auto_ref + 1;
                        end
                    end
                end
 
                LOAD_MODE:
                    init_state <= WAIT_TMRD;
 
                WAIT_TMRD:
                    if (tmrd_end)
                        init_state <= INIT_DONE;
 
                INIT_DONE:
                    init_state <= INIT_DONE;
 
                default:
                    init_state <= WAIT_150U;
            endcase
        end
    end
 
    // Initialization Done Flag
    assign init_done = (init_state == INIT_DONE);
 
    // ----------------------------------------------------
    // SDRAM Command, Address, and Bank Address Control
    // ----------------------------------------------------
    localparam CMD_NOP         = 4'b0111;
    localparam CMD_PRECHARGE   = 4'b0010;
    localparam CMD_AUTOREFRESH = 4'b0001;
    localparam CMD_LOAD_MODE   = 4'b0000;
 
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            init_cmd  <= CMD_NOP;
            init_ba   <= 2'b11;
            init_addr <= 12'hFFF;
        end else begin
            case (init_state)
                WAIT_150U, WAIT_TRP, WAIT_TRFC, WAIT_TMRD, INIT_DONE: begin
                    init_cmd  <= CMD_NOP;
                    init_ba   <= 2'b11;
                    init_addr <= 12'hFFF;
                end
 
                PRECHARGE: begin
                    init_cmd  <= CMD_PRECHARGE;
                    init_ba   <= 2'b11;
                    init_addr <= 12'hFFF;  // A10=1 for all banks precharge
                end
 
                AUTOREFRESH: begin
                    init_cmd  <= CMD_AUTOREFRESH;
                    init_ba   <= 2'b11;
                    init_addr <= 12'hFFF;
                end
 
                LOAD_MODE: begin
                    init_cmd  <= CMD_LOAD_MODE;
                    init_ba   <= 2'b11;    // Typically bank 0 for mode register
                    init_addr <= 12'b00_0_00_011_0_111; // Mode register config: burst length, CAS latency etc.
                end
 
                default: begin
                    init_cmd  <= CMD_NOP;
                    init_ba   <= 2'b11;
                    init_addr <= 12'hFFF;
                end
            endcase
        end
    end
 
endmodule