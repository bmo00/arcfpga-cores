/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jtblkout_header(
    input            clk,
                     header, prog_we,
    
    output reg       blockout=0,
    output reg       blockoutj=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==0 && prog_we )
        blockout <= prog_data[0];
    if( header && prog_addr[2:0]==0 && prog_we )
        blockoutj <= prog_data[1];
end

endmodule
