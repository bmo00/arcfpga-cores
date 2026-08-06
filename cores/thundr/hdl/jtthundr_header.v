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
    Date: 29-3-2025 */

module jtthundr_header(
    input            clk,
                     header, prog_we,
    
    output reg       only2bpp=0,
    output reg       sndext_en=0,
    output reg       nocpu2=0,
    output reg       mcualt=0,
    output reg       scrhflip=0,
    output reg       plane3inv=0,
    output reg       roishtar=0,
    output reg       genpeitd=0,
    output reg       wndrmomo=0,
    output reg       metrocrs=0,
    output reg [8:0] objhos=0,
    output reg [7:0] objvos=0,
    output reg [3:0] scrhos=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==1 && prog_we )
        only2bpp <= prog_data[0];
    if( header && prog_addr[2:0]==1 && prog_we )
        sndext_en <= prog_data[1];
    if( header && prog_addr[2:0]==1 && prog_we )
        nocpu2 <= prog_data[2];
    if( header && prog_addr[2:0]==1 && prog_we )
        mcualt <= prog_data[3];
    if( header && prog_addr[2:0]==1 && prog_we )
        scrhflip <= prog_data[4];
    if( header && prog_addr[2:0]==1 && prog_we )
        plane3inv <= prog_data[5];
    if( header && prog_addr[2:0]==2 && prog_we )
        roishtar <= prog_data[0];
    if( header && prog_addr[2:0]==2 && prog_we )
        genpeitd <= prog_data[1];
    if( header && prog_addr[2:0]==2 && prog_we )
        wndrmomo <= prog_data[2];
    if( header && prog_addr[2:0]==2 && prog_we )
        metrocrs <= prog_data[3];
    if( header && prog_addr[2:0]==2 && prog_we )
        objhos[8] <= prog_data[7];
    if( header && prog_addr[2:0]==3 && prog_we )
        objhos[7:0] <= prog_data[7:0];
    if( header && prog_addr[2:0]==4 && prog_we )
        objvos <= prog_data[7:0];
    if( header && prog_addr[2:0]==6 && prog_we )
        scrhos <= prog_data[3:0];
end

endmodule
