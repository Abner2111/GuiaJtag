//LEDs interface with JTAG - SystemVerilog Version
//Basado en trabajo por xharrym 2014
//Convertido a SystemVerilog con mejoras modernas

//INSTRUCCIONES:
//00: bypass
//01: leer dip-switch  
//10: actualizar LEDs
//11: not used (=bypass)

module connect(
	input  logic        tck,           // JTAG clock
	input  logic        tdi,           // JTAG data input
	input  logic        aclr,          // Asynchronous clear (active low)
	input  logic [1:0]  ir_in,         // Instruction register input
	input  logic        v_sdr,         // Virtual shift DR
	input  logic        v_udr,         // Virtual update DR  
	input  logic        v_cdr,         // Virtual capture DR
	input  logic        v_uir,         // Virtual update IR
	input  logic [3:0]  switches,      // DIP switches {s4,s3,s2,s1}
	output logic        tdo,           // JTAG data output
	output logic [7:0]  leds           // LED outputs {d7,d6,d5,d4,d3,d2,d1,d0}
);

	// Enumerated type for JTAG instructions
	typedef enum logic [1:0] {
		BYPASS = 2'b00,
		DIP    = 2'b01, 
		LED    = 2'b10
	} jtag_instr_e;
	
	// Internal registers
	logic [1:0] DR0;                   // Bypass data register
	logic [7:0] DR1;                   // Main data register  
	logic [7:0] led_output_reg;        // LED output register
	
	// Convert instruction input to enum
	jtag_instr_e current_instr;
	assign current_instr = jtag_instr_e'(ir_in);
	
	// TDO multiplexer - combinational logic
	always_comb begin
		case (current_instr)
			BYPASS:  tdo = DR0[0];
			default: tdo = DR1[0];  // DIP and LED both use DR1
		endcase
	end
	
	// LED output assignment
	assign leds = led_output_reg;

	// JTAG data register operations - sequential logic
	always_ff @(posedge tck or negedge aclr) begin
		if (!aclr) begin
			// Asynchronous reset
			DR0 <= '0;
			DR1 <= '0;
		end
		else begin
			// Synchronous operations based on current instruction
			case (current_instr)
				DIP: begin
					if (v_cdr) begin
						// Capture switch values into DR1
						DR1 <= {4'b0000, switches};
					end
					else if (v_sdr) begin
						// Shift operation for reading
						DR1 <= {tdi, DR1[7:1]};
					end
				end
				
				LED: begin
					if (v_sdr) begin
						// Shift operation for writing
						DR1 <= {tdi, DR1[7:1]};
					end
				end
				
				BYPASS: begin
					if (v_sdr) begin
						// Bypass shift operation
						DR0 <= {tdi, DR0[1]};
					end
				end
				
				default: begin
					// Default to bypass behavior
					if (v_sdr) begin
						DR0 <= {tdi, DR0[1]};
					end
				end
			endcase
		end
	end
	
	// LED output update logic - sequential logic
	always_ff @(posedge v_udr or negedge aclr) begin
		if (!aclr) begin
			led_output_reg <= '0;
		end
		else begin
			if (current_instr == LED) begin
				// Update LED outputs when instruction is LED and update DR is asserted
				led_output_reg <= DR1;
			end
		end
	end
	
endmodule