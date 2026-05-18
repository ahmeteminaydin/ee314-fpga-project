`include "game_params.vh"

// VGA renderer: draws background, characters, hitboxes, and HUD text.

module renderer (
    input  wire [9:0] pix_x,
    input  wire [9:0] pix_y,
    input  wire       visible,
    input  wire [1:0] game_state,
    input  wire [1:0] countdown_step,
    input  wire       p1_on_left,
    input  wire [9:0] p1_x,
    input  wire [9:0] p2_x,
    input  wire [3:0] p1_state,
    input  wire [3:0] p2_state,
    input  wire [1:0] p1_rounds,
    input  wire [1:0] p2_rounds,
    input  wire [1:0] p1_blocks,
    input  wire [1:0] p2_blocks,
    input  wire       debug_hitbox,
    output reg  [7:0] rgb
);
    localparam integer CHAR_TOP = `GROUND_Y - `CHAR_H;

    wire [1:0] left_rounds  = p1_on_left ? p1_rounds : p2_rounds;
    wire [1:0] right_rounds = p1_on_left ? p2_rounds : p1_rounds;
    wire [1:0] left_blocks  = p1_on_left ? p1_blocks : p2_blocks;
    wire [1:0] right_blocks = p1_on_left ? p2_blocks : p1_blocks;

    reg [2:0] bg_r;
    reg [2:0] bg_g;
    reg [1:0] bg_b;
    reg p1_body;
    reg p2_body;
    reg p1_hitbox;
    reg p2_hitbox;
    reg p1_hurtbox;
    reg p2_hurtbox;
    integer p1_hit_x0;
    integer p1_hit_x1;
    integer p2_hit_x0;
    integer p2_hit_x1;
    integer p1_hurt_x0;
    integer p1_hurt_x1;
    integer p2_hurt_x0;
    integer p2_hurt_x1;
    integer hit_y0;
    integer hit_y1;
    integer hurt_y0;
    integer hurt_y1;
    integer p1_range;
    integer p2_range;
    integer p1_hurt_ext;
    integer p2_hurt_ext;
    reg text_on;
    reg [7:0] text_color;

    function [7:0] rgb332;
        input [2:0] r;
        input [2:0] g;
        input [1:0] b;
        begin
            rgb332 = {r, g, b};
        end
    endfunction

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

    function [7:0] font_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            case (ch)
                "0": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h46;
                    3'd3: font_row = 8'h4A;
                    3'd4: font_row = 8'h52;
                    3'd5: font_row = 8'h62;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "1": case (row)
                    3'd0: font_row = 8'h18;
                    3'd1: font_row = 8'h28;
                    3'd2: font_row = 8'h08;
                    3'd3: font_row = 8'h08;
                    3'd4: font_row = 8'h08;
                    3'd5: font_row = 8'h08;
                    3'd6: font_row = 8'h3E;
                    default: font_row = 8'h00;
                endcase
                "2": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h02;
                    3'd3: font_row = 8'h0C;
                    3'd4: font_row = 8'h30;
                    3'd5: font_row = 8'h40;
                    3'd6: font_row = 8'h7E;
                    default: font_row = 8'h00;
                endcase
                "3": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h02;
                    3'd3: font_row = 8'h1C;
                    3'd4: font_row = 8'h02;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "A": case (row)
                    3'd0: font_row = 8'h18;
                    3'd1: font_row = 8'h24;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h7E;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h42;
                    default: font_row = 8'h00;
                endcase
                "E": case (row)
                    3'd0: font_row = 8'h7E;
                    3'd1: font_row = 8'h40;
                    3'd2: font_row = 8'h40;
                    3'd3: font_row = 8'h7C;
                    3'd4: font_row = 8'h40;
                    3'd5: font_row = 8'h40;
                    3'd6: font_row = 8'h7E;
                    default: font_row = 8'h00;
                endcase
                "G": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h40;
                    3'd3: font_row = 8'h4E;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "I": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h18;
                    3'd2: font_row = 8'h18;
                    3'd3: font_row = 8'h18;
                    3'd4: font_row = 8'h18;
                    3'd5: font_row = 8'h18;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "M": case (row)
                    3'd0: font_row = 8'h42;
                    3'd1: font_row = 8'h66;
                    3'd2: font_row = 8'h5A;
                    3'd3: font_row = 8'h42;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h42;
                    default: font_row = 8'h00;
                endcase
                "N": case (row)
                    3'd0: font_row = 8'h42;
                    3'd1: font_row = 8'h62;
                    3'd2: font_row = 8'h52;
                    3'd3: font_row = 8'h4A;
                    3'd4: font_row = 8'h46;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h42;
                    default: font_row = 8'h00;
                endcase
                "O": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h42;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "P": case (row)
                    3'd0: font_row = 8'h7C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h7C;
                    3'd4: font_row = 8'h40;
                    3'd5: font_row = 8'h40;
                    3'd6: font_row = 8'h40;
                    default: font_row = 8'h00;
                endcase
                "R": case (row)
                    3'd0: font_row = 8'h7C;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h7C;
                    3'd4: font_row = 8'h48;
                    3'd5: font_row = 8'h44;
                    3'd6: font_row = 8'h42;
                    default: font_row = 8'h00;
                endcase
                "S": case (row)
                    3'd0: font_row = 8'h3C;
                    3'd1: font_row = 8'h40;
                    3'd2: font_row = 8'h40;
                    3'd3: font_row = 8'h3C;
                    3'd4: font_row = 8'h02;
                    3'd5: font_row = 8'h02;
                    3'd6: font_row = 8'h7C;
                    default: font_row = 8'h00;
                endcase
                "T": case (row)
                    3'd0: font_row = 8'h7E;
                    3'd1: font_row = 8'h18;
                    3'd2: font_row = 8'h18;
                    3'd3: font_row = 8'h18;
                    3'd4: font_row = 8'h18;
                    3'd5: font_row = 8'h18;
                    3'd6: font_row = 8'h18;
                    default: font_row = 8'h00;
                endcase
                "U": case (row)
                    3'd0: font_row = 8'h42;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h42;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h42;
                    3'd6: font_row = 8'h3C;
                    default: font_row = 8'h00;
                endcase
                "V": case (row)
                    3'd0: font_row = 8'h42;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h42;
                    3'd4: font_row = 8'h42;
                    3'd5: font_row = 8'h24;
                    3'd6: font_row = 8'h18;
                    default: font_row = 8'h00;
                endcase
                "W": case (row)
                    3'd0: font_row = 8'h42;
                    3'd1: font_row = 8'h42;
                    3'd2: font_row = 8'h42;
                    3'd3: font_row = 8'h5A;
                    3'd4: font_row = 8'h5A;
                    3'd5: font_row = 8'h66;
                    3'd6: font_row = 8'h42;
                    default: font_row = 8'h00;
                endcase
                default: font_row = 8'h00;
            endcase
        end
    endfunction

    function draw_char;
        input [9:0] x;
        input [9:0] y;
        input [9:0] x0;
        input [9:0] y0;
        input [7:0] ch;
        input integer scale;
        integer row;
        integer col;
        reg [7:0] row_bits;
        begin
            if (x < x0 || x >= x0 + 8*scale || y < y0 || y >= y0 + 8*scale) begin
                draw_char = 1'b0;
            end else begin
                row = (y - y0) / scale;
                col = (x - x0) / scale;
                row_bits = font_row(ch, row[2:0]);
                draw_char = row_bits[7-col];
            end
        end
    endfunction

    function [7:0] player_color;
        input [3:0] st;
        input is_p1;
        begin
            case (st)
                `ST_IDLE:      player_color = is_p1 ? rgb332(3'd1, 3'd2, 2'd3) : rgb332(3'd1, 3'd3, 2'd1);
                `ST_FWD:       player_color = is_p1 ? rgb332(3'd1, 3'd3, 2'd3) : rgb332(3'd2, 3'd3, 2'd1);
                `ST_BACK:      player_color = is_p1 ? rgb332(3'd0, 3'd2, 2'd3) : rgb332(3'd0, 3'd2, 2'd1);
                `ST_ATK_START: player_color = rgb332(3'd3, 3'd2, 2'd0);
                `ST_ATK_ACTIVE:player_color = rgb332(3'd3, 3'd0, 2'd0);
                `ST_ATK_REC:   player_color = rgb332(3'd2, 3'd1, 2'd0);
                `ST_SPC_START: player_color = rgb332(3'd2, 3'd0, 2'd2);
                `ST_SPC_ACTIVE:player_color = rgb332(3'd3, 3'd0, 2'd3);
                `ST_SPC_REC:   player_color = rgb332(3'd1, 3'd0, 2'd2);
                `ST_HITSTUN:   player_color = rgb332(3'd3, 3'd3, 2'd0);
                `ST_BLOCKSTUN: player_color = rgb332(3'd0, 3'd3, 2'd3);
                `ST_GUARD:     player_color = rgb332(3'd3, 3'd0, 2'd3);
                default:       player_color = rgb332(3'd1, 3'd1, 2'd1);
            endcase
        end
    endfunction

    always @* begin
        if (!visible) begin
            rgb = 8'h00;
        end else begin
            bg_r = 3'd1 + pix_y[7:6];
            bg_g = 3'd2 + pix_x[7:6];
            bg_b = 2'd1 + pix_y[7];
            rgb = rgb332(bg_r, bg_g, bg_b);

            if (pix_y >= `GROUND_Y) begin
                rgb = rgb332(3'd2, 3'd1, 2'd0);
            end

            p1_body = (pix_x >= p1_x) && (pix_x < p1_x + `CHAR_W) &&
                      (pix_y >= CHAR_TOP) && (pix_y < CHAR_TOP + `CHAR_H);
            p2_body = (pix_x >= p2_x) && (pix_x < p2_x + `CHAR_W) &&
                      (pix_y >= CHAR_TOP) && (pix_y < CHAR_TOP + `CHAR_H);

            if (p1_body) begin
                rgb = player_color(p1_state, 1'b1);
            end
            if (p2_body) begin
                rgb = player_color(p2_state, 1'b0);
            end

            hit_y0 = CHAR_TOP + `HITBOX_Y_OFFSET;
            hit_y1 = hit_y0 + `HITBOX_HEIGHT - 1;
            hurt_y0 = CHAR_TOP;
            hurt_y1 = CHAR_TOP + `CHAR_H - 1;

            p1_range = (p1_state == `ST_SPC_ACTIVE) ? `SPECIAL_RANGE : `BASIC_RANGE;
            p2_range = (p2_state == `ST_SPC_ACTIVE) ? `SPECIAL_RANGE : `BASIC_RANGE;
            p1_hurt_ext = (p1_state == `ST_ATK_REC) ? `BASIC_RANGE :
                          (p1_state == `ST_SPC_REC) ? `SPECIAL_RANGE : 0;
            p2_hurt_ext = (p2_state == `ST_ATK_REC) ? `BASIC_RANGE :
                          (p2_state == `ST_SPC_REC) ? `SPECIAL_RANGE : 0;

            if (p1_on_left) begin
                p1_hit_x0 = p1_x + `CHAR_W;
                p1_hit_x1 = p1_x + `CHAR_W + p1_range - 1;
                p1_hurt_x0 = p1_x;
                p1_hurt_x1 = p1_x + `CHAR_W + p1_hurt_ext - 1;

                p2_hit_x1 = p2_x - 1;
                p2_hit_x0 = p2_x - p2_range;
                p2_hurt_x1 = p2_x + `CHAR_W - 1;
                p2_hurt_x0 = p2_x - p2_hurt_ext;
            end else begin
                p1_hit_x1 = p1_x - 1;
                p1_hit_x0 = p1_x - p1_range;
                p1_hurt_x1 = p1_x + `CHAR_W - 1;
                p1_hurt_x0 = p1_x - p1_hurt_ext;

                p2_hit_x0 = p2_x + `CHAR_W;
                p2_hit_x1 = p2_x + `CHAR_W + p2_range - 1;
                p2_hurt_x0 = p2_x;
                p2_hurt_x1 = p2_x + `CHAR_W + p2_hurt_ext - 1;
            end

            p1_hitbox = (p1_state == `ST_ATK_ACTIVE || p1_state == `ST_SPC_ACTIVE) &&
                        (pix_x >= p1_hit_x0) && (pix_x <= p1_hit_x1) &&
                        (pix_y >= hit_y0) && (pix_y <= hit_y1);
            p2_hitbox = (p2_state == `ST_ATK_ACTIVE || p2_state == `ST_SPC_ACTIVE) &&
                        (pix_x >= p2_hit_x0) && (pix_x <= p2_hit_x1) &&
                        (pix_y >= hit_y0) && (pix_y <= hit_y1);

            p1_hurtbox = (pix_x >= p1_hurt_x0) && (pix_x <= p1_hurt_x1) &&
                         (pix_y >= hurt_y0) && (pix_y <= hurt_y1);
            p2_hurtbox = (pix_x >= p2_hurt_x0) && (pix_x <= p2_hurt_x1) &&
                         (pix_y >= hurt_y0) && (pix_y <= hurt_y1);

            if (debug_hitbox) begin
                if (p1_hurtbox || p2_hurtbox) begin
                    rgb = rgb332(3'd3, 3'd3, 2'd0);
                end
                if (p1_hitbox || p2_hitbox) begin
                    rgb = rgb332(3'd3, 3'd0, 2'd0);
                end
            end

            text_on = 1'b0;
            text_color = rgb332(3'd3, 3'd3, 2'd3);

            if (game_state == `GS_MENU) begin
                if (draw_char(pix_x, pix_y, 280, 40, "M", 2) ||
                    draw_char(pix_x, pix_y, 296, 40, "E", 2) ||
                    draw_char(pix_x, pix_y, 312, 40, "N", 2) ||
                    draw_char(pix_x, pix_y, 328, 40, "U", 2)) begin
                    text_on = 1'b1;
                end

                if (p1_on_left) begin
                    if (draw_char(pix_x, pix_y, 80, 120, "P", 2) ||
                        draw_char(pix_x, pix_y, 96, 120, "1", 2)) begin
                        text_on = 1'b1;
                    end
                    if (draw_char(pix_x, pix_y, 480, 120, "P", 2) ||
                        draw_char(pix_x, pix_y, 496, 120, "2", 2)) begin
                        text_on = 1'b1;
                    end
                end else begin
                    if (draw_char(pix_x, pix_y, 80, 120, "P", 2) ||
                        draw_char(pix_x, pix_y, 96, 120, "2", 2)) begin
                        text_on = 1'b1;
                    end
                    if (draw_char(pix_x, pix_y, 480, 120, "P", 2) ||
                        draw_char(pix_x, pix_y, 496, 120, "1", 2)) begin
                        text_on = 1'b1;
                    end
                end
            end

            if (game_state == `GS_COUNTDOWN) begin
                if (countdown_step != 0) begin
                    if (draw_char(pix_x, pix_y, 304, 180, digit_char(countdown_step), 4)) begin
                        text_on = 1'b1;
                    end
                end else begin
                    if (draw_char(pix_x, pix_y, 240, 180, "S", 2) ||
                        draw_char(pix_x, pix_y, 256, 180, "T", 2) ||
                        draw_char(pix_x, pix_y, 272, 180, "A", 2) ||
                        draw_char(pix_x, pix_y, 288, 180, "R", 2) ||
                        draw_char(pix_x, pix_y, 304, 180, "T", 2)) begin
                        text_on = 1'b1;
                    end
                end
            end

            if (game_state == `GS_PLAY || game_state == `GS_COUNTDOWN) begin
                if (draw_char(pix_x, pix_y, 20, 20, digit_char(left_rounds), 2) ||
                    draw_char(pix_x, pix_y, 600, 20, digit_char(right_rounds), 2)) begin
                    text_on = 1'b1;
                end

                if (left_blocks >= 1 && (pix_x >= 20 && pix_x < 30) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;
                if (left_blocks >= 2 && (pix_x >= 34 && pix_x < 44) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;
                if (left_blocks >= 3 && (pix_x >= 48 && pix_x < 58) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;

                if (right_blocks >= 1 && (pix_x >= 582 && pix_x < 592) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;
                if (right_blocks >= 2 && (pix_x >= 596 && pix_x < 606) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;
                if (right_blocks >= 3 && (pix_x >= 610 && pix_x < 620) && (pix_y >= 60 && pix_y < 66)) text_on = 1'b1;
            end

            if (game_state == `GS_GAMEOVER) begin
                if (p1_rounds == `MAX_ROUNDS) begin
                    if (draw_char(pix_x, pix_y, 260, 180, "P", 2) ||
                        draw_char(pix_x, pix_y, 276, 180, "1", 2) ||
                        draw_char(pix_x, pix_y, 308, 180, "W", 2) ||
                        draw_char(pix_x, pix_y, 324, 180, "I", 2) ||
                        draw_char(pix_x, pix_y, 340, 180, "N", 2)) begin
                        text_on = 1'b1;
                    end
                end else begin
                    if (draw_char(pix_x, pix_y, 260, 180, "P", 2) ||
                        draw_char(pix_x, pix_y, 276, 180, "2", 2) ||
                        draw_char(pix_x, pix_y, 308, 180, "W", 2) ||
                        draw_char(pix_x, pix_y, 324, 180, "I", 2) ||
                        draw_char(pix_x, pix_y, 340, 180, "N", 2)) begin
                        text_on = 1'b1;
                    end
                end
            end

            if (text_on) begin
                rgb = text_color;
            end
        end
    end
endmodule
