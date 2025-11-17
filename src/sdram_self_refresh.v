module sdram_self_refresh(
    input wire sys_clk,       // System clock
    input wire sys_rst_n,     // Active-low reset
    input wire sdram_init,
    input wire self_ref_en,   // Self-refresh enable signal
    output reg sdram_cke,     // SDRAM clock enable
    output reg [3:0] sdram_cmd, // SDRAM command bus
    output reg [1:0] sdram_ba,
    output reg [11:0] sdram_addr,
    output reg self_ref_done  // Indicates self-refresh exit complete
);
 
    // SDRAM Command Definitions
    parameter PRECHARGE  = 4'b0010; // Precharge Command
    parameter AUTO_REF   = 4'b0001; // Auto-Refresh Command
    parameter NOP        = 4'b0111; // No Operation (NOP)
 
    // Self-Refresh State Machine (FSM) States (Corrected)
    parameter SR_IDLE         = 4'b0000; // Idle state
    parameter SR_PRECHARGE    = 4'b0001; // Precharge all banks before Self-Refresh
    parameter SR_ENTRY        = 4'b0010; // Enter Self-Refresh mode
    parameter SR_WAIT         = 4'b0011; // Stay in Self-Refresh mode
    parameter SR_EXIT         = 4'b0100; // Exit Self-Refresh mode
    parameter SR_POST_REFRESH = 4'b0101; // Perform 4096 Auto-Refresh cycles
    parameter SR_WAIT_TRP     = 4'b0110; // Wait for tRP timing
    parameter SR_WAIT_TRFC1   = 4'b0111; // First refresh wait state
    parameter SR_WAIT_TRFC2   = 4'b1000; // Second refresh wait state (still within 4-bit range)
 
     
 
    reg [3:0]  sr_state;  // Self-Refresh state variable
    reg [12:0] ref_count; // Counter for 4096 Auto-Refresh cycles
    reg [3:0]  tXSR_count; // Counter for tSRE timing requirement
    reg [2:0]  trp_count;
    reg [3:0]  trfc_count;
 
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            sr_state   <= SR_IDLE;
            sdram_cke  <= 1'b1;  // Default: CKE enabled
            sdram_cmd  <= NOP;
            sdram_ba   <= 2'b11;
            sdram_addr <= 12'hfff;
            self_ref_done <= 1'b0;
            ref_count <= 13'd0;
            tXSR_count <= 4'd0;
            trp_count  <= 0;
            trfc_count <= 0;
        end 
        else begin
            case (sr_state)
 
                // **IDLE: Wait for Self-Refresh Enable**
                SR_IDLE: begin
                    self_ref_done <= 1'b0;
                    ref_count <= 13'd0;
                    tXSR_count <= 4'd0;
                    trp_count  <= 0;
                    trfc_count <= 0;
                    
                    if (self_ref_en && sdram_init) begin
                        sr_state <= SR_PRECHARGE; // Ensure all banks are idle before self-refresh
                    end
                end
 
                // **PRECHARGE: Close all active rows to ensure banks are idle**
                SR_PRECHARGE: begin
                    sdram_cmd <= PRECHARGE; // Issue Precharge Command
                    sr_state <= SR_WAIT_TRP;
                end
                
                SR_WAIT_TRP: begin 
                    if (trp_count < 2 ) begin
                        sdram_cmd <= NOP; // Issue Precharge Command
                        trp_count <= trp_count + 1;
                        sr_state <= SR_WAIT_TRP;
                    end else begin
                       trp_count <= 0;
                       sr_state  <= SR_ENTRY;  
                       end
                end
                // **ENTRY: Send Auto-Refresh Command and Set CKE Low**
                SR_ENTRY: begin
                    sdram_cke <= 1'b0;  // Disable clock
                    sdram_cmd <= AUTO_REF; // Send Auto-Refresh command
                    sr_state <= SR_WAIT_TRFC1;
                end
                
                SR_WAIT_TRFC1: begin 
                     sdram_cmd <= NOP;
                    if (trfc_count < 8 ) begin
                       trfc_count <= trfc_count + 1;
                       sr_state   <= SR_WAIT_TRFC1;
                   end else  begin
                       trfc_count <= 0;
                       sr_state  <= SR_WAIT;  
                       end
                end
 
                // **WAIT: Remain in Self-Refresh Mode**
                SR_WAIT: begin
                    sdram_cke <= 1'b0; // Keep CKE low
                    sdram_cmd <= NOP;
                    if (!self_ref_en) begin
                        sr_state <= SR_POST_REFRESH; // Exit when requested
                    end
                end
 
 
                // **POST-REFRESH: Perform 4096 Auto-Refresh Commands**
                SR_POST_REFRESH: begin
                    sdram_cke <= 1'b1;
                    if (ref_count < 13'd4096) begin
                        sdram_cmd <= AUTO_REF; // Perform Auto-Refresh cycle
                        ref_count <= ref_count + 1;
                        sr_state <= SR_WAIT_TRFC2;
                    end else begin
                        ref_count <= 13'd0;
                        sr_state <= SR_EXIT; 
                    end
                end
                
                SR_WAIT_TRFC2: begin 
                    sdram_cmd <= NOP;
                    if (trfc_count < 8 ) begin
                       trfc_count <= trfc_count + 1;
                       sr_state <= SR_WAIT_TRFC2;
                  end  else
                       begin
                       trfc_count <= 0;
                       sr_state  <= SR_POST_REFRESH;  
                       end
                end
                
                
               SR_EXIT: begin
                    sdram_cke <= 1'b1; // Enable CKE
                    sdram_cmd <= NOP;
                    if (tXSR_count < 4'd8) begin
                        tXSR_count <= tXSR_count + 1;
                        sr_state <= SR_EXIT; 
                   end else begin
                        tXSR_count <= 4'd0;
                        sr_state <= SR_IDLE;
                        self_ref_done <= 1'b1; // Indicate self-refresh is complete
                    end
                end
 
                default: sr_state <= SR_IDLE;
 
            endcase
        end
    end
endmodule