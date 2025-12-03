`timescale 1ns/1ps
`include "uart_rx.v"
module tb_uart_rx;

    // Params
    localparam WIDTH = 8;
    localparam SAMPLING_TICKS = 16;

    // Clock: 100 MHz (period = 10ns)
    reg clk = 0;
    always #5 clk = ~clk;

    // DUT signals
    reg rst_n;
    reg rx;
    wire [WIDTH-1:0] d_out;
    wire rd_en;

    // Instantiate DUT
    uart_rx #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS),
        .STOP_BITS(1)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .d_out(d_out),
        .rd_en(rd_en)
    );

    // -------------------------------------------------------
    // UART timing (9600 baud)
    // bit_time = 1/9600 = 104166 ns
    // TB sẽ delay theo bit-time thay vì theo baud_tick của DUT
    // -------------------------------------------------------
    real BIT_TIME = 104_166;   // ns

    // -------------------------------------------------------
    // Task gửi 1 byte UART (LSB first)
    // -------------------------------------------------------
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // START bit
            rx <= 0;
            #(BIT_TIME);

            // 8 DATA bits
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(BIT_TIME);
            end

            // STOP bit
            rx <= 1;
            #(BIT_TIME);
        end
    endtask

    // -------------------------------------------------------
    // FIFO read logic (simple)
    // -------------------------------------------------------
    reg do_read = 0;
    initial begin
        forever begin
            @(posedge clk);
            if (do_read)
                do_read <= 0;
        end
    end

    assign rd_en = do_read;

    // -------------------------------------------------------
    // Main test
    // -------------------------------------------------------
    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        rx = 1;
        rst_n = 0;
        #200;
        rst_n = 1;

        // ---------------------------------------------------
        // Send 1 byte: 0xA5
        // ---------------------------------------------------
        $display("\n=== SEND BYTE 0xA5 ===");
        uart_send_byte(8'hA5);

        // Đợi một thời gian rx_core xử lý
        #200_000;

        // Đọc FIFO
        do_read <= 1;
        @(posedge clk);

        #100_000;
        $display("READ  = %02h", d_out);

        // ---------------------------------------------------
        // Send 2nd byte: 0x3C
        // ---------------------------------------------------
        $display("\n=== SEND BYTE 0x3C ===");
        uart_send_byte(8'h3C);

        #200_000;

        do_read <= 1;
        @(posedge clk);

        #100_000;
        $display("READ  = %02h", d_out);

        // ---------------------------------------------------
        // Done
        // ---------------------------------------------------
        #200_000;
        $finish;
    end

endmodule
