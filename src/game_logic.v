`include "game_params.vh"

// Game logic FSMs and round management. All gameplay updates run on the tick input.

module game_logic (
    input  wire clk,
    input  wire reset,
    input  wire tick,
    input  wire p1_left,
    input  wire p1_right,
    input  wire p1_attack,
    input  wire p1_attack_edge,
    input  wire p2_left,
    input  wire p2_right,
    input  wire p2_attack,
    input  wire p2_attack_edge,
    output reg  [9:0] p1_x,
    output reg  [9:0] p2_x,
    output reg  [3:0] p1_state,
    output reg  [3:0] p2_state,
    output reg  [1:0] p1_blocks,
    output reg  [1:0] p2_blocks,
    output reg  [1:0] p1_rounds,
    output reg  [1:0] p2_rounds,
    output reg  [1:0] game_state,
    output reg  [1:0] countdown_step,
    output reg  p1_on_left
);
    localparam integer LEFT_START  = 80;
    localparam integer RIGHT_START = `SCREEN_W - `CHAR_W - 80;
    localparam integer LEFT_BOUND  = 0;
    localparam integer RIGHT_BOUND = `SCREEN_W - `CHAR_W;

    localparam integer CHAR_TOP = `GROUND_Y - `CHAR_H;

    localparam [2:0] DEF_NONE  = 3'd0;
    localparam [2:0] DEF_HIT   = 3'd1;
    localparam [2:0] DEF_BLOCK = 3'd2;
    localparam [2:0] DEF_GUARD = 3'd3;
    localparam [2:0] DEF_KO    = 3'd4;

    reg [5:0] p1_timer;
    reg [5:0] p2_timer;
    reg [5:0] countdown_timer;

    reg p1_basic_connected;
    reg p2_basic_connected;
    reg [5:0] p1_charge_cnt;
    reg [5:0] p2_charge_cnt;

    reg p1_attack_latched;
    reg p2_attack_latched;
    reg p1_attack_rel_latched;
    reg p2_attack_rel_latched;
    reg p1_attack_prev;
    reg p2_attack_prev;

    reg [9:0] p1_x_n;
    reg [9:0] p2_x_n;
    reg [3:0] p1_state_n;
    reg [3:0] p2_state_n;
    reg [1:0] p1_blocks_n;
    reg [1:0] p2_blocks_n;
    reg [1:0] p1_rounds_n;
    reg [1:0] p2_rounds_n;
    reg [1:0] game_state_n;
    reg [1:0] countdown_step_n;
    reg [5:0] countdown_timer_n;
    reg p1_on_left_n;

    reg [5:0] p1_timer_n;
    reg [5:0] p2_timer_n;
    reg p1_basic_connected_n;
    reg p2_basic_connected_n;
    reg [5:0] p1_charge_cnt_n;
    reg [5:0] p2_charge_cnt_n;

    reg [3:0] p1_state_base;
    reg [3:0] p2_state_base;
    reg [5:0] p1_timer_base;
    reg [5:0] p2_timer_base;
    reg [9:0] p1_x_base;
    reg [9:0] p2_x_base;
    reg p1_basic_connected_base;
    reg p2_basic_connected_base;
    reg [5:0] p1_charge_cnt_base;
    reg [5:0] p2_charge_cnt_base;
    reg p1_charge_ready;
    reg p2_charge_ready;

    reg p1_fwd;
    reg p1_back;
    reg p2_fwd;
    reg p2_back;

    reg p1_hit_active;
    reg p2_hit_active;
    reg p1_blocking;
    reg p2_blocking;
    reg p1_hits_p2;
    reg p2_hits_p1;
    reg [2:0] p1_def_event;
    reg [2:0] p2_def_event;
    reg round_over;
    reg winner_p1;
    reg winner_p2;

    integer p1_hit_x0;
    integer p1_hit_x1;
    integer p1_hit_y0;
    integer p1_hit_y1;
    integer p2_hit_x0;
    integer p2_hit_x1;
    integer p2_hit_y0;
    integer p2_hit_y1;
    integer p1_hurt_x0;
    integer p1_hurt_x1;
    integer p1_hurt_y0;
    integer p1_hurt_y1;
    integer p2_hurt_x0;
    integer p2_hurt_x1;
    integer p2_hurt_y0;
    integer p2_hurt_y1;
    integer p1_range;
    integer p2_range;
    integer p1_hurt_ext;
    integer p2_hurt_ext;

    function rect_overlap;
        input integer ax0;
        input integer ax1;
        input integer ay0;
        input integer ay1;
        input integer bx0;
        input integer bx1;
        input integer by0;
        input integer by1;
        begin
            rect_overlap = (ax0 <= bx1) && (ax1 >= bx0) && (ay0 <= by1) && (ay1 >= by0);
        end
    endfunction

    function [1:0] dec_block;
        input [1:0] val;
        begin
            if (val == 2'd0) begin
                dec_block = 2'd0;
            end else begin
                dec_block = val - 1'b1;
            end
        end
    endfunction

    // Latch short button edges until the next game tick.
    always @(posedge clk) begin
        if (reset) begin
            p1_attack_latched <= 1'b0;
            p2_attack_latched <= 1'b0;
            p1_attack_rel_latched <= 1'b0;
            p2_attack_rel_latched <= 1'b0;
            p1_attack_prev <= 1'b0;
            p2_attack_prev <= 1'b0;
        end else begin
            p1_attack_prev <= p1_attack;
            p2_attack_prev <= p2_attack;

            if (p1_attack_edge) begin
                p1_attack_latched <= 1'b1;
            end
            if (p2_attack_edge) begin
                p2_attack_latched <= 1'b1;
            end

            if (p1_attack_prev && !p1_attack) begin
                p1_attack_rel_latched <= 1'b1;
            end
            if (p2_attack_prev && !p2_attack) begin
                p2_attack_rel_latched <= 1'b1;
            end

            if (tick) begin
                p1_attack_latched <= 1'b0;
                p2_attack_latched <= 1'b0;
                p1_attack_rel_latched <= 1'b0;
                p2_attack_rel_latched <= 1'b0;
            end
        end
    end

    always @* begin
        p1_x_n = p1_x;
        p2_x_n = p2_x;
        p1_state_n = p1_state;
        p2_state_n = p2_state;
        p1_blocks_n = p1_blocks;
        p2_blocks_n = p2_blocks;
        p1_rounds_n = p1_rounds;
        p2_rounds_n = p2_rounds;
        game_state_n = game_state;
        countdown_step_n = countdown_step;
        countdown_timer_n = countdown_timer;
        p1_on_left_n = p1_on_left;
        p1_timer_n = p1_timer;
        p2_timer_n = p2_timer;
        p1_basic_connected_n = p1_basic_connected;
        p2_basic_connected_n = p2_basic_connected;
        p1_charge_cnt_n = p1_charge_cnt;
        p2_charge_cnt_n = p2_charge_cnt;

        p1_state_base = p1_state;
        p2_state_base = p2_state;
        p1_timer_base = p1_timer;
        p2_timer_base = p2_timer;
        p1_x_base = p1_x;
        p2_x_base = p2_x;
        p1_basic_connected_base = p1_basic_connected;
        p2_basic_connected_base = p2_basic_connected;
        p1_charge_cnt_base = p1_charge_cnt;
        p2_charge_cnt_base = p2_charge_cnt;
        p1_charge_ready = 1'b0;
        p2_charge_ready = 1'b0;

        if (tick) begin
            case (game_state)
                `GS_MENU: begin
                    if (p1_left && !p1_right) begin
                        p1_on_left_n = 1'b1;
                    end else if (p1_right && !p1_left) begin
                        p1_on_left_n = 1'b0;
                    end

                    if (p2_left && !p2_right) begin
                        p1_on_left_n = 1'b0;
                    end else if (p2_right && !p2_left) begin
                        p1_on_left_n = 1'b1;
                    end

                    p1_state_n = `ST_IDLE;
                    p2_state_n = `ST_IDLE;
                    p1_timer_n = 6'd0;
                    p2_timer_n = 6'd0;
                    p1_basic_connected_n = 1'b0;
                    p2_basic_connected_n = 1'b0;
                    p1_charge_cnt_n = 6'd0;
                    p2_charge_cnt_n = 6'd0;

                    p1_rounds_n = 2'd0;
                    p2_rounds_n = 2'd0;
                    p1_blocks_n = `MAX_BLOCKS;
                    p2_blocks_n = `MAX_BLOCKS;

                    if (p1_on_left_n) begin
                        p1_x_n = LEFT_START[9:0];
                        p2_x_n = RIGHT_START[9:0];
                    end else begin
                        p1_x_n = RIGHT_START[9:0];
                        p2_x_n = LEFT_START[9:0];
                    end

                    if (p1_attack_latched) begin
                        game_state_n = `GS_COUNTDOWN;
                        countdown_step_n = 2'd3;
                        countdown_timer_n = `COUNTDOWN_FRAMES - 1;
                    end
                end

                `GS_COUNTDOWN: begin
                    p1_state_n = `ST_IDLE;
                    p2_state_n = `ST_IDLE;
                    p1_timer_n = 6'd0;
                    p2_timer_n = 6'd0;
                    p1_basic_connected_n = 1'b0;
                    p2_basic_connected_n = 1'b0;
                    p1_charge_cnt_n = 6'd0;
                    p2_charge_cnt_n = 6'd0;

                    p1_blocks_n = `MAX_BLOCKS;
                    p2_blocks_n = `MAX_BLOCKS;

                    if (p1_on_left) begin
                        p1_x_n = LEFT_START[9:0];
                        p2_x_n = RIGHT_START[9:0];
                    end else begin
                        p1_x_n = RIGHT_START[9:0];
                        p2_x_n = LEFT_START[9:0];
                    end

                    if (countdown_timer == 0) begin
                        if (countdown_step == 0) begin
                            game_state_n = `GS_PLAY;
                        end else begin
                            countdown_step_n = countdown_step - 1'b1;
                            countdown_timer_n = `COUNTDOWN_FRAMES - 1;
                        end
                    end else begin
                        countdown_timer_n = countdown_timer - 1'b1;
                    end
                end

                `GS_PLAY: begin
                    // Charge counters update once per frame.
                    p1_charge_ready = (p1_charge_cnt >= `CHARGE_FRAMES);
                    p2_charge_ready = (p2_charge_cnt >= `CHARGE_FRAMES);

                    if (p1_attack) begin
                        if (p1_charge_cnt < `CHARGE_FRAMES) begin
                            p1_charge_cnt_base = p1_charge_cnt + 1'b1;
                        end
                    end else begin
                        p1_charge_cnt_base = 6'd0;
                    end

                    if (p2_attack) begin
                        if (p2_charge_cnt < `CHARGE_FRAMES) begin
                            p2_charge_cnt_base = p2_charge_cnt + 1'b1;
                        end
                    end else begin
                        p2_charge_cnt_base = 6'd0;
                    end

                    // Input direction mapping based on side.
                    p1_fwd = p1_on_left ? p1_right : p1_left;
                    p1_back = p1_on_left ? p1_left : p1_right;
                    p2_fwd = p1_on_left ? p2_left : p2_right;
                    p2_back = p1_on_left ? p2_right : p2_left;

                        // P1 base state update.
                        case (p1_state)
                            `ST_IDLE, `ST_FWD, `ST_BACK: begin
                                if (p1_attack_latched) begin
                                    p1_state_base = `ST_ATK_START;
                                    p1_timer_base = `BASIC_STARTUP - 1;
                                    p1_basic_connected_base = 1'b0;
                                end else if (p1_attack_rel_latched && p1_charge_ready) begin
                                    p1_state_base = `ST_SPC_START;
                                    p1_timer_base = `SPECIAL_STARTUP - 1;
                                    p1_basic_connected_base = 1'b0;
                                end else if (p1_fwd && !p1_back) begin
                                    p1_state_base = `ST_FWD;
                                end else if (p1_back && !p1_fwd) begin
                                    p1_state_base = `ST_BACK;
                                end else begin
                                    p1_state_base = `ST_IDLE;
                                end
                            end
                            `ST_ATK_START: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_ATK_ACTIVE;
                                    p1_timer_base = `BASIC_ACTIVE - 1;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_ATK_ACTIVE: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_ATK_REC;
                                    p1_timer_base = `BASIC_RECOVERY - 1;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_ATK_REC: begin
                                if (p1_basic_connected && p1_attack_latched) begin
                                    p1_state_base = `ST_SPC_START;
                                    p1_timer_base = `SPECIAL_STARTUP - 1;
                                    p1_basic_connected_base = 1'b0;
                                end else if (p1_attack_rel_latched && p1_charge_ready) begin
                                    p1_state_base = `ST_SPC_START;
                                    p1_timer_base = `SPECIAL_STARTUP - 1;
                                    p1_basic_connected_base = 1'b0;
                                end else if (p1_timer == 0) begin
                                    p1_state_base = `ST_IDLE;
                                    p1_timer_base = 6'd0;
                                    p1_basic_connected_base = 1'b0;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_SPC_START: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_SPC_ACTIVE;
                                    p1_timer_base = `SPECIAL_ACTIVE - 1;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_SPC_ACTIVE: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_SPC_REC;
                                    p1_timer_base = `SPECIAL_RECOVERY - 1;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_SPC_REC: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_IDLE;
                                    p1_timer_base = 6'd0;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            `ST_HITSTUN, `ST_BLOCKSTUN, `ST_GUARD: begin
                                if (p1_timer == 0) begin
                                    p1_state_base = `ST_IDLE;
                                    p1_timer_base = 6'd0;
                                end else begin
                                    p1_timer_base = p1_timer - 1'b1;
                                end
                            end
                            default: begin
                                p1_state_base = `ST_IDLE;
                                p1_timer_base = 6'd0;
                            end
                        endcase

                        // P2 base state update.
                        case (p2_state)
                            `ST_IDLE, `ST_FWD, `ST_BACK: begin
                                if (p2_attack_latched) begin
                                    p2_state_base = `ST_ATK_START;
                                    p2_timer_base = `BASIC_STARTUP - 1;
                                    p2_basic_connected_base = 1'b0;
                                end else if (p2_attack_rel_latched && p2_charge_ready) begin
                                    p2_state_base = `ST_SPC_START;
                                    p2_timer_base = `SPECIAL_STARTUP - 1;
                                    p2_basic_connected_base = 1'b0;
                                end else if (p2_fwd && !p2_back) begin
                                    p2_state_base = `ST_FWD;
                                end else if (p2_back && !p2_fwd) begin
                                    p2_state_base = `ST_BACK;
                                end else begin
                                    p2_state_base = `ST_IDLE;
                                end
                            end
                            `ST_ATK_START: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_ATK_ACTIVE;
                                    p2_timer_base = `BASIC_ACTIVE - 1;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_ATK_ACTIVE: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_ATK_REC;
                                    p2_timer_base = `BASIC_RECOVERY - 1;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_ATK_REC: begin
                                if (p2_basic_connected && p2_attack_latched) begin
                                    p2_state_base = `ST_SPC_START;
                                    p2_timer_base = `SPECIAL_STARTUP - 1;
                                    p2_basic_connected_base = 1'b0;
                                end else if (p2_attack_rel_latched && p2_charge_ready) begin
                                    p2_state_base = `ST_SPC_START;
                                    p2_timer_base = `SPECIAL_STARTUP - 1;
                                    p2_basic_connected_base = 1'b0;
                                end else if (p2_timer == 0) begin
                                    p2_state_base = `ST_IDLE;
                                    p2_timer_base = 6'd0;
                                    p2_basic_connected_base = 1'b0;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_SPC_START: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_SPC_ACTIVE;
                                    p2_timer_base = `SPECIAL_ACTIVE - 1;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_SPC_ACTIVE: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_SPC_REC;
                                    p2_timer_base = `SPECIAL_RECOVERY - 1;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_SPC_REC: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_IDLE;
                                    p2_timer_base = 6'd0;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            `ST_HITSTUN, `ST_BLOCKSTUN, `ST_GUARD: begin
                                if (p2_timer == 0) begin
                                    p2_state_base = `ST_IDLE;
                                    p2_timer_base = 6'd0;
                                end else begin
                                    p2_timer_base = p2_timer - 1'b1;
                                end
                            end
                            default: begin
                                p2_state_base = `ST_IDLE;
                                p2_timer_base = 6'd0;
                            end
                        endcase

                        // Base movement update.
                        p1_x_base = p1_x;
                        if (p1_state_base == `ST_FWD) begin
                            if (p1_on_left) begin
                                if (p1_x + `MOVE_FWD_PIX <= p2_x - `CHAR_W) begin
                                    p1_x_base = p1_x + `MOVE_FWD_PIX;
                                end
                            end else begin
                                if (p1_x >= p2_x + `CHAR_W + `MOVE_FWD_PIX) begin
                                    p1_x_base = p1_x - `MOVE_FWD_PIX;
                                end
                            end
                        end else if (p1_state_base == `ST_BACK) begin
                            if (p1_on_left) begin
                                if (p1_x >= LEFT_BOUND + `MOVE_BACK_PIX) begin
                                    p1_x_base = p1_x - `MOVE_BACK_PIX;
                                end
                            end else begin
                                if (p1_x + `MOVE_BACK_PIX <= RIGHT_BOUND) begin
                                    p1_x_base = p1_x + `MOVE_BACK_PIX;
                                end
                            end
                        end else if (p1_state_base == `ST_SPC_START || p1_state_base == `ST_SPC_ACTIVE) begin
                            if (p1_on_left) begin
                                if (p1_x + `SPECIAL_MOVE_PIX <= p2_x - `CHAR_W) begin
                                    p1_x_base = p1_x + `SPECIAL_MOVE_PIX;
                                end
                            end else begin
                                if (p1_x >= p2_x + `CHAR_W + `SPECIAL_MOVE_PIX) begin
                                    p1_x_base = p1_x - `SPECIAL_MOVE_PIX;
                                end
                            end
                        end

                        p2_x_base = p2_x;
                        if (p2_state_base == `ST_FWD) begin
                            if (!p1_on_left) begin
                                if (p2_x + `MOVE_FWD_PIX <= p1_x - `CHAR_W) begin
                                    p2_x_base = p2_x + `MOVE_FWD_PIX;
                                end
                            end else begin
                                if (p2_x >= p1_x + `CHAR_W + `MOVE_FWD_PIX) begin
                                    p2_x_base = p2_x - `MOVE_FWD_PIX;
                                end
                            end
                        end else if (p2_state_base == `ST_BACK) begin
                            if (!p1_on_left) begin
                                if (p2_x >= LEFT_BOUND + `MOVE_BACK_PIX) begin
                                    p2_x_base = p2_x - `MOVE_BACK_PIX;
                                end
                            end else begin
                                if (p2_x + `MOVE_BACK_PIX <= RIGHT_BOUND) begin
                                    p2_x_base = p2_x + `MOVE_BACK_PIX;
                                end
                            end
                        end else if (p2_state_base == `ST_SPC_START || p2_state_base == `ST_SPC_ACTIVE) begin
                            if (!p1_on_left) begin
                                if (p2_x + `SPECIAL_MOVE_PIX <= p1_x - `CHAR_W) begin
                                    p2_x_base = p2_x + `SPECIAL_MOVE_PIX;
                                end
                            end else begin
                                if (p2_x >= p1_x + `CHAR_W + `SPECIAL_MOVE_PIX) begin
                                    p2_x_base = p2_x - `SPECIAL_MOVE_PIX;
                                end
                            end
                        end

                        // Hit detection.

                            p1_hit_active = (p1_state_base == `ST_ATK_ACTIVE) || (p1_state_base == `ST_SPC_ACTIVE);
                            p2_hit_active = (p2_state_base == `ST_ATK_ACTIVE) || (p2_state_base == `ST_SPC_ACTIVE);
                            p1_blocking = (p1_state_base == `ST_BACK);
                            p2_blocking = (p2_state_base == `ST_BACK);

                            p1_range = (p1_state_base == `ST_SPC_ACTIVE) ? `SPECIAL_RANGE : `BASIC_RANGE;
                            p2_range = (p2_state_base == `ST_SPC_ACTIVE) ? `SPECIAL_RANGE : `BASIC_RANGE;

                            p1_hurt_ext = (p1_state_base == `ST_ATK_REC) ? `BASIC_RANGE :
                                          (p1_state_base == `ST_SPC_REC) ? `SPECIAL_RANGE : 0;
                            p2_hurt_ext = (p2_state_base == `ST_ATK_REC) ? `BASIC_RANGE :
                                          (p2_state_base == `ST_SPC_REC) ? `SPECIAL_RANGE : 0;

                            p1_hit_y0 = CHAR_TOP + `HITBOX_Y_OFFSET;
                            p1_hit_y1 = p1_hit_y0 + `HITBOX_HEIGHT - 1;
                            p2_hit_y0 = CHAR_TOP + `HITBOX_Y_OFFSET;
                            p2_hit_y1 = p2_hit_y0 + `HITBOX_HEIGHT - 1;

                            p1_hurt_y0 = CHAR_TOP;
                            p1_hurt_y1 = CHAR_TOP + `CHAR_H - 1;
                            p2_hurt_y0 = CHAR_TOP;
                            p2_hurt_y1 = CHAR_TOP + `CHAR_H - 1;

                            if (p1_on_left) begin
                                p1_hit_x0 = p1_x_base + `CHAR_W;
                                p1_hit_x1 = p1_x_base + `CHAR_W + p1_range - 1;
                                p1_hurt_x0 = p1_x_base;
                                p1_hurt_x1 = p1_x_base + `CHAR_W + p1_hurt_ext - 1;

                                p2_hit_x1 = p2_x_base - 1;
                                p2_hit_x0 = p2_x_base - p2_range;
                                p2_hurt_x1 = p2_x_base + `CHAR_W - 1;
                                p2_hurt_x0 = p2_x_base - p2_hurt_ext;
                            end else begin
                                p1_hit_x1 = p1_x_base - 1;
                                p1_hit_x0 = p1_x_base - p1_range;
                                p1_hurt_x1 = p1_x_base + `CHAR_W - 1;
                                p1_hurt_x0 = p1_x_base - p1_hurt_ext;

                                p2_hit_x0 = p2_x_base + `CHAR_W;
                                p2_hit_x1 = p2_x_base + `CHAR_W + p2_range - 1;
                                p2_hurt_x0 = p2_x_base;
                                p2_hurt_x1 = p2_x_base + `CHAR_W + p2_hurt_ext - 1;
                            end

                            p1_hits_p2 = p1_hit_active && rect_overlap(p1_hit_x0, p1_hit_x1, p1_hit_y0, p1_hit_y1,
                                                                      p2_hurt_x0, p2_hurt_x1, p2_hurt_y0, p2_hurt_y1);
                            p2_hits_p1 = p2_hit_active && rect_overlap(p2_hit_x0, p2_hit_x1, p2_hit_y0, p2_hit_y1,
                                                                      p1_hurt_x0, p1_hurt_x1, p1_hurt_y0, p1_hurt_y1);

                            if (p1_state_base == `ST_ATK_ACTIVE && p1_hits_p2) begin
                                p1_basic_connected_base = 1'b1;
                            end
                            if (p2_state_base == `ST_ATK_ACTIVE && p2_hits_p1) begin
                                p2_basic_connected_base = 1'b1;
                            end

                            p1_def_event = DEF_NONE;
                            p2_def_event = DEF_NONE;

                            if (p2_hits_p1) begin
                                if (p1_blocking) begin
                                    if (p1_blocks == 0) begin
                                        p1_def_event = DEF_GUARD;
                                    end else begin
                                        p1_def_event = DEF_BLOCK;
                                    end
                                end else if (p2_state_base == `ST_SPC_ACTIVE) begin
                                    p1_def_event = DEF_KO;
                                end else begin
                                    p1_def_event = DEF_HIT;
                                end
                            end

                            if (p1_hits_p2) begin
                                if (p2_blocking) begin
                                    if (p2_blocks == 0) begin
                                        p2_def_event = DEF_GUARD;
                                    end else begin
                                        p2_def_event = DEF_BLOCK;
                                    end
                                end else if (p1_state_base == `ST_SPC_ACTIVE) begin
                                    p2_def_event = DEF_KO;
                                end else begin
                                    p2_def_event = DEF_HIT;
                                end
                            end

                            p1_state_n = p1_state_base;
                            p2_state_n = p2_state_base;
                            p1_timer_n = p1_timer_base;
                            p2_timer_n = p2_timer_base;
                            p1_x_n = p1_x_base;
                            p2_x_n = p2_x_base;
                            p1_basic_connected_n = p1_basic_connected_base;
                            p2_basic_connected_n = p2_basic_connected_base;
                            p1_charge_cnt_n = p1_charge_cnt_base;
                            p2_charge_cnt_n = p2_charge_cnt_base;

                            if (p1_def_event != DEF_NONE) begin
                                p1_blocks_n = dec_block(p1_blocks);
                            end
                            if (p2_def_event != DEF_NONE) begin
                                p2_blocks_n = dec_block(p2_blocks);
                            end

                            if (p1_def_event == DEF_HIT) begin
                                p1_state_n = `ST_HITSTUN;
                                p1_timer_n = `BASIC_HITSTUN - 1;
                                p1_basic_connected_n = 1'b0;
                            end else if (p1_def_event == DEF_BLOCK) begin
                                p1_state_n = `ST_BLOCKSTUN;
                                p1_timer_n = (p2_state_base == `ST_SPC_ACTIVE) ? (`SPECIAL_BLOCKSTUN - 1) : (`BASIC_BLOCKSTUN - 1);
                                p1_basic_connected_n = 1'b0;
                            end else if (p1_def_event == DEF_GUARD) begin
                                p1_state_n = `ST_GUARD;
                                p1_timer_n = (p2_state_base == `ST_SPC_ACTIVE) ? (`SPECIAL_GUARDSTUN - 1) : (`BASIC_GUARDSTUN - 1);
                                p1_basic_connected_n = 1'b0;
                            end

                            if (p2_def_event == DEF_HIT) begin
                                p2_state_n = `ST_HITSTUN;
                                p2_timer_n = `BASIC_HITSTUN - 1;
                                p2_basic_connected_n = 1'b0;
                            end else if (p2_def_event == DEF_BLOCK) begin
                                p2_state_n = `ST_BLOCKSTUN;
                                p2_timer_n = (p1_state_base == `ST_SPC_ACTIVE) ? (`SPECIAL_BLOCKSTUN - 1) : (`BASIC_BLOCKSTUN - 1);
                                p2_basic_connected_n = 1'b0;
                            end else if (p2_def_event == DEF_GUARD) begin
                                p2_state_n = `ST_GUARD;
                                p2_timer_n = (p1_state_base == `ST_SPC_ACTIVE) ? (`SPECIAL_GUARDSTUN - 1) : (`BASIC_GUARDSTUN - 1);
                                p2_basic_connected_n = 1'b0;
                            end

                            round_over = 1'b0;
                            winner_p1 = 1'b0;
                            winner_p2 = 1'b0;

                            if ((p1_def_event == DEF_KO) && (p2_def_event == DEF_KO)) begin
                                round_over = 1'b1;
                            end else if (p1_def_event == DEF_KO) begin
                                round_over = 1'b1;
                                winner_p2 = 1'b1;
                            end else if (p2_def_event == DEF_KO) begin
                                round_over = 1'b1;
                                winner_p1 = 1'b1;
                            end

                            if (round_over) begin
                                if (winner_p1) begin
                                    p1_rounds_n = p1_rounds + 1'b1;
                                end
                                if (winner_p2) begin
                                    p2_rounds_n = p2_rounds + 1'b1;
                                end

                                if ((winner_p1 && (p1_rounds_n >= `MAX_ROUNDS)) ||
                                    (winner_p2 && (p2_rounds_n >= `MAX_ROUNDS))) begin
                                    game_state_n = `GS_GAMEOVER;
                                end else begin
                                    game_state_n = `GS_COUNTDOWN;
                                    countdown_step_n = 2'd3;
                                    countdown_timer_n = `COUNTDOWN_FRAMES - 1;
                                end

                                if (p1_on_left) begin
                                    p1_x_n = LEFT_START[9:0];
                                    p2_x_n = RIGHT_START[9:0];
                                end else begin
                                    p1_x_n = RIGHT_START[9:0];
                                    p2_x_n = LEFT_START[9:0];
                                end

                                p1_state_n = `ST_IDLE;
                                p2_state_n = `ST_IDLE;
                                p1_timer_n = 6'd0;
                                p2_timer_n = 6'd0;
                                p1_blocks_n = `MAX_BLOCKS;
                                p2_blocks_n = `MAX_BLOCKS;
                                p1_basic_connected_n = 1'b0;
                                p2_basic_connected_n = 1'b0;
                                p1_charge_cnt_n = 6'd0;
                                p2_charge_cnt_n = 6'd0;
                            end
                    end
                end

                `GS_GAMEOVER: begin
                    if (p1_attack_latched) begin
                        game_state_n = `GS_MENU;
                    end
                end

                default: begin
                    game_state_n = `GS_MENU;
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            p1_x <= LEFT_START[9:0];
            p2_x <= RIGHT_START[9:0];
            p1_state <= `ST_IDLE;
            p2_state <= `ST_IDLE;
            p1_blocks <= `MAX_BLOCKS;
            p2_blocks <= `MAX_BLOCKS;
            p1_rounds <= 2'd0;
            p2_rounds <= 2'd0;
            game_state <= `GS_MENU;
            countdown_step <= 2'd3;
            countdown_timer <= 6'd0;
            p1_on_left <= 1'b1;
            p1_timer <= 6'd0;
            p2_timer <= 6'd0;
            p1_basic_connected <= 1'b0;
            p2_basic_connected <= 1'b0;
            p1_charge_cnt <= 6'd0;
            p2_charge_cnt <= 6'd0;
        end else if (tick) begin
            p1_x <= p1_x_n;
            p2_x <= p2_x_n;
            p1_state <= p1_state_n;
            p2_state <= p2_state_n;
            p1_blocks <= p1_blocks_n;
            p2_blocks <= p2_blocks_n;
            p1_rounds <= p1_rounds_n;
            p2_rounds <= p2_rounds_n;
            game_state <= game_state_n;
            countdown_step <= countdown_step_n;
            countdown_timer <= countdown_timer_n;
            p1_on_left <= p1_on_left_n;
            p1_timer <= p1_timer_n;
            p2_timer <= p2_timer_n;
            p1_basic_connected <= p1_basic_connected_n;
            p2_basic_connected <= p2_basic_connected_n;
            p1_charge_cnt <= p1_charge_cnt_n;
            p2_charge_cnt <= p2_charge_cnt_n;
        end
    end
endmodule
