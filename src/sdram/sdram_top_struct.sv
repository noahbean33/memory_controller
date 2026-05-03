module sdram_top_struct (
    input  logic         sys_clk,
    input  logic         sys_rst_n,
    input  logic         wr_req,
    output logic         wr_end,
    input  logic [24:0]  wr_addr,
    input  logic [15:0]  wr_data,
    input  logic [7:0]   wr_burst_len,
    input  logic         wr_dqm,

    output logic busy,
    output logic err,
    output logic new_data,
    output logic [15:0] wr_datao,
    output logic [11:0] addro,
    output logic [1:0]  bao,
    output logic [3:0]  cmdo
);

    // Internal wires for interconnecting modules


    logic        wr_en;
    logic [11:0] wr_addro;
    logic [1:0]  wr_bao;
    logic [3:0]  wr_cmdo;
    logic        wr_trans_err;

    logic        ar_en;
    logic        ar_req;
    logic        ar_end;
    logic [11:0] ar_addro;
    logic [1:0]  ar_bao;
    logic [3:0]  ar_cmdo;

    logic        start_auto_ref;
    logic        wr_busy;
    logic        wr_bcomplete;
    logic [3:0]  wr_cmd_out;
    logic [1:0]  wr_ba_out;
    logic [11:0] wr_addr_out;
    logic [15:0] wr_data_out;
    logic        wr_dqm_out;

    // Initialization Module
    logic        init_done;
    logic [3:0]  init_cmdo;
    logic [1:0]  init_bao;
    logic [11:0] init_addro;
    
    sdram_init u_sdram_init (
        .sys_clk    (sys_clk),
        .sys_rst_n  (sys_rst_n),
        .init_cmd   (init_cmdo),
        .init_ba    (init_bao),
        .init_addr  (init_addro),
        .init_done  (init_done)
    );
 
    // Controller Module
    logic wr_wait;
    controller u_controller (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_done    (init_done),
        .init_addro   (init_addro),
        .init_bao     (init_bao),
        .init_cmdo    (init_cmdo),
 
        .wr_req       (wr_req),
        .wr_end       (wr_end),
        .wr_en        (wr_en),
        .wr_wait      (wr_wait),
        .wr_addro     (wr_addro),
        .wr_bao       (wr_bao),
        .wr_cmdo      (wr_cmdo),
 
        .ar_req       (ar_req),
        .ar_end       (ar_end),
        .ar_en        (ar_en),
        .ar_addro     (ar_addro),
        .ar_bao       (ar_bao),
        .ar_cmdo      (ar_cmdo),
 
        .addro        (addro), 
        .bao          (bao),
        .cmdo         (cmdo),
        .busy         (busy)
    );
 
    // Auto-refresh Module
    sdram_ar u_sdram_ar (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .init_done (init_done),
        .ar_en     (ar_en),
        .ar_req    (ar_req),
        .ar_end    (ar_end),            // Already connected to top input
        .ar_cmdo   (ar_cmdo),
        .ar_bao    (ar_bao),
        .ar_addro  (ar_addro)
    );
 
 
       sdram_write u_sdram_write (
        .sys_clk      (sys_clk),
        .sys_rst_n    (sys_rst_n),
        .init_done    (init_done),
        .wr_en        (wr_en),
        .wr_addri     (wr_addr),
        .wr_din       (wr_data),
        .wr_blength   (wr_burst_len),
        .wr_dqm_in    (wr_dqm),
        .wr_wait      (wr_wait), // auto-refresh wait request input
 
        .apply_data   (new_data),
        .wr_end       (wr_end),
        .wr_cmd       (wr_cmdo),
        .wr_ba        (wr_bao),
        .wr_addro     (wr_addro),
        .wr_dqm_out   (wr_dqm_out),
        .data_written (wr_datao),
        .trans_err    (err)
    );
 
endmodule