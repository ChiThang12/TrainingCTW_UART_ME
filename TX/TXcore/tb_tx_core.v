`timescale 1ns/1ps
`include "tx_core.v"

module tb_tx_core;

    parameter WIDTH = 8;
    parameter SAMPLING_TICKS = 16;

    // Signals
    reg clk;
    reg rst_n;
    reg [WIDTH-1:0] tx_data_in;
    reg tx_start;
    reg baud_tick;

    wire tx;
    wire tx_busy;

    // Instantiate DUT
    tx_core #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data_in(tx_data_in),
        .tx_start(tx_start),
        .baud_tick(baud_tick),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    // Dump VCD
    initial begin
        $dumpfile("tb_tx_core.vcd");
        $dumpvars(0, tb_tx_core);
    end


    initial clk = 0;
    always #5 clk = ~clk;

   
    initial baud_tick = 0;
    always #10 baud_tick = ~baud_tick;

    // Test sequence: gửi nhiều byte liên tiếp
    reg [7:0] test_bytes [0:3]; 
    integer i;

    initial begin
   
        rst_n = 0;
        tx_data_in = 8'h00;
        tx_start = 0;
        #20;
        rst_n = 1;
        #20;

        test_bytes[0] = 8'hA5;
        test_bytes[1] = 8'h3C;
        test_bytes[2] = 8'hFF;
        test_bytes[3] = 8'h00;

        // Gửi từng byte
        for(i=0; i<4; i=i+1) begin
            tx_data_in = test_bytes[i];
            wait(!tx_busy);   
            tx_start = 1;
            #10;
            tx_start = 0;
        end

        #200;
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | tx=%b | tx_busy=%b | tx_start=%b | shift_reg=%b", 
                 $time, tx, tx_busy, tx_start, dut.shift_reg);
    end

endmodule
