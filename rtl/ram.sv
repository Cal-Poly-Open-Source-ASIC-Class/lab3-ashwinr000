`timescale 1ns/1ps

module ram(
    input clk_i,
    input pA_wb_cyc_i,
    input pB_wb_cyc_i,
    input pA_wb_stb_i,
    input pB_wb_stb_i,
    input pA_wb_we_i,
    input pB_wb_we_i,
    input [10:0] pA_wb_addr_i,
    input [10:0] pB_wb_addr_i,
    input [7:0] pA_wb_data_i,
    input [7:0] pB_wb_data_i,
    input VPWR,
    input VGND,
    output logic pA_wb_ack_o,
    output logic pB_wb_ack_o,
    output logic pA_wb_stall_o,
    output logic pB_wb_stall_o,
    output logic [31:0] pA_wb_data_o,
    output logic [31:0] pB_wb_data_o
    );


logic [31:0] pA_wb_data_padded;
assign pA_wb_data_padded = 32'(pA_wb_data_i) << (pA_wb_addr_i[1:0] * 8);
logic [31:0] pB_wb_data_padded;
assign pB_wb_data_padded = 32'(pB_wb_data_i) << (pB_wb_addr_i[1:0] * 8);

logic d1_pA_sel;
assign d1_pA_sel = ~pA_wb_addr_i[10];
logic d1_pB_sel;
assign d1_pB_sel = ~pB_wb_addr_i[10];
logic d2_pA_sel;
assign d2_pA_sel = pA_wb_addr_i[10];
logic d2_pB_sel; 
assign d2_pB_sel = pB_wb_addr_i[10];

logic pA_en;
assign pA_en = pA_wb_cyc_i & pA_wb_stb_i;

logic pB_en;
assign pB_en = pB_wb_cyc_i & pB_wb_stb_i;

logic [10:0] d1_addr_in;
logic [10:0] d2_addr_in;
logic [7:0] d1_addr_in_trunc;
logic [7:0] d2_addr_in_trunc;

logic [31:0] d1_data_in;
logic [31:0] d2_data_in;

logic [31:0] d1_data_out;
logic [31:0] d2_data_out;

logic turn = 0;
logic collision;
logic stallA;
logic stallB;

logic [3:0] d1_we;
logic [3:0] d2_we;

logic [1:0] pA_data_sel;
logic [1:0] pB_data_sel;

logic [1:0] pA_byte_off;
logic [1:0] pB_byte_off;

assign d1_addr_in_trunc = d1_addr_in[7:0];
assign d2_addr_in_trunc = d2_addr_in[7:0];

assign pA_byte_off = pA_wb_addr_i[1:0];
assign pB_byte_off = pB_wb_addr_i[1:0];

always_comb
begin  
    collision = 0;
    stallA = 0;
    stallB = 0;
    d1_addr_in = 0;
    d1_data_in = 0;
    d1_we = 0;
    d2_addr_in = 0;
    d2_data_in = 0;
    d2_we = 0;
    pA_wb_data_o = 0;
    pB_wb_data_o = 0;

    if (pA_en & pB_en)
    begin
        if (d1_pA_sel == d1_pB_sel)
        begin
            // d1 collision!
            if (turn)
            begin
                d1_addr_in = pB_wb_addr_i;
                d1_data_in = pB_wb_data_padded;
                if (pB_wb_we_i)
                    d1_we = (1 << pB_byte_off);
                stallA = 1;
            end
            else
            begin
                d1_addr_in = pA_wb_addr_i;
                d1_data_in = pA_wb_data_padded;
                if (pA_wb_we_i)
                    d1_we = (1 << pA_byte_off);
                stallB = 1;
            end
            collision = 1;
        end
        if (d2_pA_sel == d2_pB_sel)
        begin
            // d2 collision!
            if (turn)
            begin
                d2_addr_in = pB_wb_addr_i;
                d2_data_in = pB_wb_data_padded;
                if (pB_wb_we_i)
                    d2_we = (1 << pB_byte_off);
                stallA = 1;
            end
            else
            begin
                d2_addr_in = pA_wb_addr_i;
                d2_data_in = pA_wb_data_padded;
                if (pA_wb_we_i)
                    d2_we = (1 << pA_byte_off);
                stallB = 1;
            end
            collision = 1;
        end
        else
        begin
            // no collision, service both ports
            if (d1_pA_sel)
            begin
                d1_addr_in = pA_wb_addr_i;
                d1_data_in = pA_wb_data_padded;
                if (pA_wb_we_i)
                    d1_we = (1 << pA_byte_off);
                d2_addr_in = pB_wb_addr_i;
                d2_data_in = pB_wb_data_padded;
                if (pB_wb_we_i)
                    d2_we = (1 << pB_byte_off);
            end
            else 
	        begin
		        d1_addr_in = pB_wb_addr_i;
                d1_data_in = pB_wb_data_padded;
                if (pB_wb_we_i)
                    d1_we = (1 << pB_byte_off);
                d2_addr_in = pA_wb_addr_i;
                d2_data_in = pA_wb_data_padded;
                if (pA_wb_we_i)
                    d2_we = (1 << pA_byte_off);
            end
        end
    end
    else if (pA_en)
        // service port a
    begin
        if (d1_pA_sel)
        begin
            d1_addr_in = pA_wb_addr_i;
            d1_data_in = pA_wb_data_padded;
            if (pA_wb_we_i)
                d1_we = (1 << pA_byte_off);
        end
        else
        begin
            d2_addr_in = pA_wb_addr_i;
            d2_data_in = pA_wb_data_padded;
            if (pA_wb_we_i)
                d2_we = (1 << pA_byte_off);
        end
    end
    else if (pB_en)
    begin
        if (d1_pB_sel)
        begin
            d1_addr_in = pB_wb_addr_i;
            d1_data_in = pB_wb_data_padded;
            if (pB_wb_we_i)
                d1_we = (1 << pB_byte_off);

        end
        else
        begin
            d2_addr_in = pB_wb_addr_i;
            d2_data_in = pB_wb_data_padded;
            if (pB_wb_we_i)
                d2_we = (1 << pB_byte_off);
        end
    end

    if (pA_data_sel == 1)
        pA_wb_data_o = d1_data_out;
    else if(pA_data_sel == 2)
        pA_wb_data_o = d2_data_out;
    if (pB_data_sel == 1)
        pB_wb_data_o = d1_data_out;
    else if(pB_data_sel == 2)
        pB_wb_data_o = d2_data_out;
end

always @(posedge clk_i)
begin
    if (collision)
        turn <= ~turn;
    else
        turn <= turn;
    
    if (((d1_pA_sel & pA_en) | (d2_pA_sel & pA_en)) & ~stallA)
        pA_wb_ack_o <= 1;
    else
        pA_wb_ack_o <= 0;

    if (((d1_pB_sel & pB_en) | (d2_pB_sel & pB_en)) & ~stallB)
        pB_wb_ack_o <= 1;
    else
        pB_wb_ack_o <= 0;

    if (stallA)
        pA_wb_stall_o <= 1;
    else
        pA_wb_stall_o <= 0;

    if (stallB)
        pB_wb_stall_o <= 1;
    else
        pB_wb_stall_o <= 0;

    if (d1_pA_sel & ~stallA & pA_en)
        pA_data_sel <= 1;
    else if (d2_pA_sel & ~stallA & pA_en)
        pA_data_sel <= 2;
    else
        pA_data_sel <= 0;

    if (d1_pB_sel & ~stallB & pB_en)
        pB_data_sel <= 1;
    else if (d2_pB_sel & ~stallB & pB_en)
        pB_data_sel <= 2;
    else
        pB_data_sel <= 0;
    
    
end


DFFRAM256x32 d1(
    //`ifdef USE_POWER_PINS
    //.VPWR(VPWR),
    //.VGND(VGND),
    //`endif
    .CLK(clk_i),
    .WE0(d1_we),
    .EN0((pA_en & d1_pA_sel) | (pB_en & d1_pB_sel)),
    .Di0(d1_data_in),
    .Do0(d1_data_out),
    .A0(d1_addr_in_trunc)
    );


DFFRAM256x32 d2(
    `ifdef USE_POWER_PINS
    .VPWR(VPWR),
    .VGND(VGND),
    `endif
    .CLK(clk_i),
    .WE0(d2_we),
    .EN0((pA_en & d2_pA_sel) | (pB_en & d2_pB_sel)),
    .Di0(d2_data_in),
    .Do0(d2_data_out),
    .A0(d2_addr_in_trunc)
    );


endmodule
