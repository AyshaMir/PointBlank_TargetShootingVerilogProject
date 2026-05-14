module vga_sync ( //Count pixels and lines at 25 MHz and generate hsync, vsync, (x,y), and video_on for 640×480 VGA.
    input  wire clk25,
    output wire hsync,
    output wire vsync,
    output wire video_on,
    output wire [9:0] x,
    output wire [9:0] y
);

    // 640x480 @ 60 Hz //labse leen
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;
    
    // the whole 799 tak and 0 then 1 ....
    always @(posedge clk25) begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end
    end

    assign hsync = ~(
        h_count >= H_VISIBLE + H_FRONT &&
        h_count <  H_VISIBLE + H_FRONT + H_SYNC
    );

    assign vsync = ~(
        v_count >= V_VISIBLE + V_FRONT &&
        v_count <  V_VISIBLE + V_FRONT + V_SYNC
    );

    assign video_on = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    assign x = h_count;
    assign y = v_count;

endmodule
