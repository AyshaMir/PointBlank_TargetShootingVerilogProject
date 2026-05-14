module sprite_bram #( //Given a pixel (px, py), tell the system (1) whether this pixel belongs to a sprite, 
//(2) what BRAM address to read, and 
//(3) one clock later, whether to draw the sprite pixel and what color it is.
    parameter W = 64, //default// override hongi
    parameter H = 64
)(
    input  wire        clk,
    //x and y pixel
    input  wire [9:0]  px,
    input  wire [9:0]  py,
    //Top-left position of the sprite on screen
    input  wire [9:0]  sx,
    input  wire [9:0]  sy,
    output wire        req, //This pixel belongs to me - please read BRAM
    output wire [16:0] addr,
    input  wire [7:0]  bram_data, //Pixel color coming back from sprite BRAM
    output reg         active,
    output reg  [7:0]  color
);

    //Is (px, py) inside the rectangle starting at (sx, sy) with width W and height H?
    wire inside_now =
        (px >= sx) && (px < sx + W) &&
        (py >= sy) && (py < sy + H);

    assign req  = inside_now; //If the pixel is inside the sprite right now, ask for BRAM data.
    assign addr = (py - sy) * W + (px - sx); //onvert (px, py) into a linear index inside the sprite image.
    
    //inside_now is true this cycle bram_data arrives next cycle
    reg inside_d;

    always @(posedge clk) begin
        inside_d <= inside_now; //inside_d corresponds to the same pixel as bram_data
        //the pixel was inside the sprite (1 cycle ago) nd the sprite pixel is not transparent then mark sprite as active n output its color
        if (inside_d && bram_data != 8'h00) begin
            active <= 1'b1;
            color  <= bram_data;
        end else begin
            active <= 1'b0;
            color  <= 8'h00;
        end
    end

endmodule
