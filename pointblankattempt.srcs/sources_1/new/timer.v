`timescale 1ns / 1ps
module timer(
    input clock,
    input switch,//start signal 
    input reset, //resets both
    input stopwhenscore, //counter jab 60 hojaiaye to timer stop
    output reg [5:0] count, //30 se 0 ka safar
    output reg done, //gives high when timer = 0
    output reg running //if counter is running or not 
);
    reg [26:0] div; // clock divider it counts up to 100 million to make a 1 Hz tick

    initial begin
        div = 0;
        running = 0;
        count = 30; //counts down so 30
        done = 0; //abhi start nhi hoa to 0
    end

    always @(posedge clock) begin
        if (reset) begin // agr reset switch on hai to sab initial stage pay wapis la jao
            count <= 30;
            running <= 0;
            div <= 0;
            done <= 0;
        end
        else if (switch && !done) //agr start swicth on hai and timer khatam nhi hoa to start the timer
            running <= 1;

        if (running && !done && !stopwhenscore) begin //We only count if timer is running, khatam nhi hoa, and not stopped by score mod
            if (div == 99_999_999) begin //100 MHz (100 million ticks per second), So if you count to 99,999,999, that takes 1 second
                div <= 0; //Reset div to 0 after every second.
                if (count > 0)
                    count <= count - 1; // ye to simple count down horha
                else begin // jab timer 0 hojata to done ko 1 dedo 
                    count <= 0;
                    running <= 0;
                    done <= 1;
                end
            end else
                div <= div + 1; //agr 1 sec nhi hoa to inc divider
        end
        else
            div <= 0; //reset
    end
endmodule