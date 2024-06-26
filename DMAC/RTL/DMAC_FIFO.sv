module DMAC_FIFO #(
    parameter       DEPTH_LG2           = 4,
    parameter       DATA_WIDTH          = 32
    )
(
    input   wire                        clk,
    input   wire                        rst_n,

    output  wire                        full_o,
    input   wire                        wren_i,
    input   wire    [DATA_WIDTH-1:0]    wdata_i,

    output  wire                        empty_o,
    input   wire                        rden_i,
    output  wire    [DATA_WIDTH-1:0]    rdata_o
);

    localparam  FIFO_DEPTH              = (1<<DEPTH_LG2);

    reg     [DATA_WIDTH-1:0]            data[FIFO_DEPTH],   newreg,     newreg_n;

    reg                                 full,       full_n,
                                        empty,      empty_n;
    reg     [DEPTH_LG2:0]               wrptr,      wrptr_n,
                                        rdptr,      rdptr_n;

    // reset entries to all 0s
    always_ff @(posedge clk)
        if (!rst_n) begin
            full                        <= 1'b0;
            empty                       <= 1'b1;    // empty after as reset
            newreg                       <= {DATA_WIDTH{1'b0}};
            wrptr                       <= {(DEPTH_LG2+1){1'b0}};
            rdptr                       <= {(DEPTH_LG2+1){1'b0}};

            for (int i=0; i<FIFO_DEPTH; i++) begin
                data[i]                     <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            full                        <= full_n;
            empty                       <= empty_n;
            newreg                      <= newreg_n;
            wrptr                       <= wrptr_n;
            rdptr                       <= rdptr_n;

            if (wren_i) begin
                data[wrptr[DEPTH_LG2-1:0]]  <= wdata_i;
            end
        end

    always_comb begin
        wrptr_n                     = wrptr;
        rdptr_n                     = rdptr;
        newreg_n                    = newreg;

        if (wren_i & ~full) begin
            wrptr_n                     = wrptr + 'd1;

            if (empty) begin
                newreg_n                 = wdata_i;
            end
        end

        if (rden_i & ~empty) begin
            rdptr_n                     = rdptr + 'd1;
            newreg_n                    = data[rdptr_n[DEPTH_LG2-1:0]];
        end

        empty_n                     = (wrptr_n == rdptr_n);
        full_n                      = (wrptr_n[DEPTH_LG2]!=rdptr_n[DEPTH_LG2])
                                     &(wrptr_n[DEPTH_LG2-1:0]==rdptr_n[DEPTH_LG2-1:0]);

    end

//    // synthesis translate_off
//    always @(posedge clk) begin
//        if (full_o & wren_i) begin
//            $display("FIFO overflow");
//            @(posedge clk);
//            $finish;
//        end
//    end
//
//    always @(posedge clk) begin
//        if (empty_o & rden_i) begin
//            $display("FIFO underflow");
//            @(posedge clk);
//            $finish;
//        end
//    end
//    // synthesis translate_on

    assign  full_o                      = full;
    assign  empty_o                     = empty;
    assign  rdata_o                     = newreg;

endmodule