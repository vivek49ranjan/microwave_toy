module start_30_button (
    input clk,
    input reset,
    input prev_power_state,
    output reg microwave_power_on,
    input [3:0] current_first_sec,
    input [3:0] current_second_sec,
    input [3:0] current_first_min,
    input [3:0] current_second_min,
    output reg [3:0] new_first_s,
    output reg [3:0] new_second_s,
    output reg [3:0] new_first_m,
    output reg [3:0] new_second_m,
    input start_button
);

    reg start_button_sync;
    reg start_button_prev;
    wire start_button_edge;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_button_sync <= 0;
            start_button_prev <= 0;
        end else begin
            start_button_sync <= start_button;
            start_button_prev <= start_button_sync;
        end
    end

    assign start_button_edge = (start_button_sync == 1'b1) && (start_button_prev == 1'b0);

    reg [9:0] total_seconds_current;
    reg [9:0] total_seconds_new;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            microwave_power_on <= 0;
            new_first_s <= 4'd0;
            new_second_s <= 4'd0;
            new_first_m <= 4'd0;
            new_second_m <= 4'd0;
        end else begin
            microwave_power_on <= 0;

            new_first_s <= current_first_sec;
            new_second_s <= current_second_sec;
            new_first_m <= current_first_min;
            new_second_m <= current_second_min;


            if (start_button_edge) begin
                microwave_power_on <= 1;

                total_seconds_current = (current_second_min * 600) + (current_first_min * 60) +
                                        (current_second_sec * 10) + current_first_sec;

                total_seconds_new = total_seconds_current + 30;

                if (total_seconds_new > (99 * 60 + 59)) begin
                    total_seconds_new = (99 * 60 + 59);
                end

                new_second_m <= (total_seconds_new / 600);
                new_first_m  <= ((total_seconds_new / 60) % 10);
                new_second_s <= ((total_seconds_new % 60) / 10);
                new_first_s  <= ((total_seconds_new % 60) % 10);
            end
        end
    end

endmodule


