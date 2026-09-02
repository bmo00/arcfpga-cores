/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jttaitox_header(
    input            clk,
                     header, prog_we,
    
    output reg       cchip=0,
    output reg       ym2151=0,
    input      [3:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[3:0]==0 && prog_we )
        cchip <= prog_data[0];
    if( header && prog_addr[3:0]==0 && prog_we )
        ym2151 <= prog_data[1];
end

endmodule
