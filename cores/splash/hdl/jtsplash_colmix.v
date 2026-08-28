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

// Splash! color mixer. Layer priority from front to back:
// 8x8 tilemap, sprites, 16x16 tilemap, bitmap (always opaque)
// Palette regions: tilemaps 0x000-0x0ff, sprites 0x100-0x1ff,
// bitmap 0x300-0x3ff. 2048 entries of xRGB555

module jtsplash_colmix (
    input         clk,
    input         pxl_cen,
    input  [3:0]  gfx_en,   // 0=char, 1=scroll, 2=bitmap, 3=sprites

    input  [7:0]  char_pxl,
    input  [7:0]  scr_pxl,
    input  [7:0]  obj_pxl,
    input  [7:0]  bmp_pxl,

    output reg [11:1] pal_addr,
    input  [15:0] pal_data,

    output reg [4:0]  red, green, blue
);

wire char_op = gfx_en[0] && char_pxl[3:0] != 4'd0;
wire obj_op  = gfx_en[3] && obj_pxl[3:0]  != 4'd0;
wire scr_op  = gfx_en[1] && scr_pxl[3:0]  != 4'd0;

always @(posedge clk) if (pxl_cen) begin
    pal_addr <= char_op   ? { 3'b000, char_pxl } :
                obj_op    ? { 3'b001, obj_pxl  } :
                scr_op    ? { 3'b000, scr_pxl  } :
                gfx_en[2] ? { 3'b011, bmp_pxl  } : 11'd0;
    // the palette BRAM takes 2 clocks, sampled at the next pxl_cen
    { red, green, blue } <= pal_data[14:0];
end

endmodule
