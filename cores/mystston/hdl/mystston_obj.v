//============================================================================
//  mystston_obj — Sprite renderer for Mysterious Stones (Technos 1984)
//  Verified against mystston.cpp's draw_sprites() and the spritelayout gfx
//  descriptor:
//    static const gfx_layout spritelayout = { 16,16, RGN_FRAC(1,3), 3,
//      { RGN_FRAC(2,3), RGN_FRAC(1,3), RGN_FRAC(0,3) },
//      { 16*8+0..16*8+7, 16*0+0..16*0+7 }, { 0*8, 1*8, ..., 15*8 }, 32*8 };
//  For plane P (0=lsb..2=msb) and tile T (9-bit code, up to 512 tiles per
//  0x4000-byte third of "fgtiles_sprites"), row R (0-15): the right half of
//  the row (screen columns 8-15) is byte (P*0x4000 + T*32 + R), MSB=col8; the
//  left half (columns 0-7) is byte (P*0x4000 + T*32 + 16+R), MSB=col0. So for
//  destination column C (0-15): C<8 reads bit(7-C) of the left-half byte,
//  C>=8 reads bit(15-C) of the right-half byte.
//
//  Palette: sprites use gfx index 2 (GFXDECODE_ENTRY("fgtiles_sprites",0,
//  spritelayout,0*8,2)) — base 0, 2 groups of 8 -> a 4-bit palette index
//  {color, tile_pixel[2:0]} into entries 0-15 (dynamic palette RAM range).
//
//  Bus ownership: gfx1 is shared with the foreground text layer; owned and
//  arbitrated by mystston_video.v via a 2-phase-per-line sequencer (only one
//  of {this module, the fg fetcher} is ever `active` at a time, so there is
//  no real bus contention despite both nominally targeting the same port).
//
//  cpu_spriteram_*: Sprite RAM is single-port BRAM the CPU (mystston_main.v)
//  also accesses directly — same reasoning as mystston_scroll.v's videoram
//  shadow: keep a local copy snooped from the CPU's write side instead of
//  arbitrating a shared address bus.
//
//  hcnt/sprite_pxl/sprite_hit: output line buffer, read combinationally by
//  mystston_colmix during the actual display of target_line (one line after
//  it was prepared). sprite_pxl = {color, tile_pixel[2:0]}, a 4-bit index
//  into palette entries 0-15; transparent when tile_pixel[2:0]==0
//  (sprite_hit low).
//  License: GPLv3
//============================================================================

module mystston_obj(
    input               clk,
    input               rst,
    input               active,             // this module's turn on the gfx1 bus
    input               start,              // pulse: begin fetching target_line
    input       [7:0]   target_line,        // absolute screen line (visible range 8-247)
    output reg          done,               // pulse: target_line's sprite buffer is ready
    input               flip,               // flip screen (X and Y)

    // Sprite RAM CPU write snoop — see header comment
    input       [6:0]   cpu_spriteram_addr,
    input       [7:0]   cpu_spriteram_din,
    input               cpu_spriteram_we,

    // gfx1 bus (fgtiles_sprites, 16-bit SDRAM words) — byte address here;
    // mystston_video.v truncates to [16:1] (word address) before driving the
    // real top-level port, and only while `active`
    output reg  [16:0]  gfx1_addr,
    input       [15:0]  gfx1_data,
    output reg          gfx1_cs,
    input               gfx1_ok,

    // Output line buffer — see header comment
    input       [8:0]   hcnt,
    output      [3:0]   sprite_pxl,
    output              sprite_hit
);

    localparam [4:0] MAX_SPRITES = 5'd24;   // 0x60 bytes / 4 bytes per sprite

    reg [3:0] line_pxl [0:255];
    reg       line_hit [0:255];
    assign sprite_pxl = line_pxl[hcnt[7:0]];
    assign sprite_hit = (hcnt < 9'd256) ? line_hit[hcnt[7:0]] : 1'b0;

    reg [7:0] spriteram_shadow [0:127];
    always @(posedge clk) if (cpu_spriteram_we) spriteram_shadow[cpu_spriteram_addr] <= cpu_spriteram_din;

    reg [4:0] spr_idx;             // 0-23
    reg [7:0] attr_r, tile_r, y_r, x_r;
    reg [3:0] row_in_tile;         // 0-15, tile-relative row (post-flip)
    reg [8:0] scr_x;               // final on-screen X base (may exceed 255)
    reg       flipx_r;
    reg       color_r;

    reg [1:0] plane_idx;           // 0,1,2
    reg       half_idx;            // 0=right(cols8-15), 1=left(cols0-7)
    reg [7:0] right_byte [0:2];    // right_byte[plane], columns 8-15, MSB=col8
    reg [7:0] left_byte  [0:2];    // left_byte[plane],  columns 0-7,  MSB=col0

    // Sprite bounding box — exactly mirrors draw_sprites():
    //   x1 = 240 - spriteram[offs+3]; y1 = (240 - spriteram[offs+2]) & 0xff;
    //   if (flip) { x = 240-x1; y = 240-y1; flipx = !flipx; flipy = !flipy; }
    wire [7:0] y1 = 8'd240 - y_r;
    wire [7:0] x1 = 8'd240 - x_r;
    wire [7:0] y_final = flip ? (8'd240 - y1) : y1;
    wire [7:0] x_final = flip ? (8'd240 - x1) : x1;
    wire       flipy_final = attr_r[1] ^ flip;
    wire       flipx_final = attr_r[2] ^ flip;
    wire       enabled     = attr_r[0];
    wire [8:0] code        = { attr_r[4], tile_r };

    wire [8:0] line_minus_y = { 1'b0, target_line } - { 1'b0, y_final };
    wire       on_line      = enabled && (line_minus_y < 9'd16);
    wire [3:0] row_flip_pre = line_minus_y[3:0];

    wire [16:0] plane_base = { 2'b00, code, 5'd0 } + (plane_idx * 17'd16384); // code*32 + plane*0x4000
    wire [16:0] byte_addr  = plane_base + (half_idx ? (17'd16 + { 13'd0, row_in_tile })
                                                     : { 13'd0, row_in_tile });

    localparam S_IDLE       = 4'd0,
               S_CLEAR      = 4'd1,
               S_READ_DESC  = 4'd2,
               S_CHECK      = 4'd7,
               S_FETCH_REQ  = 4'd8,
               S_FETCH_WAIT = 4'd9,
               S_FETCH_NEXT = 4'd10,
               S_STORE_ROW  = 4'd11,
               S_NEXT_SPR   = 4'd12,
               S_DONE       = 4'd13;
    reg [3:0] state;
    integer i;

    // S_STORE_ROW helpers (plain regs, reused every column iteration)
    reg [3:0] col_idx;
    reg [2:0] tile_pixel;
    reg [8:0] dest_x;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state          <= S_IDLE;
            done           <= 1'b0;
            gfx1_cs        <= 1'b0;
            spr_idx        <= 5'd0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    gfx1_cs <= 1'b0;
                    if (start) begin
                        spr_idx <= 5'd0;
                        state   <= S_CLEAR;
                    end
                end

                S_CLEAR: begin
                    for (i = 0; i < 256; i = i + 1) begin
                        line_pxl[i] <= 4'd0;
                        line_hit[i] <= 1'b0;
                    end
                    state <= S_READ_DESC;
                end

                S_READ_DESC: begin
                    attr_r <= spriteram_shadow[{ spr_idx, 2'd0 }];
                    tile_r <= spriteram_shadow[{ spr_idx, 2'd0 } + 7'd1];
                    y_r    <= spriteram_shadow[{ spr_idx, 2'd0 } + 7'd2];
                    x_r    <= spriteram_shadow[{ spr_idx, 2'd0 } + 7'd3];
                    state  <= S_CHECK;
                end

                S_CHECK: begin
                    if (on_line) begin
                        row_in_tile <= flipy_final ? (4'd15 - row_flip_pre) : row_flip_pre;
                        scr_x       <= { 1'b0, x_final };
                        flipx_r     <= flipx_final;
                        color_r     <= attr_r[3];
                        plane_idx   <= 2'd0;
                        half_idx    <= 1'b0;
                        state       <= S_FETCH_REQ;
                    end else begin
                        state <= S_NEXT_SPR;
                    end
                end

                S_FETCH_REQ: begin
                    if (active) begin
                        gfx1_addr <= byte_addr;
                        gfx1_cs   <= 1'b1;
                        state     <= S_FETCH_WAIT;
                    end
                end
                S_FETCH_WAIT: begin
                    if (active && gfx1_ok) begin
                        if (half_idx)
                            left_byte[plane_idx]  <= byte_addr[0] ? gfx1_data[15:8] : gfx1_data[7:0];
                        else
                            right_byte[plane_idx] <= byte_addr[0] ? gfx1_data[15:8] : gfx1_data[7:0];
                        gfx1_cs <= 1'b0;
                        state   <= S_FETCH_NEXT;
                    end
                end
                S_FETCH_NEXT: begin
                    if (plane_idx == 2'd2) begin
                        if (half_idx) begin
                            state <= S_STORE_ROW;
                        end else begin
                            half_idx  <= 1'b1;
                            plane_idx <= 2'd0;
                            state     <= S_FETCH_REQ;
                        end
                    end else begin
                        plane_idx <= plane_idx + 2'd1;
                        state     <= S_FETCH_REQ;
                    end
                end

                S_STORE_ROW: begin
                    // Unrolled over the 16 destination columns of this tile
                    // row; col_idx/tile_pixel/dest_x are scratch regs reused
                    // each iteration (blocking assigns within the loop body,
                    // final non-blocking write to the line buffer).
                    for (i = 0; i < 16; i = i + 1) begin
                        col_idx = flipx_r ? (4'd15 - i[3:0]) : i[3:0];
                        // col_idx<8 -> left_byte (bit7=col0..bit0=col7); col_idx>=8 -> right_byte
                        // (bit7=col8..bit0=col15); col_idx[2:0] is col_idx mod 8 either way.
                        if (col_idx < 4'd8)
                            tile_pixel = { left_byte[2][7-col_idx[2:0]], left_byte[1][7-col_idx[2:0]], left_byte[0][7-col_idx[2:0]] };
                        else
                            tile_pixel = { right_byte[2][7-col_idx[2:0]], right_byte[1][7-col_idx[2:0]], right_byte[0][7-col_idx[2:0]] };
                        dest_x = scr_x + i[8:0];
                        if (dest_x < 9'd256 && tile_pixel != 3'd0) begin
                            line_pxl[dest_x[7:0]] <= { color_r, tile_pixel };
                            line_hit[dest_x[7:0]] <= 1'b1;
                        end
                    end
                    state <= S_NEXT_SPR;
                end

                S_NEXT_SPR: begin
                    if (spr_idx == MAX_SPRITES-1) begin
                        state <= S_DONE;
                    end else begin
                        spr_idx <= spr_idx + 5'd1;
                        state   <= S_READ_DESC;
                    end
                end

                S_DONE: begin
                    done  <= 1'b1;
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
