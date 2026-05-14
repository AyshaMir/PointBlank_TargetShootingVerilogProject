`timescale 1ns / 1ps
module debounce(
    input clock,
    input unstableinputfromsensor,
    output reg stable_out
);
    parameter max_count = 200000; // this means thatif input stays samne for 2ms, we can accept it
    reg [17:0] count = 0; //this is to count the maxcount
    reg prevstate = 0; //this remebers the prev 0/1

    always @(posedge clock) begin
        if (unstableinputfromsensor == prevstate) //agr the input we get is the same as prev val
            count <= 0;
        else begin
            count <= count + 1; //wanra count how long this val stays same
            if (count >= max_count) begin //agr count is >= 2ms
                prevstate <= unstableinputfromsensor;  
                stable_out <= unstableinputfromsensor;
                count <= 0;
            end
        end
    end
endmodule