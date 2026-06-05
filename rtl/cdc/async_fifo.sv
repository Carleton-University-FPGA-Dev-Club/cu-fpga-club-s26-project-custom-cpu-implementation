module async_fifo #(
    parameter DATA_WIDTH = 24,
    parameter DEPTH      = 16
)(
    input  logic                  wr_clk,
    input  logic                  wr_rst_n,  // active-low reset, sync to wr_clk
    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic                  full,

    input  logic                  rd_clk,
    input  logic                  rd_rst_n,  // active-low reset, sync to rd_clk
    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,
    output logic                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [ADDR_WIDTH:0] wr_ptr;
    logic [ADDR_WIDTH:0] rd_ptr;

    logic [ADDR_WIDTH:0] wr_ptr_gray;
    logic [ADDR_WIDTH:0] rd_ptr_gray;

    logic [ADDR_WIDTH:0] wr_gray_sync1, wr_gray_sync2;
    logic [ADDR_WIDTH:0] rd_gray_sync1, rd_gray_sync2;

    // ??? WRITE SIDE ??????????????????????????????????????????????????

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            wr_ptr <= 0;
        else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_WIDTH-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1;
        end
    end

    assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1);

    assign full = (wr_ptr_gray == {~rd_gray_sync2[ADDR_WIDTH],
                                    rd_gray_sync2[ADDR_WIDTH-1:0]});

    // ??? READ SIDE ???????????????????????????????????????????????????

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            rd_ptr <= 0;
        else if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr  <= rd_ptr + 1;
        end
    end

    assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1);

    assign empty = (rd_ptr_gray == wr_gray_sync2);

    // ??? DOUBLE-FLOP SYNCHRONIZERS ???????????????????????????????????

    always_ff @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= 0;
            wr_gray_sync2 <= 0;
        end else begin
            wr_gray_sync1 <= wr_ptr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    always_ff @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= 0;
            rd_gray_sync2 <= 0;
        end else begin
            rd_gray_sync1 <= rd_ptr_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

endmodule