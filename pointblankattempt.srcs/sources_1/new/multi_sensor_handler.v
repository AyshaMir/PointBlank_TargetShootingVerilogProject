`timescale 1ns / 1ps
module multi_sensor_handler #( //this # thing is a parameter list, it basically alows the paarmeters inside it to be overriden when instatiated
    parameter NUM_SENSORS = 6,
    parameter SCORE_PER_HIT = 10,
    parameter MAX_SCORE = 60
)(
    input clock,
    input reset,
    input running, //allow scoring only when running
    input timer_done, //timer end - auto game over
    input [NUM_SENSORS-1:0] sensor_raw, // teh unstable sensor inputs 
    output reg [NUM_SENSORS-1:0] used, //thsi used for vga logic to hide can after it is used
    output reg [6:0] score, //7 bits allow 60 
    output reg game_over
);

    reg [NUM_SENSORS-1:0] prev_sensor; //last cycle debounce edge vals
    wire [NUM_SENSORS-1:0] sensor_clean; //clean input 

    integer k;
    genvar i; //llop index for gen blco

    // Debounce all 6 sensors
    generate
        for (i = 0; i < NUM_SENSORS; i = i + 1) begin : sensor //dounces the 6 sesnors and does one hit per sensor 
            debounce db (
                .clock(clock),
                .unstableinputfromsensor(sensor_raw[i]),
                .stable_out(sensor_clean[i])
            );
        end
    endgenerate

    initial begin //shrur mein har xheez zero 
        score = 0;
        game_over = 0;
        used = 0;
        prev_sensor = 0;
    end

    always @(posedge clock) begin

        if (reset) begin //agr reset 1 deta to reset all vars
            score <= 0;
            game_over <= 0;
            used <= 0;
            prev_sensor <= sensor_clean;
        end

        else if (!game_over) begin //warna agr ame over nhi hoi to 
            if (timer_done) //check timer if 0 then gameover == 1
                game_over <= 1;
            // Check each sensor, only score if game running and that can is not already hit
            for (k = 0; k < NUM_SENSORS; k = k + 1) begin
                if (running && !used[k]) begin
                    //rising edge
                       if (prev_sensor[k] == 0 && sensor_clean[k] == 1) begin
                        score <= score + SCORE_PER_HIT;
                        used[k] <= 1;
                    end
                end
            end
            // update
            prev_sensor <= sensor_clean;
            //agr score limit/ 60 hoagai to gameover = 1
            if (score >= MAX_SCORE) begin
                score <= MAX_SCORE;
                game_over <= 1;
            end
        end

    end

endmodule
