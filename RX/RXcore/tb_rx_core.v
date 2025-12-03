`timescale 1ns/1ps
`include "rx_core.v"
module tb_rx_core;

    // Parameters
    localparam WIDTH = 8;
    localparam SAMPLING_TICKS = 16;
    localparam STOP_BITS = 1;

    // DUT signals
    reg clk;
    reg rst_n;
    reg rx;
    reg baud_tick;

    wire [WIDTH-1:0] rx_data_out;
    wire rx_ready;
    wire rx_error;

    // Instantiate DUT
    rx_core #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS),
        .STOP_BITS(STOP_BITS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .baud_tick(baud_tick),
        .rx_data_out(rx_data_out),
        .rx_ready(rx_ready),
        .rx_error(rx_error)
    );

    // Clock 50 MHz -> period 20 ns
    initial clk = 0;
    always #10 clk = ~clk;

    // Generate baud tick
    integer bt_cnt = 0;
    initial baud_tick = 0;
    always @(posedge clk) begin
        if (bt_cnt == 10) begin
            baud_tick <= 1'b1;
            bt_cnt <= 0;
        end else begin
            baud_tick <= 1'b0;
            bt_cnt <= bt_cnt + 1;
        end
    end

    // Task gửi 1 byte UART
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // START bit
            rx <= 0;
            repeat(SAMPLING_TICKS) @(posedge baud_tick);

            // DATA bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                repeat(SAMPLING_TICKS) @(posedge baud_tick);
            end
            
            // STOP bit
            rx <= 1;
            repeat(SAMPLING_TICKS) @(posedge baud_tick);
        end
    endtask

    // Main stimulus
    initial begin
        $dumpfile("tb_rx_core.vcd");
        $dumpvars(0, tb_rx_core);

        rx = 1;       // idle high
        rst_n = 0;
        #200;
        rst_n = 1;

        $display("\n=== SEND BYTE 0xA5 ===");
        uart_send_byte(8'hA5);

        // Chờ rx_ready
        wait(rx_ready);
        #1;
        $display("Received: %02h (ready=%b, error=%b)", rx_data_out, rx_ready, rx_error);

        #3000;

        $display("\n=== SEND BYTE 0x3C ===");
        uart_send_byte(8'h3C);

        wait(rx_ready);
        #1;
        $display("Received: %02h (ready=%b, error=%b)", rx_data_out, rx_ready, rx_error);

        #3000;

        $display("\n=== TEST STOP BIT ERROR ===");
        // gửi stop bit = 0 để test rx_error
        rx <= 0;
        repeat(SAMPLING_TICKS) @(posedge baud_tick);

        #5000;

        $finish;
    end

endmodule
