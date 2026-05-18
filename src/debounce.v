module debounce #(
    parameter integer COUNT_MAX = 500000,
    parameter integer COUNT_WIDTH = 20
) (
    input  wire clk,
    input  wire reset,
    input  wire noisy,
    output reg  clean
);
    reg [COUNT_WIDTH-1:0] count;
    reg stable_state;

    always @(posedge clk) begin
        if (reset) begin
            clean <= 1'b0;
            count <= {COUNT_WIDTH{1'b0}};
            stable_state <= 1'b0;
        end else begin
            if (noisy != stable_state) begin
                stable_state <= noisy;
                count <= {COUNT_WIDTH{1'b0}};
            end else if (count < COUNT_MAX) begin
                count <= count + 1'b1;
            end else begin
                clean <= stable_state;
            end
        end
    end
endmodule
