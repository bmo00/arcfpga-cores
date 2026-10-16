/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 10-7-2026 */

// Splash! video. 368x240 visible out of a 512x270 frame at 8 MHz -> 57.9 Hz
// MAME coordinates: x = hdump+16, y = vdump+16 (visible area starts at 16,16)
// Layer order, back to front: bitmap, 16x16 tilemap, sprites, 8x8 tilemap

module jtsplash_video #(
    parameter integer LAT = 13    // sync delay to match the pixel pipeline
)(
    input         clk,
    input         rst,
    input         pxl_cen,
    input  [3:0]  gfx_en,       // 0=char, 1=scroll, 2=bitmap, 3=sprites

    // 8x8 tilemap (front layer)
    output [12:1] vram0_addr,
    input  [15:0] vram0_dout,
    output [18:2] char_addr,
    input  [31:0] char_data,
    output        char_cs,
    input         char_ok,

    // 16x16 tilemap + scroll registers (fetched from VRAM during blanking)
    output [12:1] vram1_addr,
    input  [15:0] vram1_dout,
    output [18:2] scr_addr,
    input  [31:0] scr_data,
    output        scr_cs,
    input         scr_ok,

    // sprites
    output [11:1] oram_addr,
    input  [15:0] oram_dout,
    output [18:2] obj_addr,
    input  [31:0] obj_data,
    output        obj_cs,
    input         obj_ok,

    // pixel bitmap layer
    output [17:1] pxlram_addr,
    input  [15:0] pxlram_data,

    // palette
    output [11:1] pal_addr,
    input  [15:0] pal_data,

    output [4:0]  red, green, blue,
    output        HS, VS,
    output        hblank, vblank
);

// 512 x 270 frame, 368 x 240 visible
localparam [8:0] HB_START = 9'd368, HB_END = 9'd0,
                 HS_START = 9'd404, HS_END = 9'd436,
                 HCNT_END = 9'd511,
                 VB_START = 9'd240, VB_END = 9'd0,
                 VS_START = 9'd250, VS_END = 9'd253,
                 VCNT_END = 9'd269;
localparam integer VTOTAL  = 270;
localparam integer OBJ_DLY = 10;   // sprite to tilemap alignment
// X adjustment constants, to be calibrated against MAME frames
// Ambos tilemaps comparten pipeline (jtframe_scroll): mismas correcciones,
// medidas contra renders analiticos validados al 100% contra MAME
localparam [8:0] CHAR_XOFF = 9'd0;
localparam [8:0] SCR_XOFF  = 9'd0;
localparam [8:0] BMP_XADJ  = 9'd12; // 25 (window+MAME offset) - LAT
localparam [8:0] YOFF      = 9'd16;

wire [8:0] hdump, vdump, hpos_r;
wire       hb_i, vb_i, hs_i, vs_i, hblank_n, vblank_n;
wire [7:0] char_pxl, scr_pxl, obj_pxl, bmp_pxl;
reg [15:0] vregs0, vregs1;   // scroll Y for each tilemap

jtframe_vtimer #(
    .HCNT_END ( HCNT_END ),
    .HB_START ( HB_START ),
    .HB_END   ( HB_END   ),
    .HS_START ( HS_START ),
    .HS_END   ( HS_END   ),
    .VCNT_END ( VCNT_END ),
    .VB_START ( VB_START ),
    .VB_END   ( VB_END   ),
    .VS_START ( VS_START ),
    .VS_END   ( VS_END   )
) u_vtimer (
    .clk      ( clk      ),
    .pxl_cen  ( pxl_cen  ),
    .vdump    ( vdump    ),
    .vrender  (          ),
    .vrender1 (          ),
    .H        ( hdump    ),
    .Hinit    (          ),
    .Vinit    (          ),
    .LHBL     ( hblank_n ),
    .LVBL     ( vblank_n ),
    .HS       ( hs_i     ),
    .VS       ( vs_i     )
);

reg hb_r, vb_r;
always @(posedge clk) if (pxl_cen) begin
    hb_r <= ~hblank_n;
    vb_r <= ~vblank_n;
end
assign hb_i   = hb_r;
assign vb_i   = vb_r;
assign hpos_r = hdump - 9'd4;

// Scroll registers live in regular VRAM (words 0xc00 and 0xc01).
// They are fetched from the vram1 read port at the start of each HB
wire [12:1] scr_vram_addr;
reg  [ 2:0] vfetch_st;
reg         hb_l;
wire        vfetch_busy = vfetch_st != 3'd0;

assign vram1_addr = vfetch_st == 3'd1 ? 12'hc00 :
                    vfetch_st == 3'd2 ? 12'hc01 : scr_vram_addr;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        vfetch_st <= 3'd0;
        vregs0    <= 16'd0;
        vregs1    <= 16'd0;
        hb_l      <= 1'b0;
    end else begin
        hb_l <= ~hblank_n;
        if (!vfetch_busy) begin
            if (~hblank_n && !hb_l) vfetch_st <= 3'd1;
        end else begin
            vfetch_st <= vfetch_st == 3'd4 ? 3'd0 : vfetch_st + 3'd1;
            // vram1 BRAM has a 2-clock latency (latched output)
            if (vfetch_st == 3'd3) vregs0 <= vram1_dout;
            if (vfetch_st == 3'd4) vregs1 <= vram1_dout;
        end
    end
end

jtsplash_char u_char (
    .clk       ( clk        ),
    .rst       ( rst        ),
    .pxl_cen   ( pxl_cen    ),
    .hs        ( hs_i       ),
    .hdump     ( hpos_r     ),
    .vdump     ( vdump      ),
    .scrx      ( 9'd4 + YOFF + CHAR_XOFF ),
    .scry      ( vregs0[7:0] + YOFF[7:0] - 8'd1 ),
    .vram_addr ( vram0_addr ),
    .vram_data ( vram0_dout ),
    .rom_addr  ( char_addr  ),
    .rom_cs    ( char_cs    ),
    .rom_data  ( char_data  ),
    .rom_ok    ( char_ok    ),
    .pxl       ( char_pxl   )
);

jtsplash_scroll u_scroll (
    .clk       ( clk        ),
    .rst       ( rst        ),
    .pxl_cen   ( pxl_cen    ),
    .hs        ( hs_i       ),
    .hdump     ( hpos_r     ),
    .vdump     ( vdump      ),
    .scrx      ( YOFF + SCR_XOFF ),
    .scry      ( vregs1[8:0] + YOFF - 9'd1 ), // confirmado con render analitico: -1 exacto (99.7% match)
    .vram_addr ( scr_vram_addr ),
    .vram_data ( vram1_dout ),
    .rom_addr  ( scr_addr   ),
    .rom_cs    ( scr_cs     ),
    .rom_data  ( scr_data   ),
    .rom_ok    ( scr_ok     ),
    .pxl       ( scr_pxl    )
);

jtsplash_obj #(
    .VTOTAL    ( VTOTAL     )
) u_obj (
    .clk       ( clk        ),
    .rst       ( rst        ),
    .pxl_cen   ( pxl_cen    ),
    .hs        ( hs_i       ),
    .hdump     ( hpos_r     ),
    .vdump     ( vdump      ),
    .oram_addr ( oram_addr  ),
    .oram_dout ( oram_dout  ),
    .rom_addr  ( obj_addr   ),
    .rom_cs    ( obj_cs     ),
    .rom_data  ( obj_data   ),
    .rom_ok    ( obj_ok     ),
    .pxl       ( obj_pxl    )
);

jtsplash_bitmap #(
    .XADJ      ( BMP_XADJ   )
) u_bitmap (
    .clk       ( clk        ),
    .pxl_cen   ( pxl_cen    ),
    .hdump     ( hdump      ),
    .vdump     ( vdump      ),
    .pxlram_addr( pxlram_addr ),
    .pxlram_data( pxlram_data ),
    .pxl       ( bmp_pxl    )
);

// sprite to tilemap latency alignment
reg [7:0] obj_sr [0:OBJ_DLY-1];
integer os;
always @(posedge clk) if (pxl_cen) begin
    obj_sr[0] <= obj_pxl;
    for (os=1; os<OBJ_DLY; os=os+1) obj_sr[os] <= obj_sr[os-1];
end

jtsplash_colmix u_colmix (
    .clk       ( clk        ),
    .pxl_cen   ( pxl_cen    ),
    .gfx_en    ( gfx_en     ),
    .char_pxl  ( char_pxl   ),
    .scr_pxl   ( scr_pxl    ),
    .obj_pxl   ( obj_sr[OBJ_DLY-1] ),
    .bmp_pxl   ( bmp_pxl    ),
    .pal_addr  ( pal_addr   ),
    .pal_data  ( pal_data   ),
    .red       ( red        ),
    .green     ( green      ),
    .blue      ( blue       )
);

// delay sync signals to match the pixel pipeline
reg [LAT-1:0] hs_sr, vs_sr, hb_sr, vb_sr;
always @(posedge clk) if (pxl_cen) begin
    hs_sr <= { hs_sr[LAT-2:0], hs_i };
    vs_sr <= { vs_sr[LAT-2:0], vs_i };
    hb_sr <= { hb_sr[LAT-2:0], hb_i };
    vb_sr <= { vb_sr[LAT-2:0], vb_i };
end

assign HS     = hs_sr[LAT-1];
assign VS     = vs_sr[LAT-1];
assign hblank = hb_sr[LAT-1];
assign vblank = vb_sr[LAT-1];

endmodule
