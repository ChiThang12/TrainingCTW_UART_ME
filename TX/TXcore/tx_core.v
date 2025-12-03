module tx_core#(
    parameter WIDTH = 8,
    parameter SAMPLING_TICKS = 16,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0]tx_data_in,
    input wire tx_start,
    input wire baud_tick,

    output reg tx,
    output reg tx_busy
);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state;
    reg [WIDTH-1:0] shift_reg;

    // Bieen noi bo
    reg [$clog2(SAMPLING_TICKS)-1:0] baud_cnt;
    reg [$clog2(WIDTH)-1:0] bit_cnt;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            state <= IDLE;
            shift_reg <= 0;
            baud_cnt <=0;
            tx_busy <=0;
            tx <=1'b1; // Default luoon laf bit H
            bit_cnt <=0;
       
        end else begin
            case(state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    baud_cnt <=0;
                    bit_cnt <=0;
                    if(tx_start) begin
                        state <= START;
                        tx_busy <= 1'b1;
                    end
                end
 
                START: begin
                    tx <= 1'b0; 
                    tx_busy <= 1'b1;
                    if(baud_tick) begin
                        if(baud_cnt == SAMPLING_TICKS - 1) begin
                            baud_cnt <=0;
                            shift_reg <= tx_data_in;
                            state <= DATA;
                            bit_cnt <=0;
                        end else begin
                            baud_cnt <= baud_cnt + 1;
                        end
                    end
                end

                DATA: begin
                    tx <= shift_reg[0];
                    if(baud_tick)begin
                        if(baud_cnt == SAMPLING_TICKS - 1)begin
                            baud_cnt <=0;
                            shift_reg <= shift_reg >> 1;
                            if(bit_cnt == WIDTH - 1) begin
                                state <= STOP;
                                bit_cnt <=0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end else begin
                            baud_cnt <= baud_cnt + 1;
                        end
                    end
                    
                end

                STOP: begin
                    tx <= 1'b1;
                    if(baud_tick) begin
                        if(baud_cnt == SAMPLING_TICKS - 1) begin
                            baud_cnt <=0;
                            if(bit_cnt == STOP_BITS - 1) begin
                                state <= IDLE;
                                bit_cnt <=0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end else begin
                            baud_cnt <= baud_cnt + 1;
                        end
                    end
                    
                end
            endcase

        end
    end



endmodule