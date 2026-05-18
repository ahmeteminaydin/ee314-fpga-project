`include "game_params.vh"

// Top-level integration: clocks, inputs, game logic, VGA, LEDs, and 7-seg.

module fpga_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,
    input  wire [35:0] GPIO_0,
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B
);
    // SW[0] = reset (active high), SW[1] = debug clock select, SW[2] = hitbox overlay.
    wire reset = SW[0];

    // KEY inputs are active-low on DE1-SoC.
    wire p1_left_raw   = ~KEY[3];
    wire p1_right_raw  = ~KEY[2];
    wire p1_attack_raw = ~KEY[1];
    wire step_raw      = ~KEY[0];

    // External keypad inputs (adjust polarity if needed).
    wire p2_left_raw   = GPIO_0[0];
    wire p2_right_raw  = GPIO_0[1];
    wire p2_attack_raw = GPIO_0[2];

    wire p1_left;
    wire p1_right;
    wire p1_attack;
    wire p2_left;
    wire p2_right;
    wire p2_attack;
    wire step_btn;

    debounce db_p1_left   (.clk(CLOCK_50), .reset(reset), .noisy(p1_left_raw),   .clean(p1_left));
    debounce db_p1_right  (.clk(CLOCK_50), .reset(reset), .noisy(p1_right_raw),  .clean(p1_right));
    debounce db_p1_attack (.clk(CLOCK_50), .reset(reset), .noisy(p1_attack_raw), .clean(p1_attack));
    debounce db_p2_left   (.clk(CLOCK_50), .reset(reset), .noisy(p2_left_raw),   .clean(p2_left));
    debounce db_p2_right  (.clk(CLOCK_50), .reset(reset), .noisy(p2_right_raw),  .clean(p2_right));
    debounce db_p2_attack (.clk(CLOCK_50), .reset(reset), .noisy(p2_attack_raw), .clean(p2_attack));
    debounce db_step      (.clk(CLOCK_50), .reset(reset), .noisy(step_raw),      .clean(step_btn));

    wire p1_attack_edge;
    wire p2_attack_edge;
    wire step_pulse;

    edge_detect ed_p1_attack (.clk(CLOCK_50), .reset(reset), .signal_in(p1_attack), .rising_pulse(p1_attack_edge));
    edge_detect ed_p2_attack (.clk(CLOCK_50), .reset(reset), .signal_in(p2_attack), .rising_pulse(p2_attack_edge));
    edge_detect ed_step      (.clk(CLOCK_50), .reset(reset), .signal_in(step_btn),  .rising_pulse(step_pulse));

    wire clk25;
    wire tick_60hz;
    wire tick_1hz;

    clock_gen clkgen (
        .clk(CLOCK_50),
        .reset(reset),
        .clk25(clk25),
        .tick_60hz(tick_60hz),
        .tick_1hz(tick_1hz)
    );

    wire game_tick = SW[1] ? step_pulse : tick_60hz;
    wire debug_hitbox = SW[2];

    wire [9:0] p1_x;
    wire [9:0] p2_x;
    wire [3:0] p1_state;
    wire [3:0] p2_state;
    wire [1:0] p1_blocks;
    wire [1:0] p2_blocks;
    wire [1:0] p1_rounds;
    wire [1:0] p2_rounds;
    wire [1:0] game_state;
    wire [1:0] countdown_step;
    wire p1_on_left;

    game_logic logic_core (
        .clk(CLOCK_50),
        .reset(reset),
        .tick(game_tick),
        .p1_left(p1_left),
        .p1_right(p1_right),
        .p1_attack(p1_attack),
        .p1_attack_edge(p1_attack_edge),
        .p2_left(p2_left),
        .p2_right(p2_right),
        .p2_attack(p2_attack),
        .p2_attack_edge(p2_attack_edge),
        .p1_x(p1_x),
        .p2_x(p2_x),
        .p1_state(p1_state),
        .p2_state(p2_state),
        .p1_blocks(p1_blocks),
        .p2_blocks(p2_blocks),
        .p1_rounds(p1_rounds),
        .p2_rounds(p2_rounds),
        .game_state(game_state),
        .countdown_step(countdown_step),
        .p1_on_left(p1_on_left)
    );

    wire [9:0] pix_x;
    wire [9:0] pix_y;
    wire       visible;
    wire [7:0] rgb;

    vga_controller vga (
        .clk(clk25),
        .reset(reset),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .x(pix_x),
        .y(pix_y),
        .visible(visible)
    );

    renderer render (
        .pix_x(pix_x),
        .pix_y(pix_y),
        .visible(visible),
        .game_state(game_state),
        .countdown_step(countdown_step),
        .p1_on_left(p1_on_left),
        .p1_x(p1_x),
        .p2_x(p2_x),
        .p1_state(p1_state),
        .p2_state(p2_state),
        .p1_rounds(p1_rounds),
        .p2_rounds(p2_rounds),
        .p1_blocks(p1_blocks),
        .p2_blocks(p2_blocks),
        .debug_hitbox(debug_hitbox),
        .rgb(rgb)
    );

    assign VGA_R = {rgb[7:5], 5'b00000};
    assign VGA_G = {rgb[4:2], 5'b00000};
    assign VGA_B = {rgb[1:0], 6'b000000};

    // 7-segment display text.
    reg [7:0] ch5;
    reg [7:0] ch4;
    reg [7:0] ch3;
    reg [7:0] ch2;
    reg [7:0] ch1;
    reg [7:0] ch0;

    function [7:0] digit_char;
        input [1:0] val;
        begin
            case (val)
                2'd0: digit_char = "0";
                2'd1: digit_char = "1";
                2'd2: digit_char = "2";
                2'd3: digit_char = "3";
                default: digit_char = "0";
            endcase
        end
    endfunction

    always @* begin
        ch5 = " ";
        ch4 = " ";
        ch3 = " ";
        ch2 = " ";
        ch1 = " ";
        ch0 = " ";

        if (game_state == `GS_MENU) begin
            if (p1_on_left) begin
                ch5 = "P"; ch4 = "1";
                ch1 = "P"; ch0 = "2";
            end else begin
                ch5 = "P"; ch4 = "2";
                ch1 = "P"; ch0 = "1";
            end
        end else if (game_state == `GS_PLAY || game_state == `GS_COUNTDOWN) begin
            if (p1_on_left) begin
                ch5 = "P"; ch4 = "1";
                ch1 = "P"; ch0 = "2";
            end else begin
                ch5 = "P"; ch4 = "2";
                ch1 = "P"; ch0 = "1";
            end
            ch3 = "V";
            ch2 = "S";
        end else if (game_state == `GS_GAMEOVER) begin
            if (p1_rounds == `MAX_ROUNDS) begin
                ch5 = "P"; ch4 = "1";
                ch0 = digit_char(p2_rounds);
            end else begin
                ch5 = "P"; ch4 = "2";
                ch0 = digit_char(p1_rounds);
            end
            ch3 = "-";
            ch2 = "3";
            ch1 = "-";
        end
    end

    seg7_display seg7 (
        .ch5(ch5), .ch4(ch4), .ch3(ch3), .ch2(ch2), .ch1(ch1), .ch0(ch0),
        .HEX5(HEX5), .HEX4(HEX4), .HEX3(HEX3), .HEX2(HEX2), .HEX1(HEX1), .HEX0(HEX0)
    );

    wire [1:0] left_rounds = p1_on_left ? p1_rounds : p2_rounds;
    wire [1:0] right_rounds = p1_on_left ? p2_rounds : p1_rounds;
    wire [2:0] left_leds = {left_rounds >= 3, left_rounds >= 2, left_rounds >= 1};
    wire [2:0] right_leds = {right_rounds >= 3, right_rounds >= 2, right_rounds >= 1};
    wire [9:0] led_play = {left_leds, 4'b0000, right_leds};

    reg blink_on;
    always @(posedge CLOCK_50) begin
        if (reset) begin
            blink_on <= 1'b0;
        end else if (tick_1hz) begin
            blink_on <= ~blink_on;
        end
    end

    assign LEDR = (game_state == `GS_GAMEOVER) ? (blink_on ? 10'b1111111111 : 10'b0000000000) :
                  (game_state == `GS_PLAY || game_state == `GS_COUNTDOWN) ? led_play :
                  10'b0000000000;
endmodule
