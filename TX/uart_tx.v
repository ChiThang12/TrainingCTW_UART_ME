`include "baud_gen.v"
`include "TXcore/tx_core.v"
`include "fifo.v"

module uart_tx#(
    parameter WIDTH = 8,
    parameter SAMPLING_TICKS = 16
)(
    input wire clk,
    input wire rst_n,
    input wire wr_en,
    input wire [WIDTH-1:0] data_in,
    input wire start,

    output wire tx,
    output wire busy
);

    wire baud_tick;
    wire rd_en;
    wire full;
    wire empty;
    wire [WIDTH-1:0] d_out;

    fifo #(
        .DEPTH(16),
        .WIDTH(WIDTH)
    ) fifo_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .d_in(data_in),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .d_out(d_out)
    );

    baud_gen #(
        .CLOCK_FREQ(100_000_000),
        .BAUD_RATE(115200),
        .DATA_WIDTH(WIDTH)
    ) baud_gen_inst (
        .clk(clk),
        .rst_n(rst_n),
        .baud_tick(baud_tick)
    );
    assign rd_en = start & ~empty & ~busy;


    tx_core #(
        .WIDTH(WIDTH),
        .SAMPLING_TICKS(SAMPLING_TICKS)
    ) tx_core_inst (
        .clk(clk),
        .rst_n(rst_n),
        .tx_data_in(d_out),
        .tx_start(start),
        .baud_tick(baud_tick),
        .tx(tx),
        .tx_busy(busy)
    );

endmodule