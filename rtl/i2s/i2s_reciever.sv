module i2s_receiver (
    input  logic        bclk,
    input  logic        lrclk,
    input  logic        sdata,
    output logic [23:0] left_data,
    output logic [23:0] right_data,
    output logic        left_valid,
    output logic        right_valid
);

    logic [23:0] shift_reg;
    logic [4:0]  bit_count;
    logic        lrclk_prev;

    // block 1 — shift register and lrclk edge detection
    always_ff @(negedge bclk) begin
        shift_reg  <= {shift_reg[22:0], sdata};
        lrclk_prev <= lrclk;
    end

    // block 2 — output latching and bit counter
    always_ff @(negedge bclk) begin
        left_valid  <= 1'b0;
        right_valid <= 1'b0;

        if (lrclk_prev != lrclk) begin
            bit_count <= 5'b0;          // reset on channel change

            if (lrclk == 1'b1) begin
                left_data  <= shift_reg;
                left_valid <= 1'b1;
            end else begin
                right_data  <= shift_reg;
                right_valid <= 1'b1;
            end
        end else begin
            bit_count <= bit_count + 1; // increment in same block
        end
    end

endmodule