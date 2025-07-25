module timer (
    input clk_1s,
    input reset,
    input load_time_en,
    input [3:0] initial_first_sec,
    input [3:0] initial_second_sec,
    input [3:0] initial_first_min,
    input [3:0] initial_second_min,
    output reg [3:0] current_first_s,
    output reg [3:0] current_second_s,
    output reg [3:0] current_first_m,
    output reg [3:0] current_second_m,
    input clear_input
);

    reg [9:0] total_seconds;

    initial begin
        total_seconds = 0;
        current_first_s = 0;
        current_second_s = 0;
        current_first_m = 0;
        current_second_m = 0;
    end

    always @(posedge clk_1s or posedge reset) begin
        if (reset || clear_input) begin
            total_seconds <= 0;
            current_first_s <= 0;
            current_second_s <= 0;
            current_first_m <= 0;
            current_second_m <= 0;
        end else if (load_time_en) begin
            total_seconds <= (initial_second_min * 600) + (initial_first_min * 60) +
                             (initial_second_sec * 10) + initial_first_sec;
            current_first_s <= initial_first_sec;
            current_second_s <= initial_second_sec;
            current_first_m <= initial_first_min;
            current_second_m <= initial_second_min;
        end else if (total_seconds > 0) begin
            total_seconds <= total_seconds - 1;

            current_second_m <= (total_seconds - 1) / 600;
            current_first_m  <= ((total_seconds - 1) / 60) % 10;
            current_second_s <= ((total_seconds - 1) % 60) / 10;
            current_first_s  <= ((total_seconds - 1) % 60) % 10;
        end
    end

endmodule
