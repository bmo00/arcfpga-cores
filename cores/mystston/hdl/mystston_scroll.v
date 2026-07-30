//============================================================================
//  mystston_scroll — Background tilemap renderer for Mysterious Stones
//  Verified against mystston.cpp's get_bg_tile_info()/video_start()
//  (TILEMAP_SCAN_COLS_FLIP_X, 16x16 tiles, 16 cols x 32 rows virtual map) and
//  the spritelayout gfx descriptor (bgtiles uses the same 16x16 3bpp planar
//  layout as sprites — see mystston_obj.v's header comment for the bit-exact
//  byte/bit addressing, reused here for gfx2 instead of gfx1).
//
//  Tile code: bg_videoram is a flat 0x800-byte BRAM region (CPU addresses
//  0x1800-0x1fff). `page = (video_control[2])<<8` selects between its two
//  0x400-byte halves; within a page, the low byte of the code is at
//  [page+tile_index] and the high bit at bit0 of [page+0x200+tile_index] —
//  two independent 512-byte sub-planes, NOT a bit tacked onto video_control.
//  tile_index = (15-col)*32+row (SCAN_COLS_FLIP_X, 16 cols x 32 rows).
//  Y-flip quirk: flags = (tile_index&0x10) ? FLIPY — reduces to "row>=16"
//  since (15-col)*32 always contributes 0 to the low 5 bits.
//
//  No transparency: mystston.cpp never calls set_transparent_pen() on
//  m_bg_tilemap (only on m_fg_tilemap), so every background pixel is opaque.
//  License: GPLv3
//============================================================================

module mystston_scroll(
    input               clk,
    input               rst,
    input               start,              // pulse: begin fetching target_line
    input       [7:0]   target_line,        // physical screen line (0-239) to prepare
    output reg          done,               // pulse: target_line's bg buffer is ready
    input               flip,               // flip screen

    input       [7:0]   scroll_reg,         // 0x2020 write — vertical scroll (set_scrolly)
    input               page_select,        // video_control[2]

    // videoram is a single-port BRAM the CPU (mystston_main.v) also accesses
    // directly — rather than arbitrate a shared address bus between the CPU
    // and this module's own tile-code prefetching, this module keeps its own
    // local shadow copy, snooped from the CPU's write-side signals (cheap on
    // an FPGA, and avoids the arbitration entirely).
    input       [11:0]  cpu_videoram_addr,
    input       [7:0]   cpu_videoram_din,
    input               cpu_videoram_we,

    // SDRAM bus for tile graphics (gfx2: 17-bit byte address, 16-bit data) —
    // exclusive to this module, no arbitration needed
    output reg  [16:1]  gfx2_addr,
    input       [15:0]  gfx2_data,
    output reg          gfx2_cs,
    input               gfx2_ok,

    // Output line buffer, read combinationally by mystston_colmix
    input       [8:0]   hcnt,
    output      [2:0]   bg_pxl,
    output              bg_hit
);

    reg [2:0] line_pxl [0:255];
    assign bg_pxl = line_pxl[hcnt[7:0]];
    assign bg_hit = (hcnt < 9'd256); // background is always opaque

    // Local shadow of videoram (see port comment above) — the whole 0x800
    // (bg_videoram) region since page_select swaps between its two halves.
    reg [7:0] bg_videoram_shadow [0:4095];
    always @(posedge clk) if (cpu_videoram_we) bg_videoram_shadow[cpu_videoram_addr] <= cpu_videoram_din;

    // ------------------------------------------------------------------
    // Virtual tilemap position for target_line (16 cols x 32 rows of 16x16
    // tiles = 256 x 512 pixels; vertical scroll wraps naturally in 9 bits).
    // ------------------------------------------------------------------
    wire [8:0] y_pre = flip ? (9'd239 - { 1'b0, target_line }) : { 1'b0, target_line };
    wire [8:0] vy    = y_pre + { 1'b0, scroll_reg };
    wire [4:0] row   = vy[8:4];       // 0-31
    wire [3:0] tile_line_pre = vy[3:0];
    wire       flipy_quirk = row[4];  // (tile_index & 0x10), see header comment
    wire [3:0] tile_line = flipy_quirk ? (4'd15 - tile_line_pre) : tile_line_pre;

    // bg_videoram's own 0-based index (page|tile_index, 0-0x7ff) plus the
    // 0x800 base offset where it sits within the flat 4096-entry shadow.
    wire [10:0] page = { page_select, 10'd0 }; // 0 or 0x400, within bg_videoram's own 0x800 window
    wire [11:0] code_lo_addr = 12'h800 + { 1'b0, page } + { 3'd0, tile_index };
    wire [11:0] code_hi_addr = code_lo_addr + 12'h200;

    reg  [3:0] col;                    // 0-15, display column being fetched
    wire [3:0] eff_col = flip ? (4'd15 - col) : col;
    wire [8:0] tile_index = { 4'd0, (5'd15 - { 1'b0, eff_col }) } * 9'd32 + { 5'd0, row };
    // ^ (15-col)*32 + row, per TILEMAP_SCAN_COLS_FLIP_X

    reg [1:0] plane_idx;
    reg       half_idx;
    reg [7:0] right_byte [0:2];
    reg [7:0] left_byte  [0:2];
    reg [8:0] code;

    wire [16:0] plane_base = { 2'b00, code, 5'd0 } + (plane_idx * 17'd16384);
    wire [16:0] byte_addr  = plane_base + (half_idx ? (17'd16 + { 13'd0, tile_line })
                                                     : { 13'd0, tile_line });

    localparam S_IDLE        = 4'd0,
               S_CODE_READ   = 4'd1,
               S_FETCH_REQ   = 4'd5,
               S_FETCH_WAIT  = 4'd6,
               S_FETCH_NEXT  = 4'd7,
               S_STORE_COL   = 4'd8,
               S_NEXT_COL    = 4'd9,
               S_DONE        = 4'd10;
    reg [3:0] state;

    reg [3:0] col_idx;
    reg [2:0] tile_pixel;
    reg [8:0] dest_x_pre, dest_x;
    integer i;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state   <= S_IDLE;
            done    <= 1'b0;
            gfx2_cs <= 1'b0;
            col     <= 4'd0;
        end else begin
            done <= 1'b0;
            case (state)
                S_IDLE: begin
                    gfx2_cs <= 1'b0;
                    if (start) begin
                        col   <= 4'd0;
                        state <= S_CODE_READ;
                    end
                end

                S_CODE_READ: begin
                    code <= { bg_videoram_shadow[code_hi_addr][0], bg_videoram_shadow[code_lo_addr] };
                    plane_idx <= 2'd0;
                    half_idx  <= 1'b0;
                    state <= S_FETCH_REQ;
                end

                S_FETCH_REQ: begin
                    gfx2_addr <= byte_addr[16:1];
                    gfx2_cs   <= 1'b1;
                    state     <= S_FETCH_WAIT;
                end
                S_FETCH_WAIT: begin
                    if (gfx2_ok) begin
                        if (half_idx)
                            left_byte[plane_idx]  <= byte_addr[0] ? gfx2_data[15:8] : gfx2_data[7:0];
                        else
                            right_byte[plane_idx] <= byte_addr[0] ? gfx2_data[15:8] : gfx2_data[7:0];
                        gfx2_cs <= 1'b0;
                        state   <= S_FETCH_NEXT;
                    end
                end
                S_FETCH_NEXT: begin
                    if (plane_idx == 2'd2) begin
                        if (half_idx) begin
                            state <= S_STORE_COL;
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

                S_STORE_COL: begin
                    for (i = 0; i < 16; i = i + 1) begin
                        col_idx = flip ? (4'd15 - i[3:0]) : i[3:0];
                        if (col_idx < 4'd8)
                            tile_pixel = { left_byte[2][7-col_idx[2:0]], left_byte[1][7-col_idx[2:0]], left_byte[0][7-col_idx[2:0]] };
                        else
                            tile_pixel = { right_byte[2][7-col_idx[2:0]], right_byte[1][7-col_idx[2:0]], right_byte[0][7-col_idx[2:0]] };
                        dest_x_pre = { 5'd0, col } * 9'd16 + i[8:0];
                        dest_x = flip ? (9'd255 - dest_x_pre) : dest_x_pre;
                        if (dest_x < 9'd256)
                            line_pxl[dest_x[7:0]] <= tile_pixel;
                    end
                    state <= S_NEXT_COL;
                end

                S_NEXT_COL: begin
                    if (col == 4'd15) begin
                        state <= S_DONE;
                    end else begin
                        col   <= col + 4'd1;
                        state <= S_CODE_READ;
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
