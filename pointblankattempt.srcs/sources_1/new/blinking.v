`timescale 1ns / 1ps
module blinking(
    input clock,
    input running, //this is basically the start buttn and reset button from timer and sscore mod
    output reg led //led om fpga
);
    reg [25:0] blink_div = 0; //every clock cycle, it increases by 1, used to slow down the very fast 100 MHz clock (100 million ticks per second)

    always @(posedge clock) begin
        if (running) begin // agr start hai to 
            blink_div <= blink_div + 1; // counter inc by 1
            if (blink_div == 50_000_000) begin //agr ints hogya to 
                blink_div <= 0; // reset it 
                led <= ~led; // agr on to off, off to on
            end
        end else begin
            blink_div <= 0; //disabled
            led <= 0;
        end
    end
endmodule
