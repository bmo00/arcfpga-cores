/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jtskykid_header(
    input            clk,
                     header, prog_we,
    
    output reg       rot180=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==1 && prog_we )
        rot180 <= prog_data[0];
end

endmodule
