module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write clock domain
    input  wire                    wr_clk,
    input  wire                    wr_rst,
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    output wire                    full,

    // Read clock domain
    input  wire                    rd_clk,
    input  wire                    rd_rst,
    input  wire                    rd_en,
    output reg  [DATA_WIDTH-1:0]   rd_data,
    output wire                    empty
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    // Memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary pointers
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_bin;

    // Gray-code pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // Synchronized read pointer in write clock domain
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;

    // Synchronized write pointer in read clock domain
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;

    reg full_reg;
    reg empty_reg;

    assign full  = full_reg;
    assign empty = empty_reg;

    // --------------------------------------------------
    // Binary to Gray conversion
    // --------------------------------------------------
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;

    wire [ADDR_WIDTH:0] wr_ptr_gray_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    assign wr_ptr_bin_next =
        wr_ptr_bin + ((wr_en && !full) ? 1'b1 : 1'b0);

    assign rd_ptr_bin_next =
        rd_ptr_bin + ((rd_en && !empty) ? 1'b1 : 1'b0);

    assign wr_ptr_gray_next =
        (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    assign rd_ptr_gray_next =
        (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    // --------------------------------------------------
    // Write pointer logic
    // --------------------------------------------------
    always @(posedge wr_clk or posedge wr_rst) begin

        if (wr_rst) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end

        else begin

            if (wr_en && !full)
                mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

        end
    end

    // --------------------------------------------------
    // Read pointer logic
    // --------------------------------------------------
    always @(posedge rd_clk or posedge rd_rst) begin

        if (rd_rst) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            rd_data     <= 0;
        end

        else begin

            if (rd_en && !empty)
                rd_data <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

        end
    end

    // --------------------------------------------------
    // Synchronize read pointer into write domain
    // --------------------------------------------------
    always @(posedge wr_clk or posedge wr_rst) begin

        if (wr_rst) begin
            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;
        end

        else begin
            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
        end

    end

    // --------------------------------------------------
    // Synchronize write pointer into read domain
    // --------------------------------------------------
    always @(posedge rd_clk or posedge rd_rst) begin

        if (rd_rst) begin
            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;
        end

        else begin
            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
        end

    end

    // --------------------------------------------------
    // FULL detection
    // --------------------------------------------------
    always @(posedge wr_clk or posedge wr_rst) begin

        if (wr_rst) begin
            full_reg <= 1'b0;
        end

        else begin
            full_reg <=
                (wr_ptr_gray_next ==
                {~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                  rd_ptr_gray_sync2[ADDR_WIDTH-2:0]});
        end

    end

    // --------------------------------------------------
    // EMPTY detection
    // --------------------------------------------------
    always @(posedge rd_clk or posedge rd_rst) begin

        if (rd_rst) begin
            empty_reg <= 1'b1;
        end

        else begin
            empty_reg <=
                (rd_ptr_gray_next == wr_ptr_gray_sync2);
        end

    end

endmodule
