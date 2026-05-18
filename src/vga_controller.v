module vga_controller (
    input  wire clk,
    input  wire reset,
    output reg  hsync,
    output reg  vsync,
    output reg  [9:0] x,
    output reg  [9:0] y,
    output reg  visible
);
    localparam integer H_VISIBLE = 640;
    localparam integer H_FRONT   = 16;
    localparam integer H_SYNC    = 96;
    localparam integer H_BACK    = 48;
    localparam integer H_TOTAL   = 800;

    localparam integer V_VISIBLE = 480;
    localparam integer V_FRONT   = 10;
    localparam integer V_SYNC    = 2;
    localparam integer V_BACK    = 33;
    localparam integer V_TOTAL   = 525;

    reg [9:0] h_count;
    reg [9:0] v_count;

    always @(posedge clk) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 10'd0;
                end else begin
                    v_count <= v_count + 1'b1;
                end
            end else begin
                h_count <= h_count + 1'b1;
            end
        end
    end

    always @* begin
        x = h_count;
        y = v_count;
        visible = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);
        hsync = ~((h_count >= H_VISIBLE + H_FRONT) && (h_count < H_VISIBLE + H_FRONT + H_SYNC));
        vsync = ~((v_count >= V_VISIBLE + V_FRONT) && (v_count < V_VISIBLE + V_FRONT + V_SYNC));
    end
endmodule
