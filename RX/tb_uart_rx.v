`timescale 1ns/1ps
`include "uart_rx.v"
module tb_uart_rx;


    localparam WIDTH = 8;
    localparam SAMPLING_TICKS = 16;


    reg clk = 0;
    always #5 clk = ~clk;

    reg rst_n;
    reg rx;
    wire [WIDTH-1:0] d_out;
    wire rd_en;


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

 
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // START bit
            rx <= 0;
            #(BIT_TIME);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(BIT_TIME);
            end


            rx <= 1;
            #(BIT_TIME);
        end
    endtask


    reg do_read = 0;
    initial begin
        forever begin
            @(posedge clk);
            if (do_read)
                do_read <= 0;
        end
    end

    assign rd_en = do_read;


    initial begin
        $dumpfile("tb_uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        rx = 1;
        rst_n = 0;
        #200;
        rst_n = 1;

 
        $display("\n=== SEND BYTE 0xA5 ===");
        uart_send_byte(8'hA5);

      
        #200_000;


        do_read <= 1;
        @(posedge clk);

        #100_000;
        $display("READ  = %02h", d_out);


        $display("\n=== SEND BYTE 0x3C ===");
        uart_send_byte(8'h3C);

        #200_000;

        do_read <= 1;
        @(posedge clk);

        #100_000;
        $display("READ  = %02h", d_out);


        #200_000;
        $finish;
    end

endmodule
