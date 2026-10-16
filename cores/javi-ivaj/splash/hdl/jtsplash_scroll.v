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

// Splash! 16x16 tilemap, 32x32 map at VRAM words 0x800-0xbff
// VRAM word: bits 15-12 = palette, 11-8 = code high, 7-2 = code low,
// bit 1 = hflip, bit 0 = vflip. Fixed 0xc00 code bank. Pen 0 transparent
// Scroll Y comes from vregs[1], no scroll X

module jtsplash_scroll (
    input         clk,
    input         rst,
    input         pxl_cen,
    input         hs,
    input  [8:0]  hdump,
    input  [8:0]  vdump,
    input  [8:0]  scrx,
    input  [8:0]  scry,

    output [12:1] vram_addr,
    input  [15:0] vram_data,

    output [18:2] rom_addr,
    output        rom_cs,
    input  [31:0] rom_data,
    input         rom_ok,

    output [7:0]  pxl
);

wire [ 9:0] va;
wire [11:0] code  = { 2'b11, vram_data[11:8], vram_data[7:2] };
wire [ 3:0] pal   = vram_data[15:12];
wire        hflip = vram_data[1];
wire        vflip = vram_data[0];

assign vram_addr = { 2'b10, va };

jtframe_scroll #(
    .SIZE   ( 16 ),
    .VA     ( 10 ),
    .CW     ( 12 ),
    .PW     (  8 ),
    .MAP_HW (  9 ),
    .MAP_VW (  9 )
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
    .hflip     ( hflip     ),
    .vflip     ( vflip     ),

    .rom_addr  ( rom_addr  ),
    .rom_data  ( rom_data  ),
    .rom_cs    ( rom_cs    ),
    .rom_ok    ( rom_ok    ),

    .pxl       ( pxl       )
);

endmodule
