`timescale 1ns / 1ps
module top_vga (
    input  wire        clk100,
    //game signals
    input  wire        start_clean,   // startgame
    input  wire        running,
    input  wire        game_over,
    input  wire [6:0]  score,
    input  wire [5:0]  time_left,
    input  wire [5:0]  used,           // cans hit
    //vga signals
    output wire        hsync,
    output wire        vsync,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b
);
    //clk_div
    reg [1:0] div = 0; //div 2 bit counter
    always @(posedge clk100) div <= div + 1;
    wire clk25 = div[1]; //div[1] toggles at 100/4 mhz = 25mhz

    // VGAsync instantiate
    wire video_on;
    wire [9:0] x, y;
    vga_sync sync (
        .clk25(clk25),
        .hsync(hsync),
        .vsync(vsync),
        .video_on(video_on), //visible area 1 when showing
        .x(x), // x and y coordinates
        .y(y)
    );
    
    //1 cycle pipeline
    //On each clk25 tick, vga_sync gives a new pixel coordinate
    //BRAM is usually synchronous read, You put an address in this clock, You get the pixel (douta) next clock.
    //So BRAM has a 1 clock delay.
    //x,y = where the counters are right now
    //x_d,y_d = the pixel we are actually drawing right now
    reg [9:0] x_d, y_d;
    reg video_on_d;

    always @(posedge clk25) begin
        x_d <= x;
        y_d <= y;
        video_on_d <= video_on;
    end
    
    //defining the screens
    localparam SCREEN_START = 2'd1;
    localparam SCREEN_PLAY  = 2'd2;
    localparam SCREEN_OVER  = 2'd3;

    reg [1:0] screen;
    always @(*) begin
        if (game_over) //agr game over hai to end screen
            screen = SCREEN_OVER;
        else if (start_clean) //warna agr start hai to play wali
            screen = SCREEN_PLAY;
        else
            screen = SCREEN_START; //agr dono nhi hain to start screen
    end
    
    //bg backgrounds
    localparam YELLOW_LIGHT = 8'b11110100;
    localparam YELLOW_DARK  = 8'b11010000;
    
    //x_d is your current pixel x-coordinate (0 to 639). It's a 10-bit number.
    wire stripe_sel = x_d[6]; //Uses one bit of x_d to alternate colors every 64 pixels ? vertical stripe effect.
    wire [7:0] bg_color = stripe_sel ? YELLOW_DARK : YELLOW_LIGHT;
    
    //bunting instatiation
    wire [7:0] bunting_pixel;
    reg  [16:0] bunting_addr; //what BRAM address to read

    bunting_bram bunting_rom (
        .clka(clk25),
        .addra(bunting_addr),
        .douta(bunting_pixel)
    );

    wire bunting_req, bunting_on;
    wire [7:0] bunting_col;
    wire [16:0] bunting_addr_i;

    sprite_bram #(.W(640), .H(135)) bunting (
        .clk(clk25),
        .px(x_d), .py(y_d),
        .sx(0), .sy(0),
        .req(bunting_req), // req is pixel is inside sprite
        .addr(bunting_addr_i),
        .bram_data(bunting_pixel),
        .active(bunting_on), //shld draw
        .color(bunting_col) //color
    );
    //If bunting_req is 1, load bunting_addr with bunting_addr_i
    always @(posedge clk25)
        bunting_addr <= bunting_req ? bunting_addr_i : 0;
        
    //shelf instantiate
    wire [7:0] shelf_pixel;
    reg  [15:0] shelf_addr;

    shelf_bram shelf_rom (
        .clka(clk25),
        .addra(shelf_addr),
        .douta(shelf_pixel)
    );

    wire [1:0] shelf_req, shelf_on;
    wire [7:0] shelf_col [0:1];
    wire [15:0] shelf_addr_i [0:1];

    sprite_bram #(.W(512), .H(96)) shelf1 (
        .clk(clk25),
        .px(x_d), .py(y_d),
        .sx(64), .sy(200),
        .req(shelf_req[0]),
        .addr(shelf_addr_i[0]),
        .bram_data(shelf_pixel),
        .active(shelf_on[0]),
        .color(shelf_col[0])
    );

    sprite_bram #(.W(512), .H(96)) shelf2 (
        .clk(clk25),
        .px(x_d), .py(y_d),
        .sx(64), .sy(350),
        .req(shelf_req[1]),
        .addr(shelf_addr_i[1]),
        .bram_data(shelf_pixel),
        .active(shelf_on[1]),
        .color(shelf_col[1])
    );
    
    //Set shelf_addr to shelf_addr_i[0] if shelf_req[0] is true, otherwise set it to shelf_addr_i[1] if shelf_req[1] is true, otherwise set it to 0.
    always @(posedge clk25)
        shelf_addr <= shelf_req[0] ? shelf_addr_i[0] :
                      shelf_req[1] ? shelf_addr_i[1] : 0;
                      
                      
    //can instantiation
    wire [7:0] can_pixel;
    reg  [15:0] can_addr;

    can_bram can_rom (
        .clka(clk25),
        .addra(can_addr),
        .douta(can_pixel)
    );

    wire [9:0] can_x [0:5];
    wire [9:0] can_y [0:5];
    //can position
    assign can_x[0]=72;   assign can_y[0]=140;
    assign can_x[1]=256;  assign can_y[1]=140;
    assign can_x[2]=440;  assign can_y[2]=140;
    assign can_x[3]=72;   assign can_y[3]=290;
    assign can_x[4]=256;  assign can_y[4]=290;
    assign can_x[5]=440;  assign can_y[5]=290;

    wire [5:0] can_req, can_on;
    wire [7:0] can_col [0:5];
    wire [15:0] can_addr_i [0:5];
    //Create six independent 96×96 sprite checkers, all sharing the same can image, each placed at a different position,
    //and give me per-can signals telling me when to fetch and draw that can's pixels
    genvar c;
    generate
        for (c = 0; c < 6; c = c + 1) begin : cans //craete six copies
            sprite_bram #(.W(96), .H(96)) can_i (
                .clk(clk25),
                .px(x_d), .py(y_d),
                .sx(can_x[c]), .sy(can_y[c]),
                .req(can_req[c]), //output whether pixel inside cth can
                .addr(can_addr_i[c]), //the address for the pixel
                .bram_data(can_pixel), 
                .active(can_on[c]), //whether it hld be drawn 
                .color(can_col[c]) // its color
            );
        end
    endgenerate

    integer i;
    always @(posedge clk25) begin
        can_addr <= 0;
        for (i = 0; i < 6; i = i + 1)
            if (can_req[i])
                can_addr <= can_addr_i[i];
    end
    
   //asci conversion for timer and score
   //split numbers into digits and then convert to ascii
    wire [3:0] score_tens = score / 10;
    wire [3:0] score_ones = score % 10;
    
    wire [3:0] time_tens  = time_left / 10;
    wire [3:0] time_ones  = time_left % 10;
    
    wire [7:0] score_tens_char = 8'd48 + score_tens;
    wire [7:0] score_ones_char = 8'd48 + score_ones;
    
    wire [7:0] time_tens_char  = 8'd48 + time_tens;
    wire [7:0] time_ones_char  = 8'd48 + time_ones;
    
    wire [8*7-1:0] time_string; //7 chracaters * 8 bits
    assign time_string = {
        8'd84, 8'd73, 8'd77, 8'd69, 8'd58,
        time_tens_char,
        time_ones_char
    };
    
    wire [8*8-1:0] score_string;
    assign score_string = {
        8'd83, 8'd67, 8'd79, 8'd82,
        8'd69, 8'd58,
        score_tens_char,
        score_ones_char
    };
    
    //text instantiation
    wire welcome_on, point_on, blank_on, game_on, over_on;

    function automatic [9:0] center_x; //funtion center_x gives x coordinate
        input integer len, scale; //func take len and how big it is to be
        begin
            center_x = (640 - (len * 8 * scale)) / 2; //coentiring formula
        end
    endfunction

    string_renderer #(.TEXT_LENGTH(10), .SCALE(4)) welcome_txt (
        .clk(clk25), .pixel_x(x_d), .pixel_y(y_d),
        .X_POS(center_x(10,4)), .Y_POS(150),
        .text_string({8'd87,8'd69,8'd76,8'd67,8'd79,8'd77,8'd69,8'd32,8'd84,8'd79}),
        .text_on(welcome_on)
    );

    string_renderer #(.TEXT_LENGTH(5), .SCALE(8)) point_txt (
        .clk(clk25), .pixel_x(x_d), .pixel_y(y_d),
        .X_POS(center_x(5,8)), .Y_POS(210),
        .text_string({8'd80,8'd79,8'd73,8'd78,8'd84}),
        .text_on(point_on)
    );

    string_renderer #(.TEXT_LENGTH(6), .SCALE(8)) blank_txt (
        .clk(clk25), .pixel_x(x_d), .pixel_y(y_d),
        .X_POS(center_x(6,8)), .Y_POS(310),
        .text_string({8'd66,8'd76,8'd65,8'd78,8'd75,8'd33}),
        .text_on(blank_on)
    );

    string_renderer #(.TEXT_LENGTH(4), .SCALE(8)) game_txt (
        .clk(clk25), .pixel_x(x_d), .pixel_y(y_d),
        .X_POS(center_x(4,8)), .Y_POS(150),
        .text_string({8'd71,8'd65,8'd77,8'd69}),
        .text_on(game_on)
    );

    string_renderer #(.TEXT_LENGTH(5), .SCALE(8)) over_txt (
        .clk(clk25), .pixel_x(x_d), .pixel_y(y_d),
        .X_POS(center_x(5,8)), .Y_POS(240),
        .text_string({8'd79,8'd86,8'd69,8'd82,8'd33}),
        .text_on(over_on)
    );
    wire score_over_on;
    
    string_renderer #(
        .TEXT_LENGTH(8),   
        .SCALE(4)
    ) score_over_txt (
        .clk(clk25),
        .pixel_x(x_d),
        .pixel_y(y_d),
        .X_POS(center_x(8,4)),
        .Y_POS(330),
        .text_string(score_string),
        .text_on(score_over_on)
    );
    
    wire time_on;

    string_renderer #(
        .TEXT_LENGTH(7),
        .SCALE(2)
    ) time_txt (
        .clk(clk25),
        .pixel_x(x_d),
        .pixel_y(y_d),
        .X_POS(20),
        .Y_POS(440),
        .text_string(time_string),
        .text_on(time_on)
    );
    
    wire score_on;
    
    string_renderer #(
        .TEXT_LENGTH(8),
        .SCALE(2)
    ) score_txt (
        .clk(clk25),
        .pixel_x(x_d),
        .pixel_y(y_d),
        .X_POS(640 - (8 * 8 * 2) - 20),
        .Y_POS(440),
        .text_string(score_string),
        .text_on(score_on)
    );
    
    
//the rendering part 
    reg [7:0] rgb;
    integer k;
    
    always @(posedge clk25) begin //every clk cycle it asks ab kya color karna
        if (!video_on_d) //so agr bahar hai screen se to black
            rgb <= 8'h00;
        else begin
            rgb <= bg_color; // warna bg strpes
            if (bunting_on) //agr bunting upar se on ati to wo draw karo
                rgb <= bunting_col;
            if (screen == SCREEN_START &&
                (welcome_on || point_on || blank_on)) //start screen hai to ye 3 text iin red karo
                rgb <= 8'b1110_0000; // red
            else if (screen == SCREEN_OVER) begin // over screen payt uska text 
                if (game_on || over_on)
                    rgb <= 8'b1110_0000; // red
                else if (score_over_on) //or score ka text
                    rgb <= 8'b1110_0000; // red
            end
            else if (screen == SCREEN_PLAY) begin // agr play screen hai to
                if (time_on || score_on) //timer and score  text
                    rgb <= 8'b1110_0000; // red
                else begin
                    for (k = 0; k < 2; k = k + 1) //for ech shelf upar wo draw akro
                        if (shelf_on[k])
                            rgb <= shelf_col[k];
                    for (k = 0; k < 6; k = k + 1) //phir uskay upar cans or wo hit nhi hona chiaye 
                        if (can_on[k] && !used[k])
                            rgb <= can_col[k];
                end
            end
        end
    end
    assign vga_r = {rgb[7:5], 1'b0};
    assign vga_g = {rgb[4:2], 1'b0};
    assign vga_b = {rgb[1:0], 2'b00};

endmodule
