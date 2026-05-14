`timescale 1ns / 1ps
module topmodule_6(
    input clock,
    input start,
    input reset,
    input [5:0] sensor_input,   // 6 sensors
    output [6:0] seg,
    output [3:0] an,
    output led
);

    // -------------------------
    // DEBOUNCE START & RESET
    // -------------------------
    wire start_clean, reset_clean;
    debounce db_start (.clock(clock), .unstableinputfromsensor(start), .stable_out(start_clean));
    debounce db_reset (.clock(clock), .unstableinputfromsensor(reset), .stable_out(reset_clean));

    // -------------------------
    // TIMER
    // -------------------------
    wire [5:0] count;
    wire timer_done;
    wire running;

    wire game_over; // from scoring module

    timer timer1(
        .clock(clock),
        .switch(start_clean),
        .reset(reset_clean),

        // Stop timer when score hits 60
        .stopwhenscore(game_over),

        .count(count),
        .done(timer_done),
        .running(running)
    );

    // -------------------------
    // SCORING MODULE
    // -------------------------
    wire [6:0] score;

    multi_sensor_handler scoreblock(
        .clock(clock),
        .reset(reset_clean),
        .running(running),
        .timer_done(timer_done),      // <-- FIXED (was missing)
        .sensor_raw(sensor_input),
        .score(score),
        .game_over(game_over)
    );

    // -------------------------
    // 7-SEGMENT DRIVER
    // -------------------------
    wire [3:0] time_tens  = count / 10;
    wire [3:0] time_ones  = count % 10;
    wire [3:0] score_tens = score / 10;
    wire [3:0] score_ones = score % 10;

    seven_seg display(
        .clock(clock),
        .score_tens(score_tens),
        .score_ones(score_ones),
        .time_tens(time_tens),
        .time_ones(time_ones),
        .seg(seg),
        .an(an)
    );

    // -------------------------
    // LED BLINK ON GAME OVER
    // -------------------------
    blinking blink(
        .clock(clock),
        .running(game_over), // blink only when game over
        .led(led)
    );

endmodule
