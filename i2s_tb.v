`timescale 1ns/1ps

module tb();
    localparam PERIOD = 40.7;
    localparam BPERIOD = 4*PERIOD;
    localparam LRPERIOD = 64*BPERIOD;
    reg rst;
    reg mck;
    reg bck;
    reg lrck;
    reg [15:0] key;
    reg data;
    reg [3:0]count;

    initial begin
        rst = 0;
        #(8*BPERIOD);
        rst = 1;
        // #(16*BPERIOD);
        // rst = 0;
    end

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        mck = 1;
        bck = 1;
        lrck = 1;
        key = 0;
        count=15;

        # (5000*LRPERIOD);
        $finish;
    end

    always #PERIOD mck = ~mck;
    always #BPERIOD bck = ~bck;
    always #LRPERIOD lrck = ~lrck;

    always @(posedge lrck or negedge lrck) begin
        if (lrck == 1) begin
            key <= key + 2;
        end
        else begin
            key <= key + 1;
        end
    end

    always @(posedge bck) begin
        if(count >= 0) begin
            data <= key[count];
            count <= count - 1;
        end
        else if(count == 0) begin
            count <= 15;
        end
    end

    i2s i2s_init(.rst_i(rst), .lrck_i(lrck), .bck_i(bck), .data_i(data), .mck_i(mck));

endmodule