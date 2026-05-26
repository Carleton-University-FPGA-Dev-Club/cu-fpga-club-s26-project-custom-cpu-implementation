module i2s_receiver (
    input logic bclk, // bit clock
    input logic lrclk, // left-right clock
    input logic sdata, // serial data
    output logic [23:0] left_data, // left channel data
    output logic [23:0] right_data, // right channel data
    output logic left_valid, // left channel valid
    output logic right_valid // right channel valid
);
logic lrclk_prev;
logic [4:0] bit_count;
logic [23:0] shift_reg;

always_ff @(negedge bclk) begin
    shift_reg <= {shift_reg[22:0], sdata};
    bit_count <= bit_count + 1;
    lrck_prev <= lrck; 
end

always_ff @( negedge bclk ) begin
    left_valid <= 0;
    right_valid <= 0;
    if (lrclk != lrclk_prev) begin
        bit_count <= 0;
        if (lrclk == 1) begin
            left_data <= shift_reg;
            left_valid <= 1;
        end
        else begin
            right_data <= shift_reg;
            right_valid <= 1;
        end
    end
end
    
