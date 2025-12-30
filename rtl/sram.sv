// Module declaration called sram
module sram #(
        

    parameter ADDR_WIDTH = 14,  // 2^14 = 16384 words, each word is 4 bytes,
                               // 16384 × 4 = 65536 bytes = 64 KB
    // Optional hex file to preload memory (simulation only)
    // Example: "software/loop.hex"
    parameter MEM_INIT_HEX = "software/ram_test.hex"
)(
    input logic clk, //clk where all memory behavior is sychnronized to this signal 
                    //( in hardware, flip-flops triggered in rising edge)
    input logic valid, // indicated CPU is requesting a memory operation when valid is high
    input  logic [31:0] addr, // 32-bit byte address from CPU , will convert to words address later
    input  logic [31:0] wdata, // data to be written to memory (from CPU register)
    input  logic [3:0] wstrb, // each bit corresponds to one byte;
                              //(wstrb[0] -> byte 0 (bits 7:0)....wstrb[3] -> byte 3 (bits 31:24)
                              //0000 means read, 1111 means write full word, 0001 means write lowest byte
    output logic [31:0] rdata, // Data returned to CPU on a read, samples when ready=1
    output logic        ready //Handshake response back to CPU , ready=1 means memory access is complete
);

    logic valid_q;  // delayed valid, used to generate 1-cycle-late ready
//Internal memory array declaration
    logic [31:0] mem [0:(1<<ADDR_WIDTH)-1];//Creates an array of registers, each entry is 32 bits wide
    //Address range is from 0 to (2^ADDR_WIDTH - 1) with ADDR_WIDTH = 14
    //This is actual RAM storage, in FPGA this maps to BRAM

//Address translation: convert byte address to word address
    wire [ADDR_WIDTH-1:0] word_addr = addr[ADDR_WIDTH+1:2]; // CPU gives byte address, memory array is word-indexed
    //Example: addr = 0x000_0000 -> word_addr = 0, addr = 0x000_0004 -> word_addr = 1

//assign ready = valid; // ready signal generation, if CPU asserts valid, SRAM will respond in same cycle with ready
                    //creates 1-cycle latency memory
//The sequential logic ( the actual memory behavior)
    always_ff @(posedge clk) begin //everything inside happens on the rising edge of the clk, sequential logic, hardware = flip-flops + memory
        ready   <= valid_q;
        valid_q <= valid;

        if (valid) begin //only do anything if CPU requesting access
        rdata <= mem[word_addr]; //Default read behavior, reads the memory word, places it on rdata bus, CPU will sample it when ready is high
            if (|wstrb) begin // |wstrb = OR-reduction, Means: “is any write byte enabled?” (if yes then this is write operation)
               
                //Byte-selective writes
                if (wstrb[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0];//writes lowest byte
                if (wstrb[1]) mem[word_addr][15: 8] <= wdata[15: 8];//writes byte 1
                if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];//writes byte 2
                if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];//writes byte 3
                
            end else begin
    
        end
    end

    end

/*
    --------------------------------------------------------------------------
    SIMULATION-ONLY MEMORY PRELOAD
    --------------------------------------------------------------------------
    - Loads a .hex file into memory at time 0
    - Ignored by synthesis tools
    - This is how we load programs into SRAM during simulation
    */
    `ifndef SYNTHESIS//initial block is ignored by synthesis tools, so this method used instead, works for simulation and FPGA synthesis
    initial begin
        valid_q = 0;
        ready   = 0;
        rdata   = 0;
        if (MEM_INIT_HEX != "") begin
            $display("[SRAM] Preloading memory from %s", MEM_INIT_HEX);
            $readmemh(MEM_INIT_HEX, mem);
        end
    end
    `endif

endmodule

//Summary: This SRAM:
//accepts cpu requests synchronized to clk
//converts byte address to word address
//Supports byte writes
//Responds in one cycle
//Simple, predictable, correct
//We start with this because its easy to understand, works well in simulation, sythesizes to FPGA BRAM cleanly



