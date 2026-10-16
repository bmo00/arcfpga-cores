/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

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
