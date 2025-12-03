module rx_core#(
    parameter WIDTH = 8,
    parameter SAMPLING_TICKS = 16,
    parameter STOP_BITS = 1
)(
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire baud_tick,

    output reg [WIDTH-1:0] rx_data_out,
    output reg rx_ready,
    output reg rx_error

);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    reg [1:0] state;
    reg [WIDTH-1:0] shift_reg;

   
    reg [$clog2(SAMPLING_TICKS)-1:0] baud_cnt;
    reg [$clog2(WIDTH)-1:0] bit_cnt;
    
    
    reg rx_sync1, rx_sync2;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            shift_reg <= 0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            rx_data_out <= 0;
            rx_ready <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            rx_ready <= 1'b0; 
            
            case(state)
                IDLE: begin
                    baud_cnt <= 0;
                    bit_cnt <= 0;
                    rx_error <= 1'b0;
                    shift_reg <= 0;

                    if(rx_sync2 == 1'b0) begin
                        state <= START;
                    end
                end

                START: begin
                    if(baud_tick) begin
                        if(baud_cnt == (SAMPLING_TICKS/2)) begin
                            if(rx_sync2 == 1'b0) begin
                                baud_cnt <= baud_cnt + 1;
                            end else begin
                                state <= IDLE;
                                baud_cnt <= 0;
                                rx_error <= 1'b1;
                            end
                        end else if(baud_cnt == SAMPLING_TICKS - 1) begin
                            baud_cnt <= 0;
                            state <= DATA;
                            bit_cnt <= 0;
                        end else begin
                            baud_cnt <= baud_cnt + 1;
                        end
                    end
                end

                DATA: begin
                    if(baud_tick) begin
                        // Lấy mẫu ở giữa bit
                        if(baud_cnt == (SAMPLING_TICKS/2)) begin
                            shift_reg <= {rx_sync2, shift_reg[WIDTH-1:1]};
                            baud_cnt <= baud_cnt + 1;
                        end else if(baud_cnt == SAMPLING_TICKS - 1) begin
                            baud_cnt <= 0;
                            if(bit_cnt == WIDTH - 1) begin
                                state <= STOP;
                                bit_cnt <= 0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end else begin
                            baud_cnt <= baud_cnt + 1;
                        end
                    end
                end

                STOP: begin
                    if(baud_tick) begin
                        if(baud_cnt == (SAMPLING_TICKS/2)) begin
                            if(rx_sync2 == 1'b1) begin
                                baud_cnt <= baud_cnt + 1;
                            end else begin
                                rx_error <= 1'b1;
                                baud_cnt <= baud_cnt + 1;
                            end
                        end else if(baud_cnt == SAMPLING_TICKS - 1) begin
                            baud_cnt <= 0;
                            if(bit_cnt == STOP_BITS - 1) begin
                                rx_data_out <= shift_reg;
                                rx_ready <= 1'b1;
                                state <= IDLE;
                                bit_cnt <= 0;
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