module i2s_receiver_tb;

    // signals to connect to DUT
    logic        bclk;
    logic        lrclk;
    logic        sdata;
    logic [23:0] left_data;
    logic [23:0] right_data;
    logic        left_valid;
    logic        right_valid;

    // instantiate the DUT (Device Under Test)
    i2s_receiver DUT (
        .bclk        (bclk),
        .lrclk       (lrclk),
        .sdata       (sdata),
        .left_data   (left_data),
        .right_data  (right_data),
        .left_valid  (left_valid),
        .right_valid (right_valid)
    );

    // generate bclk — 3.072 MHz means period = 325ns
    // so half period = 162ns
    initial bclk = 0;
    always #162 bclk = ~bclk;

    // task to send one 24-bit word over I2S
    task send_word(input logic lr, input logic [23:0] data);
        integer i;
        lrclk = lr;
        for (i = 23; i >= 0; i--) begin
            @(posedge bclk);        // wait for rising edge
            sdata = data[i];        // put bit on the line
            @(negedge bclk);        // falling edge — DUT samples here
        end
    endtask

    // main test sequence
    initial begin
        $dumpfile("i2s_receiver_tb.vcd");
        $dumpvars(0, i2s_receiver_tb);

        // initialise everything low
        bclk  = 0;
        lrclk = 0;
        sdata = 0;

        // wait a few cycles to settle
        repeat(4) @(negedge bclk);

        // send a left channel word (lrclk=0) — value 24'hABCDEF
        $display("Sending LEFT channel: 0xABCDEF");
        send_word(0, 24'hABCDEF);

        // toggle lrclk to trigger the latch
        @(negedge bclk);
        lrclk = 1;
        @(negedge bclk);

        // check result
        if (left_valid && left_data == 24'hABCDEF)
            $display("PASS: left_data = 0x%06X", left_data);
        else
            $display("FAIL: left_data = 0x%06X, valid = %b", left_data, left_valid);

        // send a right channel word (lrclk=1) — value 24'h123456
        $display("Sending RIGHT channel: 0x123456");
        send_word(1, 24'h123456);

        // toggle lrclk to trigger the latch
        @(negedge bclk);
        lrclk = 0;
        @(negedge bclk);

        // check result
        if (right_valid && right_data == 24'h123456)
            $display("PASS: right_data = 0x%06X", right_data);
        else
            $display("FAIL: right_data = 0x%06X, valid = %b", right_data, right_valid);

        $display("Testbench complete.");
        $finish;
    end

endmodule