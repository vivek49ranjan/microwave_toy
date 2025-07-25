module pwm_power (
    input clk,
    input [7:0] duty_cycle,
    output reg magnetron_on
);
    reg [7:0] counter;

    parameter PWM_PERIOD_MAX = 100;

    always @(posedge clk) begin
        if (counter == (PWM_PERIOD_MAX - 1)) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end

        if (duty_cycle == 8'd0) begin
            magnetron_on <= 0;
        end else if (duty_cycle == 8'd100) begin
            magnetron_on <= 1;
        end else if (counter < duty_cycle) begin
            magnetron_on <= 1;
        end else begin
            magnetron_on <= 0;
        end
    end
endmodule


