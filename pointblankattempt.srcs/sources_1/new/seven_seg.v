`timescale 1ns / 1ps
module seven_seg(
    input clock,
    input [3:0] score_tens, score_ones, //score ka ones and tnes
    input [3:0] time_tens, time_ones, // timer ka ones anf tens 
    output reg [6:0] seg, 
    output reg [3:0] an
);
    reg [16:0] displayrefresh = 0; //It acts like a timer or counter that increases every clock cycle, every 10 nanoseconds, it adds 1
    wire [1:0] seg_select; //0123, konsa segment dispaly horha
    reg [3:0] value; //stores val curreently dispalyed  

    assign seg_select = displayrefresh[16:15]; //ake the two highest bits (bit 16 and bit 15) from the counter,and feed them into digselect

    always @(posedge clock)
        displayrefresh <= displayrefresh + 1; //adding the counter

    always @(*) begin
        case (seg_select) //// Use the two most significant bits of the refresh counter to cycle through the four display digits.
            2'b00: begin an = 4'b1110; value = time_ones;  end
            2'b01: begin an = 4'b1101; value = time_tens;  end
            2'b10: begin an = 4'b1011; value = score_ones; end
            2'b11: begin an = 4'b0111; value = score_tens; end
            default: begin an = 4'b1111; value = 4'd0; end
        endcase
    end //

    always @(*) begin
        case (value) // ye wo truth table hai which we made in shuru ki labs 
            4'd0: seg = 7'b1000000;
            4'd1: seg = 7'b1111001;
            4'd2: seg = 7'b0100100;
            4'd3: seg = 7'b0110000;
            4'd4: seg = 7'b0011001;
            4'd5: seg = 7'b0010010;
            4'd6: seg = 7'b0000010;
            4'd7: seg = 7'b1111000;
            4'd8: seg = 7'b0000000;
            4'd9: seg = 7'b0010000;
            default: seg = 7'b1111111;
        endcase
    end
endmodule
