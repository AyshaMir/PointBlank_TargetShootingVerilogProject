`timescale 1ns / 1ps
module top_system (
//inputs
    input  wire        clk100,        // 100 MHz
    input  wire        start,      // external toggle switch
    input  wire [5:0]  sensor_input,   // 6 IR sensors
    //vga output
    output wire        hsync,
    output wire        vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    //fpga outputs
    output wire [6:0]  seg,
    output wire [3:0]  an,
    output wire        led
);
    //deboucne start
    wire start_clean;

    debounce db_start (
        .clock(clk100),
        .unstableinputfromsensor(start),
        .stable_out(start_clean)
    );
    
    //delay when we change screen
    reg [27:0] delay_cnt = 0;
    reg        delay_done = 0;

    always @(posedge clk100) begin
        if (!start_clean) begin
            delay_cnt  <= 0;
            delay_done <= 0;
        end
        else if (!delay_done) begin
            delay_cnt <= delay_cnt + 1;
            if (delay_cnt == 28'd100_000_000)  //1 sec
                delay_done <= 1;
        end
    end
    
    //timer call
    wire [5:0] time_count;
    wire timer_done;
    wire running;
    wire game_over;

    timer timer_inst (
        .clock(clk100),
        .switch(delay_done),        // starts AFTER delay
        .reset(!start_clean),   // reset when switch OFF
        .stopwhenscore(game_over),
        .count(time_count),
        .done(timer_done),
        .running(running)
    );
    
    //scoring +sensor handling
    wire [6:0] score;
    wire [5:0] used;

    multi_sensor_handler score_inst (
        .clock(clk100),
        .reset(!start_clean),   // reset when switch OFF
        .running(running),
        .timer_done(timer_done),
        .sensor_raw(sensor_input),
        .score(score),
        .game_over(game_over),
        .used(used)
    );
    
    //seven seg call
    wire [3:0] time_tens  = time_count / 10;
    wire [3:0] time_ones  = time_count % 10;
    wire [3:0] score_tens = score / 10;
    wire [3:0] score_ones = score % 10;

    seven_seg seg_inst (
        .clock(clk100),
        .score_tens(score_tens),
        .score_ones(score_ones),
        .time_tens(time_tens),
        .time_ones(time_ones),
        .seg(seg),
        .an(an)
    );
    
    //blinking mdule call
    blinking blink_inst (
        .clock(clk100),
        .running(game_over),
        .led(led)
    );
    
    //vga ko call
    top_vga vga_inst (
        .clk100(clk100),

        .start_clean(start_clean),
        .running(running),
        .game_over(game_over),
        .score(score),
        .time_left(time_count),
        .used(used),

        .hsync(hsync),
        .vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

endmodule
