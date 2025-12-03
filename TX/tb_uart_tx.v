`timescale 1ns/1ps
`include "uart_tx.v"

module tb_uart_tx;

    parameter WIDTH = 8;
    parameter SAMPLING_TICKS = 16;

    reg clk;
    reg rst_n;
    reg wr_en;
    reg start;
    reg [WIDTH-1:0] data_in;

    wire tx;
    wire busy;

    // Instantiate DUT
    uart_tx #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .data_in(data_in),
        .start(start),
        .tx(tx),
        .busy(busy)
    );

    // Dump VCD
    initial begin
        $dumpfile("tb_uart_tx.vcd");
        $dumpvars(0, tb_uart_tx);
    end

    // Clock: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
    reg [7:0] test_bytes [0:3];
    integer i;

    initial begin
        // Init
        rst_n = 0;
        wr_en = 0;
        start = 0;
        data_in = 8'h00;
        #20;
        rst_n = 1;
        #20;

        // Byte muốn gửi
        test_bytes[0] = 8'hA5;
        test_bytes[1] = 8'h3C;
        test_bytes[2] = 8'hFF;
        test_bytes[3] = 8'h00;

        // Gửi từng byte
        for(i=0; i<4; i=i+1) begin
            data_in = test_bytes[i];
            wr_en = 1;         // ghi vào FIFO 1 tick
            #10;
            wr_en = 0;

            // Start transmission khi tx không busy và FIFO không rỗng
            wait(!busy);
            start = 1;
            #10;
            start = 0;
        end

        // Kết thúc simulation
        #5000;
        $finish;
    end

    // Monitor
    initial begin
        $monitor("Time=%0t | tx=%b | busy=%b | start=%b | data_in=%h", 
                 $time, tx, busy, start, data_in);
    end

endmodule
