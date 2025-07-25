module second_clock (
    input sys_clk,
    input reset,
    output reg clk_1s
);

    parameter CLK_FREQ = 50_000_000;
    parameter COUNT_MAX = (CLK_FREQ / 2) - 1;

    reg [25:0] count;

    always @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            count <= 0;
            clk_1s <= 0;
        end else begin
            if (count == COUNT_MAX) begin
                count <= 0;
                clk_1s <= ~clk_1s;
            end else begin
                count <= count + 1;
            end
        end
    end

endmodule


