module clock_gen #(
    parameter integer CLK_HZ = 50000000
) (
    input  wire clk,
    input  wire reset,
    output reg  clk25,
    output reg  tick_60hz,
    output reg  tick_1hz
);
    localparam integer COUNT_60HZ = CLK_HZ / 60;
    localparam integer COUNT_1HZ  = CLK_HZ / 1;

    reg [31:0] cnt60;
    reg [31:0] cnt1;

    always @(posedge clk) begin
        if (reset) begin
            clk25     <= 1'b0;
            cnt60     <= 32'd0;
            cnt1      <= 32'd0;
            tick_60hz <= 1'b0;
            tick_1hz  <= 1'b0;
        end else begin
            clk25 <= ~clk25;

            if (cnt60 == COUNT_60HZ - 1) begin
                cnt60     <= 32'd0;
                tick_60hz <= 1'b1;
            end else begin
                cnt60     <= cnt60 + 1'b1;
                tick_60hz <= 1'b0;
            end

            if (cnt1 == COUNT_1HZ - 1) begin
                cnt1     <= 32'd0;
                tick_1hz <= 1'b1;
            end else begin
                cnt1     <= cnt1 + 1'b1;
                tick_1hz <= 1'b0;
            end
        end
    end
endmodule
