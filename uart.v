module uart(

    input wire rx,
    input wire clk,
    input wire [7:0] data_frame,
    input wire transmit,
    output reg tx = 1,
    output reg ready = 1
);

parameter s_idle = 2'b00;
parameter s_start = 2'b01;
parameter s_data = 2'b10;
parameter s_stop = 2'b11;

reg [3:0] current_state = s_idle;

parameter clk_freq = 100;
parameter baud_rate = 50;

parameter bit_period = clk_freq / baud_rate;

reg [7:0] counter = 0;
reg counter_flag = 0;

reg [3:0] data_bit_pointer = 0;

reg transmit_signal_sent = 0;
reg [7:0] data_frame_sent;

always @(posedge clk) begin

    if (counter >= bit_period - 1) begin
        counter <= 0;
        counter_flag <= 1;
    end
    else begin 
        counter <= counter + 1;
        counter_flag <= 0;
    end
end

always @(posedge clk) begin

    if (transmit && ready) begin
        transmit_signal_sent <= 1;
        ready <= 0;
        data_frame_sent <= data_frame;
    end

    if (counter_flag) begin

        case (current_state)
            s_idle: begin 
                tx <= 1;
                data_bit_pointer <= 0;
                if (transmit_signal_sent) current_state <= s_start;
            end
            s_start: begin
                tx <= 0;
                current_state <= s_data;
            end
            s_data: begin
                tx <= data_frame_sent[data_bit_pointer];
                data_bit_pointer <= data_bit_pointer + 1;
                if (data_bit_pointer == 7) current_state <= s_stop;
            end
            s_stop:
                begin
                    tx <= 1;
                    current_state <= s_idle;
                    transmit_signal_sent <= 0;
                    ready <= 1;
                end
            default: begin
                current_state <= s_idle;
                tx <= 1; 
                data_bit_pointer <= 0;
                ready <= 1;
                transmit_signal_sent <= 0;
            end
        endcase
    end
end

endmodule


module tb;

    reg rx;
    reg clk;
    reg [7:0] data_frame;
    reg transmit;
    wire tx;
    wire ready;

    
    uart module_uart(
        .rx         	(rx          ),
        .clk        	(clk         ),
        .data_frame 	(data_frame  ),
        .transmit   	(transmit    ),
        .tx         	(tx          ),
        .ready(ready)
    );

    initial begin
        $dumpvars(0, tb);
        clk = 0;
        rx = 0;
        data_frame = 8'b01000001;
        #1000 $finish;
    end

    initial begin
        transmit = 1;
        #10;
        transmit = 0;
    end

    always begin
        clk = ~clk;
        #5;
    end


endmodule