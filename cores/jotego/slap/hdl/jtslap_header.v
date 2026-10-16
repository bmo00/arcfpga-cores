/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jtslap_header(
    input            clk,
                     header, prog_we,
    
    output reg       a76=0,
    output reg       tigerh=0,
    input      [3:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[3:0]==12 && prog_we )
        a76 <= prog_data[0];
    if( header && prog_addr[3:0]==12 && prog_we )
        tigerh <= prog_data[1];
end

endmodule
