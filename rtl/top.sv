//SoC integration layer: 
//instantiates the CPU, memory, wires them together, defines clock + reset behavior
//Does not implement the logic itself, connects the block ( like a mother board)
module top (
    input logic clk, //system clk
    input logic reset //synchronous reset ( active high)
    //these are ohysical wires, in simulation they are driven by testbench, in FPGA they are connected to pins or PLLs
);
    logic        mem_valid; //asserted by CPU - "i want to access memory" ( in hardware its single wire from CPU to memory system)
    logic        mem_ready; //Asserted by memory, "memory access is complete" ( in hardware its single wire from memory system to CPU)
    logic [31:0] mem_addr;//32-bit b yte address, used for instruction fetch and data load/store ( in hardware its a 32-bit bus from CPU to memory system)
    logic [31:0] mem_wdata;//data written from CPU to memory
    logic [3:0]  mem_wstrb;//byte-enable signals for write operations ( in hardware its a 4-bit bus from CPU to memory system)
    logic [31:0] mem_rdata;//Data returned from memory to CPU, used for instruction fetch and data load ( in hardware its a 32-bit bus from memory system to CPU)
    
    //Instantiate the PicoRV32 module, creates the actual hardware for the CPU
    //Everyhting inside this instance is a real processor
    picorv32 cpu (
        .clk         (clk), //Connects SoC clk to CPU clk input ( all CPU logic runs on this clock)
        .resetn      (!reset), // reset connection, active low in CPU, active high in SoC ( this inversion is very common in integration work)
      
        //Memory interface connections for the CPU memory system
        .mem_valid   (mem_valid),//CPU drives this, requests memory access
        .mem_ready   (mem_ready),//memory drives this, tells CPU when access completes
        .mem_addr    (mem_addr),//CPU provides the address
        .mem_wdata   (mem_wdata),//CPU provides write data
        .mem_wstrb   (mem_wstrb),//CPU provides byte-enable signals
        .mem_rdata   (mem_rdata),//Memory returns read data

        .irq         (32'b0),//PicoRV32 supports 32 interrupt lines, we tie them all to 0. This means no interrupts yet ( keeps CPU in pure polling mode)
        .eoi         ()//end of interrupt signal, not used here, left unconnected
        //Debug tracing outputs, useful for advanced debugging 
        .trace_valid (),
        .trace_data  ()
    );
//SRAM instantiation, this creates a block of memory that the CPU can use for instructions and data
    sram ram(
        .clk   (clk), //same clock as CPU
        .valid (mem_valid),//SRAM sees when CPU wants to access memory
        .addr  (mem_addr),//same address CPU generated 
        .wdata (mem_wdata),//data CPU wants to write
        .wstrb (mem_wstrb),//byte-enable signals from CPU
        .rdata (mem_rdata),//SRAM returns read value, goes directly to CPU
        .ready (mem_ready)//SRAM tells CPU access is complete
    );
endmodule

//This is a real computer, capable of running software compiled for RISC-V
//The CPU is connected to a block of SRAM memory
//No peripherals yet, no I/O, no interrupts
//This is the top-level module that would be synthesized onto an FPGA or ASIC
//We isolate:CPU correctness, memory correctness, handshake correctness, Before adding complexity.

//How the CPU talks to memory:
// PicoRV32 CPU and the SRAM communicate using 6 signals
//| Signal      | Direction  | Meaning                   |
//| ----------- | ---------- | ------------------------- |
//| `mem_valid` | CPU → SRAM | “I want to access memory” |
//| `mem_addr`  | CPU → SRAM | Address (byte address)    |
//| `mem_wdata` | CPU → SRAM | Data to write             |
//| `mem_wstrb` | CPU → SRAM | Which bytes to write      |
//| `mem_rdata` | SRAM → CPU | Data read                 |
//| `mem_ready` | SRAM → CPU | “Access is complete”      |

//The CPU does not know what “SRAM” is. It only knows that when it asserts mem_valid, someone will eventually assert mem_ready.




