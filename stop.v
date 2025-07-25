module stop_clear (
    input stop,
    input [7:0] power_in,
    input microwave_power_on,
    output reg clear_timer_signal,
    output reg microwave_power_off_signal
);

    always @(*) begin
        if (stop) begin
            clear_timer_signal = 1;
            microwave_power_off_signal = 1;
        end else begin
            clear_timer_signal = 0;
            microwave_power_off_signal = 0;
        end
    end

endmodule

