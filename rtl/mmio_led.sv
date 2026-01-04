// -----------------------------------------------------------------------------
// Simple MMIO LED Register
// -----------------------------------------------------------------------------
// Address: 0x1000_0000
//
// - Write: stores the written value into an internal register
// - Read : returns the stored value
// - One-cycle ready response
//
// This is a minimal, well-behaved memory-mapped peripheral.
// -----------------------------------------------------------------------------

module mmio_led #(
    parameter BASE_ADDR = 32'h1000_0000 //lets you move the parameter without rewriting logic
)(
    input  logic        clk,
    input  logic        valid,     // CPU is requesting an access
    input  logic [31:0] addr,      // byte address
    input  logic [31:0] wdata,     // data from CPU
    input  logic [3:0]  wstrb,     // byte write strobes

    output logic [31:0] rdata,     // data returned to CPU
    output logic        ready      // handshake response
);

    // Internal register representing the LED state
    logic [31:0] led_reg;

    // Address match signal
    wire addr_hit = (addr == BASE_ADDR); //ensures that peripheral only responds to its assigned address

    // Sequential logic: one-cycle response
    always_ff @(posedge clk) begin
        // Default outputs
        ready <= 1'b0;
        rdata <= 32'b0;

        if (valid && addr_hit) begin
            // Handle writes
            if (|wstrb) begin //tells us this is a write, same logic as SRAM
                if (wstrb[0]) led_reg[ 7: 0] <= wdata[ 7: 0];
                if (wstrb[1]) led_reg[15: 8] <= wdata[15: 8];
                if (wstrb[2]) led_reg[23:16] <= wdata[23:16];
                if (wstrb[3]) led_reg[31:24] <= wdata[31:24];
            end

            // Handle reads (read-after-write is fine)
            rdata <= led_reg;

            // Signal completion
            ready <= 1'b1;
        end
    end

endmodule
