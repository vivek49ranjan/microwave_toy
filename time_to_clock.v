module time_to_cook (
    input clk_1s,
    input reset,
    input [3:0] digit_input,
    output reg [3:0] first_sec_out,
    output reg [3:0] second_sec_out,
    output reg [3:0] first_min_out,
    output reg [3:0] second_min_out
);

    reg [3:0] digit_register [3:0];
    reg [1:0] digit_index;

    initial begin
        first_sec_out = 0;
        second_sec_out = 0;
        first_min_out = 0;
        second_min_out = 0;
        digit_index = 0;
        digit_register[0] = 0;
        digit_register[1] = 0;
        digit_register[2] = 0;
        digit_register[3] = 0;
    end

    always @(posedge clk_1s or posedge reset) begin
        if (reset) begin
            first_sec_out <= 0;
            second_sec_out <= 0;
            first_min_out <= 0;
            second_min_out <= 0;
            digit_index <= 0;
            digit_register[0] <= 0;
            digit_register[1] <= 0;
            digit_register[2] <= 0;
            digit_register[3] <= 0;
        end else begin
            if (digit_input != 4'bxxxx) begin
                if (digit_index < 2'd4) begin
                    digit_register[digit_index] <= digit_input;
                    digit_index <= digit_index + 1;
                end else begin
                    digit_register[0] <= digit_register[1];
                    digit_register[1] <= digit_register[2];
                    digit_register[2] <= digit_register[3];
                    digit_register[3] <= digit_input;
                end
            end
            second_min_out <= digit_register[0];
            first_min_out <= digit_register[1];
            second_sec_out <= digit_register[2];
            first_sec_out <= digit_register[3];
        end
    end

endmodule


