module flash_module 
    (
    input S, 
    input C, 
    inout HOLD_DQ3,
    inout DQ0, 
    inout DQ1, 
    input [31:0] Vcc, 
    inout Vpp_W_DQ2, 
    input RESET2); 


 



N25Qxxx DUT (S, C, HOLD_DQ3, DQ0, DQ1, Vcc, Vpp_W_DQ2,RESET2);



endmodule