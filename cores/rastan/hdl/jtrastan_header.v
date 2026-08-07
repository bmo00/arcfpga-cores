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

module jtrastan_header(
    input            clk,
                     header, prog_we,
    
    output reg       rastan=0,
    output reg       opwolf=0,
    output reg       rbisland=0,
    output reg       cchip=0,
    output reg [7:0] gun_xoff8=0,
    output reg [7:0] gun_yoff8=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==0 && prog_we )
        rastan <= prog_data[0];
    if( header && prog_addr[2:0]==0 && prog_we )
        opwolf <= prog_data[1];
    if( header && prog_addr[2:0]==0 && prog_we )
        rbisland <= prog_data[2];
    if( header && prog_addr[2:0]==0 && prog_we )
        cchip <= prog_data[3];
    if( header && prog_addr[2:0]==1 && prog_we )
        gun_xoff8 <= prog_data[7:0];
    if( header && prog_addr[2:0]==2 && prog_we )
        gun_yoff8 <= prog_data[7:0];
end

endmodule
