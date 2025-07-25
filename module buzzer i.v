module buzzer(
    input [3:0] first_s,
    input [3:0] second_s,
    input [3:0] first_m,
    input [3:0] second_m,
    input clk_1s,
    output reg buzzer_on,
    output reg microwave_power_off
);

    reg [3:0] beep_count;

    initial begin
        beep_count = 0;
        buzzer_on = 0;
        microwave_power_off = 0;
    end

    always @(posedge clk_1s) begin
        microwave_power_off <= 0;
        buzzer_on <= 0;

        if ((first_s == 4'd0) && (second_s == 4'd0) && (first_m == 4'd0) && (second_m == 4'd0)) begin
            microwave_power_off <= 1;

            if (beep_count < 4'd3) begin
                buzzer_on <= 1;
                beep_count <= beep_count + 1;
            end else begin
                buzzer_on <= 0;
                beep_count <= 4'd0;
            end
        end else begin
            beep_count <= 4'd0;
        end
    end

endmodule


