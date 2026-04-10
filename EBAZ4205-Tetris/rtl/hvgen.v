module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 		       	PCLK,
	input	   [7:0]	iRGB,

	output reg [7:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1,
	
	input   [8:0]		HOFFS
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt-1;
assign VPOS = vcnt;

wire [8:0] HS_B = 360+(HOFFS*2);
wire [8:0] HS_E =  24+(HS_B);
wire [8:0] HS_N = 511-(456-HS_E);

always @(posedge PCLK) begin
	case (hcnt)
		  0: begin HBLK <= 0; hcnt <= hcnt+1; end
		337: begin HBLK <= 1; hcnt <= hcnt+1; end
		511: begin hcnt <= 0;
			case (vcnt)
				239: begin VBLK <= 1; vcnt <= vcnt+1; end
				240: begin VSYN <= 0; vcnt <= vcnt+1; end
				243: begin VSYN <= 1; vcnt <= vcnt+1; end
				261: begin VBLK <= 0; vcnt <= 0;      end
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase

	if (hcnt==HS_B) begin HSYN <= 0; end
	if (hcnt==HS_E) begin HSYN <= 1; hcnt <= HS_N; end

	oRGB <= (HBLK|VBLK) ? 8'h0 : iRGB;
end

endmodule
