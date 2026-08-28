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

// Splash! pixel bitmap layer: 512x256, one pixel per 16-bit word (low byte)
// drawn directly by the 68000. Always opaque, at the very back
// MAME: pixelram[((y & 0xff) << 9) + ((x + 9) & 0x1ff)], palette 0x300 + pixel

module jtsplash_bitmap #(
    parameter [8:0] XADJ = 9'd12
)(
    input             clk,
    input             pxl_cen,
    input      [8:0]  hdump,
    input      [8:0]  vdump,

    output     [17:1] pxlram_addr,
    input      [15:0] pxlram_data,

    output reg [7:0]  pxl
);

// prefetch one pixel ahead, the BRAM takes 2 clock cycles (latched output)
wire [8:0] sx = hdump + 9'd1 + XADJ;
wire [7:0] sy = vdump[7:0] + 8'd16;

assign pxlram_addr = { sy, sx };

always @(posedge clk) if (pxl_cen) pxl <= pxlram_data[7:0];

endmodule
