 module sdram_ar (
    input  logic        sys_clk,       // System clock (100MHz)
    input  logic        sys_rst_n,     // Active-low reset
    input  logic        init_done,     // Initialization complete signal
    input  logic        ar_en,         // Auto-refresh enable

    output logic        ar_req,        // Auto-refresh request
    output logic        ar_end,        // Auto-refresh end signal
    output logic [3:0]  ar_cmdo,       // SDRAM command during auto-refresh
    output logic [1:0]  ar_bao,        // Bank address (fixed value)
    output logic [11:0] ar_addro       // SDRAM address (fixed value)
);

    // --------------------------------------------------
    // Timing Parameters
    // --------------------------------------------------
    parameter CNT_REF_MAX  = 11'd1540;  // Refresh interval (~15.5us)
    parameter TRP_COUNT    = 3'd2;      // Precharge wait cycles
    parameter TRFC_COUNT   = 3'd7;      // Auto-refresh wait cycles

    // --------------------------------------------------
    // SDRAM Command Encodings
    // --------------------------------------------------
    parameter CMD_PRECHARGE    = 4'b0010;
    parameter CMD_AUTOREFRESH  = 4'b0001;
    parameter CMD_NOP          = 4'b0111;

    // --------------------------------------------------
    // FSM State Encodings
    // --------------------------------------------------
    parameter IDLE         = 3'b000;
    parameter PRECHARGE    = 3'b001;
    parameter WAIT_TRP     = 3'b011;
    parameter AUTOREFRESH  = 3'b010;
    parameter WAIT_TRFC    = 3'b100;
    parameter END          = 3'b101;

    // --------------------------------------------------
    // Internal Registers and Wires
    // --------------------------------------------------
    logic [10:0] cnt_aref;           // Refresh interval counter
    logic [2:0]  current_state;      // FSM current state
    logic [2:0]  cnt_clk;            // Wait cycle counter
    logic        cnt_clk_rst;       // Counter reset flag
    logic [1:0]  refresh_count;     // Number of refresh cycles

    logic trp_done;                 // Precharge wait complete flag
    logic trfc_done;                // Auto-refresh wait complete flag
    logic ack;                      // Acknowledge signal for refresh start

    // --------------------------------------------------
    // Auto-refresh acknowledgment and end signal
    // --------------------------------------------------
    assign ack      = (current_state == PRECHARGE);
    assign ar_end   = (current_state == END);

 
    // --------------------------------------------------
    // Refresh Interval Counter
    // --------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cnt_aref <= 11'd0;
        else if (cnt_aref >= CNT_REF_MAX)
            cnt_aref <= 11'd0;
        else if (init_done)
            cnt_aref <= cnt_aref + 1'b1;
    end
 
    // --------------------------------------------------
    // Generate Auto-Refresh Request
    // --------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            ar_req <= 1'b0;
        else if (cnt_aref == (CNT_REF_MAX - 1))
            ar_req <= 1'b1;
        else if (ack)
            ar_req <= 1'b0;
    end
 
    // --------------------------------------------------
    // Wait Cycle Counter
    // --------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            cnt_clk <= 3'd0;
        else if (cnt_clk_rst)
            cnt_clk <= 3'd0;
        else
            cnt_clk <= cnt_clk + 1'b1;
    end
 
    // --------------------------------------------------
    // Wait Completion Flags
    // --------------------------------------------------
    assign trp_done  = (current_state == WAIT_TRP  && cnt_clk == TRP_COUNT);
    assign trfc_done = (current_state == WAIT_TRFC && cnt_clk == TRFC_COUNT);
 
    // --------------------------------------------------
    // FSM: Auto-Refresh Operation Control
    // --------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            current_state <= IDLE;
        else begin
            case (current_state)
                IDLE: begin
                    if (ar_en && init_done)
                        current_state <= PRECHARGE;
                end
 
                PRECHARGE: begin
                    current_state <= WAIT_TRP;
                end
 
                WAIT_TRP: begin
                    if (trp_done)
                        current_state <= AUTOREFRESH;
                end
 
                AUTOREFRESH: begin
                    current_state <= WAIT_TRFC;
                end
 
                WAIT_TRFC: begin
                    if (trfc_done)
                        current_state <= END;
                    else
                        current_state <= WAIT_TRFC;
                end
 
                END: begin
                    current_state <= IDLE;
                end
 
                default: current_state <= IDLE;
            endcase
        end
    end
 
    // --------------------------------------------------
    // Counter Reset Logic Based on FSM State
    // --------------------------------------------------
    always_comb begin
        case (current_state)
            IDLE,
            END:        cnt_clk_rst = 1'b1;
            WAIT_TRP:   cnt_clk_rst = trp_done;
            WAIT_TRFC:  cnt_clk_rst = trfc_done;
            default:    cnt_clk_rst = 1'b0;
        endcase
    end
 
    // --------------------------------------------------
    // SDRAM Command / Address / Bank Selection
    // --------------------------------------------------
    always_ff @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            ar_cmdo  <= CMD_NOP;
            ar_bao   <= 2'b11;
            ar_addro <= 12'hFFF;
            ar_end   <= 1'b0;
        end else begin
            case (current_state)
                IDLE,
                WAIT_TRP,
                WAIT_TRFC: begin
                    ar_cmdo  <= CMD_NOP;
                    ar_bao   <= 2'b11;
                    ar_addro <= 12'hFFF;
                    ar_end   <= 1'b0;
                end
 
                PRECHARGE: begin
                    ar_cmdo  <= CMD_PRECHARGE;
                    ar_bao   <= 2'b11;
                    ar_addro <= 12'hFFF;
                    ar_end   <= 1'b0;
                end
 
                AUTOREFRESH: begin
                    ar_cmdo  <= CMD_AUTOREFRESH;
                    ar_bao   <= 2'b11;
                    ar_addro <= 12'hFFF;
                    ar_end   <= 1'b0;
                end
 
                END: begin
                    ar_cmdo  <= CMD_NOP;
                    ar_bao   <= 2'b11;
                    ar_addro <= 12'hFFF;
                    ar_end   <= 1'b1;
                end
 
                default: begin
                    ar_cmdo  <= CMD_NOP;
                    ar_bao   <= 2'b11;
                    ar_addro <= 12'hFFF;
                end
            endcase
        end
    end
 
endmodule