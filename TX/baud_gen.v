module baud_gen #(
    parameter CLOCK_FREQ = 100000000,
    parameter BAUD_RATE = 9600,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    output reg baud_tick
);

    localparam BAUD_TICK = CLOCK_FREQ / (BAUD_RATE * 16);

    reg [$clog2(BAUD_TICK)-1:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <=0;
            baud_tick <=0;
        end else begin
            if(counter == BAUD_TICK-1) begin
                baud_tick <= 1'b1;
                counter <= 0;
            end else begin
                counter <= counter + 1;
                baud_tick <= 1'b0;
            end
        end
        
    end


endmodule