module InstMem (
    input wire [31:0] addr_i,
    output reg [31:0] inst_o
);
	always @(*)
		case (addr_i[9:2])
            8'd0:   inst_o <= 32'b00100000000001000000000000000101;
            8'd1:   inst_o <= 32'b00000000000000000001000000100110;
            8'd2:   inst_o <= 32'b00001100000000000000000000000100;
            8'd3:   inst_o <= 32'b00010000000000001111111111111111;
            8'd4:   inst_o <= 32'b00100011101111011111111111111000;
            8'd5:   inst_o <= 32'b10101111101111110000000000000100;
            8'd6:   inst_o <= 32'b10101111101001000000000000000000;
            8'd7:   inst_o <= 32'b00101000100010000000000000000001;
            8'd8:   inst_o <= 32'b00010001000000000000000000000010;
            8'd9:   inst_o <= 32'b00100011101111010000000000001000;
            8'd10:   inst_o <= 32'b00000011111000000000000000001000;
            8'd11:   inst_o <= 32'b00000000100000100001000000100000;
            8'd12:   inst_o <= 32'b00100000100001001111111111111111;
            8'd13:   inst_o <= 32'b00001100000000000000000000000100;
            8'd14:   inst_o <= 32'b10001111101001000000000000000000;
            8'd15:   inst_o <= 32'b10001111101111110000000000000100;
            8'd16:   inst_o <= 32'b00100011101111010000000000001000;
            8'd17:   inst_o <= 32'b00000000100000100001000000100000;
            8'd18:   inst_o <= 32'b00000011111000000000000000001000;
			default: inst_o <= 32'h00000000;
		endcase
		
endmodule