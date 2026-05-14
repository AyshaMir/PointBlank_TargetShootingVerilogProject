module string_renderer #( //Given the current pixel (pixel_x, pixel_y), 
//this module tells you whether that pixel should be part of a rendered text string, using a font ROM and scaling.
//It does not output color, only a boolean flag: text_on.
    parameter integer TEXT_LENGTH = 8,
    parameter integer SCALE = 4 //must be power of 2
)(
    input  wire        clk,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire [9:0]  X_POS,
    input  wire [9:0]  Y_POS,
    input  wire [8*TEXT_LENGTH-1:0] text_string,
    output reg         text_on
);

    localparam CHAR_W = 8;
    localparam CHAR_H = 16;
    localparam SCALE_SHIFT = $clog2(SCALE); //How many bits to shift right to divide by SCALE

    // Local coordinates
    wire [9:0] lx = pixel_x - X_POS;
    wire [9:0] ly = pixel_y - Y_POS;
    //Is this pixel inside the bounding box of the full text?
    wire inside =
        lx < (CHAR_W * SCALE * TEXT_LENGTH) &&
        ly < (CHAR_H * SCALE);

    // Font-space coordinates
    wire [9:0] font_x = lx >> SCALE_SHIFT;   // 0..(8*TEXT_LENGTH-1)
    wire [3:0] font_y = ly >> SCALE_SHIFT;   // 0..15

    wire [9:0] char_index = font_x >> 3;     // /8
    wire [2:0] bit_x      = font_x[2:0];     // %8

    // Character fetch
    integer idx;
    reg [7:0] char_code;

    always @(*) begin
        if (!inside)
            char_code = 8'd32;
        else begin
            idx = TEXT_LENGTH - 1 - char_index;
            char_code = text_string[idx*8 +: 8];
        end
    end

    // FONT ROM (1-cycle latency)
    wire [10:0] rom_addr = { char_code[6:0], font_y };
    wire [7:0] font_row;

    font_rom FONT_ROM (
        .clk(clk),
        .addr(rom_addr),
        .data(font_row)
    );

    // PIPELINE ALIGNMENT
    reg inside_d;
    reg [2:0] bit_x_d;

    always @(posedge clk) begin
        inside_d <= inside;
        bit_x_d  <= bit_x;
    end
    // FINAL PIXEL
    always @(posedge clk) begin
        if (inside_d && font_row[7 - bit_x_d])
            text_on <= 1'b1;
        else
            text_on <= 1'b0;
    end

endmodule
