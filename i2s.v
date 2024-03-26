module i2s(
    input               rst_i,

    input               mck_i,
    input               lrck_i,
    input               bck_i,
    input               data_i,

    output              mck_o,
    output              lrck_o,
    output              bck_o,
    output              data_o,

    output reg          sync,
    output              sync2,
    output              sclk,
    output              sclk2,

    output reg          sdo,
    output reg          sdo1,
    output reg          sdo2,
    output reg          sdo3
);

localparam  BIT = 16;
localparam  B= 0;
localparam  E = B+BIT;

localparam  IDLE = 0;
localparam  R_START = 1;
localparam  R_TRANSFER = 2;
localparam  R_DONE = 3;
localparam  L_START = 4;
localparam  L_TRANSFER = 5;
localparam  L_DONE = 6;
localparam  FLASH = 7;

assign  mck_o = mck_i;
assign  lrck_o = lrck_i;
assign  bck_o = bck_i;
assign  data_o = data_i;

reg     lrck_r;
reg     lrck_rr;
wire    left_start;
wire    right_start;
assign  left_start = lrck_r & ~lrck_rr;
assign  right_start = ~lrck_r & lrck_rr;

always @(negedge bck_o) begin
    if (!rst_i) begin
        lrck_r <= 0;
        lrck_rr <= 0;
    end
    else begin
        lrck_r <= lrck_i;
        lrck_rr <= lrck_r;
    end
end

reg             data_r;
reg[3:0]        state;
reg[5:0]        count;
reg[BIT-1:0]    val;
reg[BIT-1:0]    val_r;
reg[BIT-1:0]    val_rr;
reg[BIT-1:0]    l_val;
reg[BIT-1:0]    l_val_reverse;
reg[BIT-1:0]    r_val;
reg[BIT-1:0]    r_val_reverse;

always @(negedge bck_o) begin
    if (!rst_i) begin
        state <= IDLE;
        count <= 0;

        val <= 0;
        val_r <= 0;
        val_rr <= 0;
        l_val <= 0;
        r_val <= 0;

        data_r <= 0;
    end
    else begin
        data_r <= data_i;
        if (right_start)
            state <= R_TRANSFER;
        else if (left_start)
            state <= L_TRANSFER;
        else begin
            case(state)
                IDLE:
                    val <= 0;
                R_TRANSFER: begin
                    if (count == E) begin
                        count <= 0;
                        state <= R_DONE;
                    end
                    else if (count < E) begin
                        // val <= {val, data_r};
                        val <= {val, data_r};
                        count <= count + 1;
                    end
                end
                R_DONE: begin
                    //dithering
                    // r_val <= {~val[BIT-1], val[BIT-2:0]} + val_r[8:0] - val_rr[8:0];
                    val_r <= val;
                    val_rr <= val_r;
                    r_val <= {!val[BIT-1], val[BIT-2:0]};
                    r_val_reverse <= ~{!val[BIT-1], val[BIT-2:0]};

                    state <= IDLE;
                end
                L_TRANSFER: begin
                    if (count == E) begin
                        count <= 0;
                        state <= L_DONE;
                    end
                    else if (count < E) begin
                        val <= {val, data_r};
                        count <= count + 1;
                    end
                end
                L_DONE: begin
                    // l_val <= {~val[BIT-1], val[BIT-2:0]} + val_r[8:0] - val_rr[8:0];
                    l_val <= {!val[BIT-1], val[BIT-2:0]};
                    l_val_reverse <= ~{!val[BIT-1], val[BIT-2:0]};
                    state <= IDLE;
                end
            endcase
        end
    end
end

localparam  WORD = BIT + 8;
reg [3:0]       state_w;
reg [5:0]       count_w;
reg [WORD-1:0]      key;
reg [WORD-1:0]      key1;
reg [WORD-1:0]      key2;
reg [WORD-1:0]      key3;
assign sclk = bck_i;
assign sclk2 = bck_i;
assign sync2= sync;

always @(posedge sclk) begin
    if (!rst_i)  begin
        key <= {8'h06, WORD-1'h0};
        key1 <= {8'h06, WORD-1'h0};
        key2 <= {8'h06, WORD-1'h0};
        key3 <= {8'h06, WORD-1'h0};

        count_w <= 0;
        state_w <= FLASH;
    end
    else if (left_start) begin
        key <= {8'h08, l_val};
        // key1 <= {8'h08, ~l_val};
        key1 <= {8'h08, ~l_val+1'h1};
        key2 <= {8'h08, r_val};
        // key3 <= {8'h08, ~r_val};
        key3 <= {8'h08, ~r_val+1'h1};

        sync <= 0;
        state_w <= FLASH;
    end
    else if (right_start) begin
        key <= {8'h09, l_val};
        key1 <= {8'h09, ~l_val+1'h1};
        key2 <= {8'h09, r_val};
        key3 <= {8'h09, ~r_val+1'h1};

        sync <= 0;
        state_w <= FLASH;
    end
    else if (state_w == FLASH) begin
        if (count_w == WORD) begin
            state_w <= IDLE;
            count_w <= 0;
            
            sdo <= 0;
            sdo1 <= 0;
            sdo2 <= 0;
            sdo3 <= 0;

            sync <= 1;
        end
        else begin
            sdo <= key[WORD-1 - count_w];
            sdo1 <= key1[WORD-1 - count_w];
            sdo2 <= key2[WORD-1 - count_w];
            sdo3 <= key3[WORD-1 - count_w];

            count_w <= count_w + 1;
            sync <= 0;
        end
    end
end
endmodule
