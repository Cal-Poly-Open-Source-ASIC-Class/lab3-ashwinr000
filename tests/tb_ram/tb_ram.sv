`timescale 1ns/1ps

module tb_ram();

    logic clk_i;
    logic pA_wb_cyc_i;
    logic pB_wb_cyc_i;
    logic pA_wb_stb_i;
    logic pB_wb_stb_i;
    logic pA_wb_we_i;
    logic pB_wb_we_i;
    logic [10:0] pA_wb_addr_i;
    logic [10:0] pB_wb_addr_i;
    logic [7:0] pA_wb_data_i;
    logic [7:0] pB_wb_data_i;
    logic pA_wb_ack_o;
    logic pB_wb_ack_o;
    logic pA_wb_stall_o;
    logic pB_wb_stall_o;
    logic [31:0] pA_wb_data_o;
    logic [31:0] pB_wb_data_o;

    `ifdef USE_POWER_PINS
        wire VPWR;
        wire VGND;
        assign VPWR=1;
        assign VGND=0;
    `endif



    localparam CLK_PERIOD = 10;
    always begin
        #(CLK_PERIOD/2) 
        clk_i <= ~clk_i;
    end
    

    // Necessary to create Waveform
    initial begin
        // Name as needed
        clk_i = 0;
        $dumpfile("tb_ram.vcd");
        //$dumpvars(0);
        $dumpvars(2, tb_ram);
    end

    task pA_ram_write(input logic [10:0] addr_in, input logic [7:0] data_in);
        wait(~clk_i);
        pA_wb_stb_i = 1;
        pA_wb_we_i = 1;
        pA_wb_addr_i = addr_in;
        pA_wb_data_i = data_in;
        wait(clk_i);

        wait(~clk_i);
        wait(pA_wb_ack_o);
        pA_wb_we_i = 0;
        pA_wb_stb_i = 0;
    
    endtask

    task pA_ram_read(input logic [10:0] addr_in, output logic [31:0] data_out);
        wait(~clk_i);
        pA_wb_stb_i = 1;
        pA_wb_we_i = 0;
        pA_wb_addr_i = addr_in;
        wait(clk_i);

        wait(~clk_i);
        wait(pA_wb_ack_o);
        data_out = pA_wb_data_o;
        pA_wb_we_i = 0;
        pA_wb_stb_i = 0;
    
    endtask

    task pB_ram_write(input logic [10:0] addr_in, input logic [7:0] data_in);
        wait(~clk_i);
        pB_wb_stb_i = 1;
        pB_wb_we_i = 1;
        pB_wb_addr_i = addr_in;
        pB_wb_data_i = data_in;
        wait(clk_i);

        wait(~clk_i);
        wait(pB_wb_ack_o);
        pB_wb_we_i = 0;
        pB_wb_stb_i = 0;
    
    endtask

    task pB_ram_read(input logic [10:0] addr_in, output logic [31:0] data_out);
        wait(~clk_i);
        pB_wb_stb_i = 1;
        pB_wb_we_i = 0;
        pB_wb_addr_i = addr_in;
        wait(clk_i);

        wait(~clk_i);
        wait(pB_wb_ack_o);
        data_out = pB_wb_data_o;
        pB_wb_we_i = 0;
        pB_wb_stb_i = 0;
    
    endtask

    task pA_pB_ram_read(input logic [10:0] pA_addr_in, input logic [10:0] pB_addr_in, output logic [31:0] pA_data_out, output logic [31:0] pB_data_out);
        wait(~clk_i);
        pA_wb_cyc_i = 1;
        pA_wb_stb_i = 1;
        pA_wb_we_i = 0;
        pA_wb_addr_i = pA_addr_in;

        pB_wb_cyc_i = 1;
        pB_wb_stb_i = 1;
        pB_wb_we_i = 0;
        pB_wb_addr_i = pB_addr_in;
        wait(clk_i);

        wait(~clk_i);
        if (pB_wb_stall_o)
        begin
            wait(pA_wb_ack_o);
            pA_data_out = pA_wb_data_o;
            pA_wb_we_i = 0;
            pA_wb_cyc_i = 0;
            pA_wb_stb_i = 0;
            wait(pB_wb_ack_o);
            pB_data_out = pB_wb_data_o;
            //wait(~clk_i);
            pB_wb_we_i = 0;
            pB_wb_cyc_i = 0;
            pB_wb_stb_i = 0;
        end
        else
        begin
            wait(pB_wb_ack_o);
            pB_data_out = pB_wb_data_o;
            pB_wb_we_i = 0;
            pB_wb_cyc_i = 0;
            pB_wb_stb_i = 0;
            wait(pA_wb_ack_o);
            pA_data_out = pA_wb_data_o;
            //wait(~clk_i);
            pA_wb_we_i = 0;
            pA_wb_cyc_i = 0;
            pA_wb_stb_i = 0;
        end
        wait(~pA_wb_ack_o & ~pB_wb_ack_o);

    endtask

    initial 
    begin
        
        logic [10:0] addr;
        logic [10:0] addr2;
        logic [7:0] data_in;
        logic [31:0] pA_data_out;
        logic [31:0] pB_data_out;

        pA_wb_cyc_i = 1;
        pB_wb_cyc_i = 1;

        addr = 0;
        data_in = 8;
        pB_ram_write(addr, data_in);

        pB_ram_read(addr, pB_data_out);
        
        addr = 32;
        data_in = 23;
        pB_ram_write(addr, data_in);

        pB_ram_read(addr, pB_data_out);

        addr = 32;
        addr2 = 0;

        pA_pB_ram_read(addr, addr2, pA_data_out, pB_data_out);

        pA_pB_ram_read(addr, addr2, pA_data_out, pB_data_out);

        #30;
        $finish;
    end 

    ram r(
        .clk_i(clk_i),
        .pA_wb_cyc_i(pA_wb_cyc_i),
        .pB_wb_cyc_i(pB_wb_cyc_i),
        .pA_wb_stb_i(pA_wb_stb_i),
        .pB_wb_stb_i(pB_wb_stb_i),
        .pA_wb_we_i(pA_wb_we_i),
        .pB_wb_we_i(pB_wb_we_i),
        .pA_wb_addr_i(pA_wb_addr_i),
        .pB_wb_addr_i(pB_wb_addr_i),
        .pA_wb_data_i(pA_wb_data_i),
        .pB_wb_data_i(pB_wb_data_i),
        .pA_wb_ack_o(pA_wb_ack_o),
        .pB_wb_ack_o(pB_wb_ack_o),
        .pA_wb_stall_o(pA_wb_stall_o),
        .pB_wb_stall_o(pB_wb_stall_o),
        .pA_wb_data_o(pA_wb_data_o),
        .pB_wb_data_o(pB_wb_data_o),
        .VPWR(VPWR),
	    .VGND(VGND)
        );


endmodule