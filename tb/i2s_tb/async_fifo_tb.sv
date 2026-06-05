module async_fifo_tb;

    localparam DATA_WIDTH = 24;
    localparam DEPTH      = 16;

    logic                  wr_clk, rd_clk;
    logic                  wr_rst_n, rd_rst_n;
    logic                  wr_en,  rd_en;
    logic [DATA_WIDTH-1:0] wr_data, rd_data;
    logic                  full,   empty;

    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH)
    ) DUT (
        .wr_clk   (wr_clk),   .wr_rst_n (wr_rst_n),
        .wr_en    (wr_en),    .wr_data  (wr_data),
        .full     (full),
        .rd_clk   (rd_clk),   .rd_rst_n (rd_rst_n),
        .rd_en    (rd_en),    .rd_data  (rd_data),
        .empty    (empty)
    );

    initial wr_clk = 0;  always #162 wr_clk = ~wr_clk;
    initial rd_clk = 0;  always #4   rd_clk = ~rd_clk;

    task write_val(input logic [23:0] d);
        @(posedge wr_clk); #1;
        wr_en = 1; wr_data = d;
        @(posedge wr_clk); #1;
        wr_en = 0;
    endtask

    task read_val(input logic [23:0] expected);
        int timeout = 0;
        rd_en = 0;
        while (empty && timeout < 5000) begin
            @(posedge rd_clk); #1;
            timeout++;
        end
        if (timeout >= 5000) begin
            $display("FAIL: timed out waiting for data, expected 0x%06X", expected);
            return;
        end
        @(posedge rd_clk); #1;
        rd_en = 1;
        @(posedge rd_clk); #1;
        rd_en = 0;
        @(posedge rd_clk); #1;
        if (rd_data == expected)
            $display("PASS: got 0x%06X", rd_data);
        else
            $display("FAIL: expected 0x%06X got 0x%06X", expected, rd_data);
    endtask

    initial begin
        $dumpfile("async_fifo_tb.vcd");
        $dumpvars(0, async_fifo_tb);

        // initialise
        wr_en = 0; rd_en = 0; wr_data = 0;

        // apply reset to both domains
        wr_rst_n = 0; rd_rst_n = 0;
        repeat(10) @(posedge rd_clk);
        wr_rst_n = 1; rd_rst_n = 1;
        repeat(10) @(posedge rd_clk);

        // ?? TEST 1 ??????????????????????????????????????????????????
        $display("--- TEST 1: write 4 samples, read back ---");
        write_val(24'hABCDEF);
        write_val(24'h123456);
        write_val(24'hDEADBE);
        write_val(24'hCAFEBA);

        repeat(10) @(posedge rd_clk);

        read_val(24'hABCDEF);
        read_val(24'h123456);
        read_val(24'hDEADBE);
        read_val(24'hCAFEBA);

        // ?? TEST 2 ??????????????????????????????????????????????????
        $display("--- TEST 2: empty flag ---");
        repeat(10) @(posedge rd_clk);
        if (empty)
            $display("PASS: FIFO empty after reading all data");
        else
            $display("FAIL: FIFO should be empty");

        // ?? TEST 3 ??????????????????????????????????????????????????
        $display("--- TEST 3: fill 15 slots ---");
        repeat(15) write_val($urandom);
        repeat(10) @(posedge rd_clk);
        if (!full)
            $display("PASS: not full after 15 of 16 slots");
        else
            $display("FAIL: full flag wrong");

        $display("--- DONE ---");
        repeat(20) @(posedge rd_clk);
        $finish;
    end

endmodule