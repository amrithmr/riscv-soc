`timescale 1ns/1ps

module tb_top;

    // ----------------------------
    // Clock and reset
    // ----------------------------
    logic clk = 0;
    logic resetn = 0;

    always #5 clk = ~clk; // 100 MHz clock

    // ----------------------------
    // DUT
    // ----------------------------
    top dut (
        .clk    (clk),
        .reset (resetn)
    );

    // ----------------------------
    // Waveform dump
    // ----------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

    // ----------------------------
    // Reset sequence
    // ----------------------------
    initial begin
        resetn = 0;
        repeat (5) @(posedge clk);
        resetn = 1;
        $display("INFO: Reset released");
    end

    // ----------------------------
    // Monitor memory interface
    // ----------------------------
    always @(posedge clk) begin
        if (resetn && dut.mem_valid) begin
            $display(
                "t=%0t addr=0x%08x wstrb=%b wdata=0x%08x ready=%b",
                $time,
                dut.mem_addr,
                dut.mem_wstrb,
                dut.mem_wdata,
                dut.mem_ready
            );
        end

        // Detect first STORE
        if (resetn && dut.mem_valid && |dut.mem_wstrb) begin
            $display("PASS: STORE observed!");
            $finish;
        end
    end

    // ----------------------------
    // Timeout protection
    // ----------------------------
    initial begin
        #5_000_000; // 5 ms sim time
        $display("FAIL: Timeout — no STORE observed");
        $finish;
    end

endmodule
