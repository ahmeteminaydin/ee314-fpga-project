`ifndef GAME_PARAMS_VH
`define GAME_PARAMS_VH

// Global video constants.
`define SCREEN_W 640
`define SCREEN_H 480

// Character and stage layout.
`define CHAR_W 64
`define CHAR_H 240
`define GROUND_Y 430

// Movement speeds (pixels per 60 Hz frame).
`define MOVE_FWD_PIX 3
`define MOVE_BACK_PIX 2
`define SPECIAL_MOVE_PIX 4

// Attack timing (frames).
`define BASIC_STARTUP 5
`define BASIC_ACTIVE 2
`define BASIC_RECOVERY 17
`define SPECIAL_STARTUP 14
`define SPECIAL_ACTIVE 2
`define SPECIAL_RECOVERY 31

// Hitbox settings.
`define BASIC_RANGE 28
`define SPECIAL_RANGE 52
`define HITBOX_HEIGHT 160
`define HITBOX_Y_OFFSET 40

// Special charge duration (frames at 60 Hz).
`define CHARGE_FRAMES 30

// Stun durations (frames). Derived from frame advantage table.
`define BASIC_HITSTUN 17
`define BASIC_BLOCKSTUN 15
`define BASIC_GUARDSTUN 35
`define SPECIAL_BLOCKSTUN 20
`define SPECIAL_GUARDSTUN 35

// Game constants.
`define MAX_ROUNDS 3
`define MAX_BLOCKS 3
`define COUNTDOWN_FRAMES 60

// Game state encoding.
`define GS_MENU 2'd0
`define GS_COUNTDOWN 2'd1
`define GS_PLAY 2'd2
`define GS_GAMEOVER 2'd3

// Player state encoding.
`define ST_IDLE 4'd0
`define ST_FWD 4'd1
`define ST_BACK 4'd2
`define ST_ATK_START 4'd3
`define ST_ATK_ACTIVE 4'd4
`define ST_ATK_REC 4'd5
`define ST_SPC_START 4'd6
`define ST_SPC_ACTIVE 4'd7
`define ST_SPC_REC 4'd8
`define ST_HITSTUN 4'd9
`define ST_BLOCKSTUN 4'd10
`define ST_GUARD 4'd11

`endif
