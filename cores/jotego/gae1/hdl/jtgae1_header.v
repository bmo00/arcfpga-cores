/* SPDX-FileCopyrightText: 2026 Jose Tejada Gomez
 * SPDX-License-Identifier: GPL-3.0-or-later
 * Date: 29-3-2025 */

module jtgae1_header(
    input            clk,
                     header, prog_we,
    
    output reg       squash=0,
    output reg       thoop=0,
    output reg       biomtoy=0,
    output reg       bigkarnk=0,
    output reg       vcrypt=0,
    output reg [5:0] vram_p1=0,
    output reg       gfx_4m=0,
    output reg [5:0] spr_force_high=0,
    input      [2:0] prog_addr,
    input      [7:0] prog_data
);

always @(posedge clk) begin
    if( header && prog_addr[2:0]==0 && prog_we )
        squash <= prog_data[0];
    if( header && prog_addr[2:0]==0 && prog_we )
        thoop <= prog_data[1];
    if( header && prog_addr[2:0]==0 && prog_we )
        biomtoy <= prog_data[2];
    if( header && prog_addr[2:0]==0 && prog_we )
        bigkarnk <= prog_data[4];
    if( header && prog_addr[2:0]==0 && prog_we )
        vcrypt <= prog_data[3];
    if( header && prog_addr[2:0]==1 && prog_we )
        vram_p1 <= prog_data[5:0];
    if( header && prog_addr[2:0]==2 && prog_we )
        gfx_4m <= prog_data[0];
    if( header && prog_addr[2:0]==3 && prog_we )
        spr_force_high <= prog_data[5:0];
end

endmodule
