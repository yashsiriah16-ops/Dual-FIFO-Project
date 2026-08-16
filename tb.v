`timescale 1ns / 1ps

module async_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    reg wr_clk;
    reg rd_clk;

    reg wr_rst;
    reg rd_rst;

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] wr_data;

    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .wr_clk(wr_clk),
        .wr_rst(wr_rst),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .full(full),

        .rd_clk(rd_clk),
        .rd_rst(rd_rst),
        .rd_en(rd_en),
        .rd_data(rd_data),
        .empty(empty)
    );

    // --------------------------------------------------
    // Write clock
    // 10 ns period
    // --------------------------------------------------
    always #5 wr_clk = ~wr_clk;

    // --------------------------------------------------
    // Read clock
    // 14 ns period
    // --------------------------------------------------
    always #7 rd_clk = ~rd_clk;

    // --------------------------------------------------
    // Write task
    // --------------------------------------------------
    task write_data;
        input [DATA_WIDTH-1:0] data;

        begin

            @(posedge wr_clk);

            if (!full) begin
                wr_data = data;
                wr_en   = 1'b1;

                @(posedge wr_clk);

                wr_en = 1'b0;

                $display(
                    "TIME=%0t WRITE DATA=%0d",
                    $time,
                    data
                );
            end

            else begin
                $display(
                    "TIME=%0t FIFO FULL - WRITE BLOCKED",
                    $time
                );
            end

        end
    endtask

    // --------------------------------------------------
    // Read task
    // --------------------------------------------------
    task read_data;

        begin

            @(posedge rd_clk);

            if (!empty) begin

                rd_en = 1'b1;

                @(posedge rd_clk);

                rd_en = 1'b0;

                $display(
                    "TIME=%0t READ DATA=%0d",
                    $time,
                    rd_data
                );

            end

            else begin

                $display(
                    "TIME=%0t FIFO EMPTY - READ BLOCKED",
                    $time
                );

            end

        end

    endtask

    // --------------------------------------------------
    // Test sequence
    // --------------------------------------------------
    initial begin

        // Initial values
        wr_clk = 0;
        rd_clk = 0;

        wr_rst = 1;
        rd_rst = 1;

        wr_en = 0;
        rd_en = 0;

        wr_data = 0;

        // ------------------------------------------------
        // Reset
        // ------------------------------------------------
        #30;

        wr_rst = 0;
        rd_rst = 0;

        $display("-------------------------------------");
        $display("RESET RELEASED");
        $display("-------------------------------------");

        // ------------------------------------------------
        // Write data
        // ------------------------------------------------
        write_data(8'd10);
        write_data(8'd20);
        write_data(8'd30);
        write_data(8'd40);
        write_data(8'd50);
        write_data(8'd60);
        write_data(8'd70);
        write_data(8'd80);

        // Give CDC synchronizers time
        #50;

        // ------------------------------------------------
        // Read data
        // ------------------------------------------------
        read_data();
        read_data();
        read_data();
        read_data();

        #50;

        // ------------------------------------------------
        // More writes
        // ------------------------------------------------
        write_data(8'd100);
        write_data(8'd110);
        write_data(8'd120);

        #50;

        // ------------------------------------------------
        // More reads
        // ------------------------------------------------
        read_data();
        read_data();
        read_data();
        read_data();
        read_data();
        read_data();
        read_data();

        #100;

        $display("-------------------------------------");
        $display("SIMULATION COMPLETED");
        $display("-------------------------------------");

        $finish;

    end

endmodule
