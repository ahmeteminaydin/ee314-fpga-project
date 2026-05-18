module seg7_display (
    input  wire [7:0] ch5,
    input  wire [7:0] ch4,
    input  wire [7:0] ch3,
    input  wire [7:0] ch2,
    input  wire [7:0] ch1,
    input  wire [7:0] ch0,
    output wire [6:0] HEX5,
    output wire [6:0] HEX4,
    output wire [6:0] HEX3,
    output wire [6:0] HEX2,
    output wire [6:0] HEX1,
    output wire [6:0] HEX0
);
    function [6:0] seg7_encode;
        input [7:0] ch;
        begin
            case (ch)
                "0": seg7_encode = 7'b1000000;
                "1": seg7_encode = 7'b1111001;
                "2": seg7_encode = 7'b0100100;
                "3": seg7_encode = 7'b0110000;
                "4": seg7_encode = 7'b0011001;
                "5": seg7_encode = 7'b0010010;
                "6": seg7_encode = 7'b0000010;
                "7": seg7_encode = 7'b1111000;
                "8": seg7_encode = 7'b0000000;
                "9": seg7_encode = 7'b0010000;
                "P": seg7_encode = 7'b0011000;
                "V": seg7_encode = 7'b1100010; // Approximate V as U
                "S": seg7_encode = 7'b0010010;
                "-": seg7_encode = 7'b1111110;
                " ": seg7_encode = 7'b1111111;
                default: seg7_encode = 7'b1111111;
            endcase
        end
    endfunction

    assign HEX5 = seg7_encode(ch5);
    assign HEX4 = seg7_encode(ch4);
    assign HEX3 = seg7_encode(ch3);
    assign HEX2 = seg7_encode(ch2);
    assign HEX1 = seg7_encode(ch1);
    assign HEX0 = seg7_encode(ch0);
endmodule
