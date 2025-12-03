`include "baud_gen.v"
`include "RXcore/rx_core.v"
`include "fifo.v"

module uart_rx#(
    parameter WIDTH = 8,
    parameter SAMPLING_TICKS = 16,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire rd_en,

    output wire [WIDTH-1:0] d_out,
    output wire empty,
    output wire full

);

    // b a u d g e m
    wire baud_tick;
    baud_gen #(
        .CLOCK_FREQ(100_000_000),
        .BAUD_RATE(9600),
        .DATA_WIDTH(WIDTH)
    ) baud_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );


    //r x 
    wire [WIDTH-1:0] rx_data_out;
    wire rx_ready;
    wire rx_error;
    rx_core #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS),
        .STOP_BITS(STOP_BITS)
    ) rx_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .baud_tick(baud_tick), 
        .rx_data_out(rx_data_out),
        .rx_ready(rx_ready),
        .rx_error(rx_error)
    );


    // f i f o
    wire wr_en = rx_ready && !rx_error && !full;
    wire [WIDTH-1:0] data;
    fifo #(
        .WIDTH(WIDTH),
        .DEPTH(16)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .d_in(rx_data_out),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .d_out(d_out)
    );




endmodule