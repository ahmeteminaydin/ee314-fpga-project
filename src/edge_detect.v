module edge_detect (
    input  wire clk,
    input  wire reset,
    input  wire signal_in,
    output reg  rising_pulse
);
    reg prev;

    always @(posedge clk) begin
        if (reset) begin
            prev <= 1'b0;
            rising_pulse <= 1'b0;
        end else begin
            rising_pulse <= signal_in & ~prev;
            prev <= signal_in;
        end
    end
endmodule
