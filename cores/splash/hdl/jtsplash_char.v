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

// Splash! 8x8 tilemap (front layer), 64x32 map at VRAM words 0x000-0x7ff
// VRAM word: bits 15-12 = palette, 11-8 = code high, 7-0 = code low
// The tile code adds a fixed 0x2000 bank. No tile flipping. Pen 0 transparent
// Fixed scroll X of 4 pixels plus scroll Y from vregs[0]

module jtsplash_char (
    input         clk,
    input         rst,
    input         pxl_cen,
    input         hs,
    input  [8:0]  hdump,
    input  [8:0]  vdump,
    input  [8:0]  scrx,
    input  [7:0]  scry,

    output [12:1] vram_addr,
    input  [15:0] vram_data,

    output [18:2] rom_addr,
    output        rom_cs,
    input  [31:0] rom_data,
    input         rom_ok,

    output [7:0]  pxl
);

wire [10:0] va;
wire [13:0] code = { 2'b10, vram_data[11:8], vram_data[7:0] };
wire [ 3:0] pal  = vram_data[15:12];

assign vram_addr = { 1'b0, va };

jtframe_scroll #(
    .SIZE   (  8 ),
    .VA     ( 11 ),
    .CW     ( 14 ),
    .PW     (  8 ),
    .MAP_HW (  9 ),
    .MAP_VW (  8 )
) u_scroll (
    .rst       ( rst       ),
    .clk       ( clk       ),
    .pxl_cen   ( pxl_cen   ),

    .hs        ( hs        ),
    .vdump     ( vdump     ),
    .hdump     ( hdump     ),
    .blankn    ( 1'b1      ),
    .flip      ( 1'b0      ),
    .scrx      ( scrx      ),
    .scry      ( scry      ),

    .vram_addr ( va        ),

    .code      ( code      ),
    .pal       ( pal       ),
    .hflip     ( 1'b0      ),
    .vflip     ( 1'b0      ),

    .rom_addr  ( rom_addr  ),
    .rom_data  ( rom_data  ),
    .rom_cs    ( rom_cs    ),
    .rom_ok    ( rom_ok    ),

    .pxl       ( pxl       )
);

endmodule
