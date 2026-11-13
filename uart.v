module uart # (
    parameter CLK_FREQ = 100,
    parameter BAUD_RATE = 50
)(

    input wire clk,
    input wire [7:0] data_frame,
    input wire tx_start_transmit,
    output reg tx_line = 1,
    output reg tx_ready = 1
);

localparam STATE_IDLE = 2'b00;
localparam STATE_START = 2'b01;
localparam STATE_DATA = 2'b10;
localparam STATE_STOP = 2'b11;

reg [1:0] current_state = STATE_IDLE;

localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

reg [7:0] counter = 0;
reg counter_flag = 0;

reg [2:0] data_bit_pointer = 0;
reg [7:0] data_frame_sent;

reg transmit_signal_sent = 0;


always @(posedge clk) begin

    if (counter >= BIT_PERIOD - 1) begin
        counter <= 0;
        counter_flag <= 1;
    end
    else begin 
        counter <= counter + 1;
        counter_flag <= 0;
    end
end


always @(posedge clk) begin

    if (tx_start_transmit && tx_ready) begin
        transmit_signal_sent <= 1;
        tx_ready <= 0;
        data_frame_sent <= data_frame;
    end

    if (counter_flag) begin
        case (current_state)
            STATE_IDLE: begin 
                tx_line <= 1;
                data_bit_pointer <= 0;
                if (transmit_signal_sent) current_state <= STATE_START;
            end
            STATE_START: begin
                tx_line <= 0;
                current_state <= STATE_DATA;
            end
            STATE_DATA: begin
                tx_line <= data_frame_sent[data_bit_pointer];
                data_bit_pointer <= data_bit_pointer + 1;
                if (data_bit_pointer == 7) current_state <= STATE_STOP;
            end
            STATE_STOP:
                begin
                    tx_line <= 1;
                    current_state <= STATE_IDLE;
                    transmit_signal_sent <= 0;
                    tx_ready <= 1;
                end
            default: begin
                current_state <= STATE_IDLE;
                tx_line <= 1; 
                data_bit_pointer <= 0;
                tx_ready <= 1;
                transmit_signal_sent <= 0;
            end
        endcase
    end
end

endmodule


module transmit_data (

    input btn,
    input clk,
    output tx_line
);

    reg transmit_en = 0;
    reg button_prev;

    always @(posedge clk) begin
        button_prev <= btn;
        if (button_prev && !btn) begin
            transmit_en = 1;
        end
        else
            transmit_en = 0; 
    end

    reg [7:0] data_to_transmit = 8'b01000001;

    uart module_uart(
        .clk (clk),
        .tx_line(tx_line),
        .data_frame (data_to_transmit),
        .tx_start_transmit (transmit_en)
    );

endmodule

module tb;

    reg clk;
    reg [7:0] data_frame;
    reg tx_start_transmit;
    wire tx_line;
    wire tx_ready;

    
    uart module_uart(
        .clk        	(clk         ),
        .data_frame 	(data_frame  ),
        .tx_start_transmit   	(tx_start_transmit    ),
        .tx_line         	(tx_line          ),
        .tx_ready(tx_ready)
    );

    initial begin
        $dumpvars(0, tb);
        clk = 0;
        data_frame = 8'b01000001;
        #230;
        tx_start_transmit = 1;
        data_frame = 8'b01111101;
        #10;
        tx_start_transmit = 0;
        #1000 $finish;
    end

    initial begin
        tx_start_transmit = 1;
        #10;
        tx_start_transmit = 0;
    end

    always begin
        clk = ~clk;
        #5;
    end


endmodule