module matrix_multiplier #(
    parameter DATA_W = 8,
    parameter ACC_W  = 24,
    parameter N      = 3
) (
    input  wire clk,
    input  wire reset,
    input  wire start,
    output wire done,

    input  wire wr_en,
    input  wire wr_sel,  // 0 loads A, 1 loads B
    input  integer wr_addr,
    input  wire signed [DATA_W-1:0] wr_data,

    input  integer rd_addr,
    output wire signed [ACC_W-1:0] rd_data
);
    // The four steps of the controller
    localparam IDLE    = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam STORE   = 2'b10;
    localparam FINISH  = 2'b11;

    reg [1:0] state;

    // The three matrices
    reg signed [DATA_W-1:0] mem_A [0:N*N-1];
    reg signed [DATA_W-1:0] mem_B [0:N*N-1];
    reg signed [ACC_W-1:0]  mem_C [0:N*N-1];

    // Counters select the output value and the pair being multiplied
    integer row;
    integer col;
    integer k;

    wire signed [DATA_W-1:0] mac_a;
    wire signed [DATA_W-1:0] mac_b;
    wire signed [ACC_W-1:0] acc;

    // A[row][k] times B[k][col]
    assign mac_a = mem_A[row*N + k];
    assign mac_b = mem_B[k*N + col];

    // Read one saved result from C
    assign rd_data = mem_C[rd_addr];
    assign done = (state == FINISH);

    // The MAC has a reset input but no separate clear input.
    // Reset it in IDLE and STORE so every new result starts at zero.
    wire mac_reset;
    wire mac_enable;
    assign mac_reset = reset || (state == IDLE) || (state == STORE);
    assign mac_enable = (state == COMPUTE);

    mac #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W)
    ) uut (
        .clk(clk),
        .reset(mac_reset),
        .enable(mac_enable),
        .a(mac_a),
        .b(mac_b),
        .acc(acc)
    );

    // Load A or B while the controller is idle
    always @(posedge clk) begin
        if (wr_en && state == IDLE) begin
            if (wr_sel)
                mem_B[wr_addr] <= wr_data;
            else
                mem_A[wr_addr] <= wr_data;
        end
    end

    // Controller
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            row <= 0;
            col <= 0;
            k <= 0;
        end else begin
            case (state)
                IDLE: begin
                    row <= 0;
                    col <= 0;
                    k <= 0;
                    if (start)
                        state <= COMPUTE;
                end

                COMPUTE: begin
                    if (k == N-1)
                        state <= STORE;
                    else
                        k <= k + 1;
                end

                STORE: begin
                    mem_C[row*N + col] <= acc;
                    k <= 0;

                    if (col == N-1) begin
                        col <= 0;
                        if (row == N-1) begin
                            row <= 0;
                            state <= FINISH;
                        end else begin
                            row <= row + 1;
                            state <= COMPUTE;
                        end
                    end else begin
                        col <= col + 1;
                        state <= COMPUTE;
                    end
                end

                FINISH: begin
                    if (!start)
                        state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
