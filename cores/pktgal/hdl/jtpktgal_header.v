/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jtpktgal_header(
    input            clk,
                     header, prog_we,
    
    output reg       char_orig=0,
    output reg       char_bootleg=0,
    output reg       deco222=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==0 && prog_we )
        char_orig <= prog_data[0];
    if( header && prog_addr[2:0]==0 && prog_we )
        char_bootleg <= prog_data[1];
    if( header && prog_addr[2:0]==0 && prog_we )
        deco222 <= prog_data[2];
end

endmodule
