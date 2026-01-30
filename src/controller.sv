`timescale 1ns / 1ps
 
module controller(
    input  logic        sys_clk,      // System clock (100MHz)
    input  logic        sys_rst_n,    // Reset signal (active low)
    input  logic        init_done,
    input  logic [11:0] init_addro,
    input  logic [1:0]  init_bao,
    input  logic [3:0]  init_cmdo,
    
 
    input  logic        wr_req,
    input  logic        wr_end,
    output logic        wr_en,
    output logic        wr_wait,
    input  logic [11:0] wr_addro,
    input  logic [1:0]  wr_bao,
    input  logic [3:0]  wr_cmdo,
 
    input  logic        ar_req,
    input  logic        ar_end,
    output logic        ar_en,
    input  logic [11:0] ar_addro,
    input  logic [1:0]  ar_bao,
    input  logic [3:0]  ar_cmdo,
 
    output logic [11:0] addro,
    output logic [1:0]  bao,
    output logic [3:0]  cmdo,
    output logic        busy
);
 
assign busy = !init_done || wr_en || ar_en;  // Controller is busy if initialization is not done or write/read is active
 
// Command Encoding
parameter logic [3:0] CMD_NOP         = 4'b0111;
 
// FSM States
parameter IDLE            = 3'd0;
parameter ACCEPT_OP       = 3'd1;
parameter ACCEPT_WR       = 3'd2;
parameter SERVE_AR        = 3'd3;
parameter WR_ABRUPT_END   = 3'd4;
parameter WR_DONE         = 3'd5;
 
logic [2:0] contr_state;
 
//=============================
// Next State Decoder
//=============================
always_ff @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        contr_state <= IDLE;
    end else begin
        case (contr_state)
            IDLE: begin
                if (init_done)
                    contr_state <= ACCEPT_OP;
                else
                    contr_state <= IDLE;
            end
 
            ACCEPT_OP: begin
                if (ar_req)
                    contr_state <= SERVE_AR;
                else if (wr_req)
                    contr_state <= ACCEPT_WR;
                else
                    contr_state <= ACCEPT_OP;
            end
 
            SERVE_AR: begin
                if (ar_end)
                    contr_state <= ACCEPT_OP;
                else
                    contr_state <= SERVE_AR;
            end
 
            ACCEPT_WR: begin
                if (ar_req && !wr_end)
                    contr_state <= WR_ABRUPT_END;
                else if (wr_end)
                    contr_state <= WR_DONE;
                else
                    contr_state <= ACCEPT_WR;
            end
 
            WR_ABRUPT_END: begin
                if (wr_end)
                    contr_state <= WR_DONE;
            end
 
            WR_DONE: begin
                contr_state <= ACCEPT_OP;
            end
 
            default: contr_state <= IDLE;
        endcase
    end
end
 
//=============================
// Output Logic (FSM Outputs)
//=============================
always_ff @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        addro   <= 12'hFFF;
        bao     <= 2'b11;
        cmdo    <= 4'b1111;
        wr_en   <= 1'b0;
        wr_wait <= 1'b0;
        ar_en   <= 1'b0;
    end else begin
        case (contr_state)
            IDLE: begin
                addro   <= init_addro;
                bao     <= init_bao;
                cmdo    <= init_cmdo;
                wr_en   <= 1'b0;
                wr_wait <= 1'b0;
                ar_en   <= 1'b0;
            end
 
            ACCEPT_OP: begin
                addro   <= 12'hFFF;
                bao     <= 2'b11;
                cmdo    <= CMD_NOP;
                wr_en   <= 1'b0;
                wr_wait <= 1'b0;
                ar_en   <= 1'b0;
            end
 
            ACCEPT_WR: begin
                wr_en   <= 1'b1;
                addro   <= wr_addro;
                bao     <= wr_bao;
                cmdo    <= wr_cmdo;
                wr_wait <= 1'b0;
                ar_en   <= 1'b0;
                if (wr_end)
                    wr_en <= 1'b0;
            end
 
            SERVE_AR: begin
                addro   <= ar_addro;
                bao     <= ar_bao;
                cmdo    <= ar_cmdo;
                wr_en   <= 1'b0;
                wr_wait <= 1'b0;
                ar_en   <= 1'b1;
            end
 
            WR_ABRUPT_END: begin
                addro   <= wr_addro;
                bao     <= wr_bao;
                cmdo    <= wr_cmdo;
                wr_en   <= 1'b0;
                wr_wait <= 1'b1;
                ar_en   <= 1'b0;
            end
 
            WR_DONE: begin
                addro   <= 12'hFFF;
                bao     <= 2'b11;
                cmdo    <= CMD_NOP;
                wr_en   <= 1'b0;
                wr_wait <= 1'b0;
                ar_en   <= 1'b0;
            end
 
            default: begin
                addro   <= 12'hFFF;
                bao     <= 2'b11;
                cmdo    <= CMD_NOP;
                wr_en   <= 1'b0;
                wr_wait <= 1'b0;
                ar_en   <= 1'b0;
            end
        endcase
    end
end
 
endmodule