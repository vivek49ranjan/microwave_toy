`timescale 1ns / 1ps

module top_microwave(
    input timer_input,
    input door_open,
    input popcorn,
    input beverage,
    input reheat,
    input defrost,
    input pizza,
    input potato,
    input vegetable,
    input dinner,
    input baby_milk,
    input keep_warm,
    input clk,
    input reset,
    output [3:0] first_second_out,
    output [3:0] first_minute_out,
    output [3:0] second_second_out,
    output [3:0] second_minute_out,
    output [7:0] temperature,
    output play_audio,
    input start,
    input stop,
    output buzzer,
    output reg [7:0] power,
    output [6:0] seven_segment_1,
    output [6:0] seven_segment_2,
    output [6:0] seven_segment_3,
    output [6:0] seven_segment_4,
    input [3:0] set_time_digit
);

    wire sec_clock_out;
    wire [3:0] time_entered_fs,
               time_entered_ss,
               time_entered_fm,
               time_entered_sm;
    wire [3:0] preset_time_fs,
               preset_time_ss,
               preset_time_fm,
               preset_time_sm;
    wire [7:0] preset_power_level;
    wire [7:0] preset_temperature_out;

    wire timer_clear_signal;
    wire start_button_power_on_signal;
    wire microwave_power_off_from_timer;
    wire microwave_power_off_from_stop;

    wire magnetron_control;

    reg [3:0] current_first_s_display;
    reg [3:0] current_second_s_display;
    reg [3:0] current_first_m_display;
    reg [3:0] current_second_m_display;

    wire [3:0] timer_load_first_s;
    wire [3:0] timer_load_second_s;
    wire [3:0] timer_load_first_m;
    wire [3:0] timer_load_second_m;
    wire timer_load_enable;

    reg custom_time_enable;

    wire [3:0] timer_load_first_s_start;
    wire [3:0] timer_load_second_s_start;
    wire [3:0] timer_load_first_m_start;
    wire [3:0] timer_load_second_m_start;

    second_clock create_sec (
        .sys_clk(clk),
        .reset(reset),
        .clk_1s(sec_clock_out)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            custom_time_enable <= 0;
        end else if (set_time_digit != 4'bxxxx) begin
            custom_time_enable <= 1;
        end else if (start || stop || timer_clear_signal || microwave_power_off_from_timer) begin
            custom_time_enable <= 0;
        end
    end

    time_to_cook custom_timer_setter (
        .clk_1s(sec_clock_out),
        .reset(reset),
        .digit_input(set_time_digit),
        .first_sec_out(time_entered_fs),
        .second_sec_out(time_entered_ss),
        .first_min_out(time_entered_fm),
        .second_min_out(time_entered_sm)
    );

    preset_cook predefinde (
        .clk(clk),
        .reset(reset),
        .popcorn(popcorn),
        .beverage(beverage),
        .reheat(reheat),
        .defrost(defrost),
        .pizza(pizza),
        .potato(potato),
        .vegetable(vegetable),
        .dinner(dinner),
        .baby_milk(baby_milk),
        .keep_warm(keep_warm),
        .custom_time(custom_time_enable),
        .in_first_s(time_entered_fs),
        .in_second_s(time_entered_ss),
        .in_first_m(time_entered_fm),
        .in_second_m(time_entered_sm),
        .temperature_out(preset_temperature_out),
        .first_s(preset_time_fs),
        .second_s(preset_time_ss),
        .first_m(preset_time_fm),
        .second_m(preset_time_sm),
        .power(preset_power_level)
    );

    assign temperature = preset_temperature_out;

    stop_clear stop_controller (
        .stop(stop),
        .power_in(power),
        .microwave_power_on(start_button_power_on_signal),
        .clear_timer_signal(timer_clear_signal),
        .microwave_power_off_signal(microwave_power_off_from_stop)
    );

    start_30_button start_controller (
        .clk(clk),
        .reset(reset),
        .prev_power_state(power > 0),
        .microwave_power_on(start_button_power_on_signal),
        .current_first_sec(current_first_s_display),
        .current_second_sec(current_second_s_display),
        .current_first_min(current_first_m_display),
        .current_second_min(current_second_m_display),
        .new_first_s(timer_load_first_s_start),
        .new_second_s(timer_load_second_s_start),
        .new_first_m(timer_load_first_m_start),
        .new_second_m(timer_load_second_m_start),
        .start_button(start)
    );

    assign timer_load_enable = (start || (custom_time_enable && set_time_digit != 4'bxxxx) ||
                                popcorn || beverage || reheat || defrost || pizza || potato ||
                                vegetable || dinner || baby_milk || keep_warm);

    assign timer_load_first_s = start ? timer_load_first_s_start :
                                (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_fs :
                                4'd0;

    assign timer_load_second_s = start ? timer_load_second_s_start :
                                 (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_ss :
                                 4'd0;

    assign timer_load_first_m = start ? timer_load_first_m_start :
                                (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_fm :
                                4'd0;

    assign timer_load_second_m = start ? timer_load_second_m_start :
                                 (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_sm :
                                 4'd0;


    timer cook_timer (
        .clk_1s(sec_clock_out),
        .reset(reset),
        .load_time_en(timer_load_enable),
        .initial_first_sec(timer_load_first_s),
        .initial_second_sec(timer_load_second_s),
        .initial_first_min(timer_load_first_m),
        .initial_second_min(timer_load_second_m),
        .current_first_s(current_first_s_display),
        .current_second_s(current_second_s_display),
        .current_first_m(current_first_m_display),
        .current_second_m(current_second_m_display),
        .clear_input(timer_clear_signal)
    );

    assign first_second_out = current_first_s_display;
    assign second_second_out = current_second_s_display;
    assign first_minute_out = current_first_m_display;
    assign second_minute_out = current_second_m_display;

    seven_segment display1 (
        .number(first_second_out),
        .reset(reset),
        .a(seven_segment_1[0]), .b(seven_segment_1[1]), .c(seven_segment_1[2]),
        .d(seven_segment_1[3]), .e(seven_segment_1[4]), .f(seven_segment_1[5]),
        .g(seven_segment_1[6])
    );

    seven_segment display2 (
        .number(second_second_out),
        .reset(reset),
        .a(seven_segment_2[0]), .b(seven_segment_2[1]), .c(seven_segment_2[2]),
        .d(seven_segment_2[3]), .e(seven_segment_2[4]), .f(seven_segment_2[5]),
        .g(seven_segment_2[6])
    );

    seven_segment display3 (
        .number(first_minute_out),
        .reset(reset),
        .a(seven_segment_3[0]), .b(seven_segment_3[1]), .c(seven_segment_3[2]),
        .d(seven_segment_3[3]), .e(seven_segment_3[4]), .f(seven_segment_3[5]),
        .g(seven_segment_3[6])
    );

    seven_segment display4 (
        .number(second_minute_out),
        .reset(reset),
        .a(seven_segment_4[0]), .b(seven_segment_4[1]), .c(seven_segment_4[2]),
        .d(seven_segment_4[3]), .e(seven_segment_4[4]), .f(seven_segment_4[5]),
        .g(seven_segment_4[6])
    );

    assign play_audio = 1'b0;

    buzzer kitchen_buzzer(
        .first_s(first_second_out),
        .second_s(second_second_out),
        .first_m(first_minute_out),
        .second_m(second_minute_out),
        .clk_1s(sec_clock_out),
        .buzzer_on(buzzer),
        .microwave_power_off(microwave_power_off_from_timer)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            power <= 8'd0;
        end else if (start_button_power_on_signal) begin
            if (preset_power_level > 0) begin
                power <= preset_power_level;
            end else begin
                power <= 8'd100;
            end
        end else if (microwave_power_off_from_stop || microwave_power_off_from_timer) begin
            power <= 8'd0;
        end else if ((popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) && !start_button_power_on_signal) begin
            power <= preset_power_level;
        end else if (custom_time_enable && set_time_digit != 4'bxxxx && !start_button_power_on_signal) begin
             power <= 8'd100;
        end
    end

    pwm_power magnetron_pwm (
        .clk(clk),
        .duty_cycle(power),
        .magnetron_on(magnetron_control)
    );

endmodule

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

module seven_segment (
    input [3:0] number,
    input reset,
    output reg a,
    output reg b,
    output reg c,
    output reg d,
    output reg e,
    output reg f,
    output reg g
);

always @(*) begin
    if (reset) begin
        a = 0; b = 0; c = 0; d = 0; e = 0; f = 0; g = 0;
    end else begin
        case (number)
            4'd0: {a,b,c,d,e,f,g} = 7'b1111110;
            4'd1: {a,b,c,d,e,f,g} = 7'b0110000;
            4'd2: {a,b,c,d,e,f,g} = 7'b1101101;
            4'd3: {a,b,c,d,e,f,g} = 7'b1111001;
            4'd4: {a,b,c,d,e,f,g} = 7'b0110011;
            4'd5: {a,b,c,d,e,f,g} = 7'b1011011;
            4'd6: {a,b,c,d,e,f,g} = 7'b1011111;
            4'd7: {a,b,c,d,e,f,g} = 7'b1110000;
            4'd8: {a,b,c,d,e,f,g} = 7'b1111111;
            4'd9: {a,b,c,d,e,f,g} = 7'b1111011;
            default: {a,b,c,d,e,f,g} = 7'b0000000;
        endcase
    end
end

endmodule

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

module preset_cook (
    input clk,
    input reset,
    input popcorn, beverage, reheat, defrost, pizza, potato, vegetable,
    input dinner, baby_milk, keep_warm,
    input custom_time,
    input [3:0] in_first_s,
    input [3:0] in_second_s,
    input [3:0] in_first_m,
    input [3:0] in_second_m,
    output reg [7:0] temperature_out,
    output reg [3:0] first_s,
    output reg [3:0] second_s,
    output reg [3:0] first_m,
    output reg [3:0] second_m,
    output reg [7:0] power
);

    always @(*) begin
        first_s = 0;
        second_s = 0;
        first_m = 0;
        second_m = 0;
        power = 0;
        temperature_out = 8'd0;

        if (reset) begin
        end else if (custom_time) begin
            first_s = in_first_s;
            second_s = in_second_s;
            first_m = in_first_m;
            second_m = in_second_m;
            power = 8'd100;
            temperature_out = 8'd75;
        end else if (popcorn) begin
            first_s = 0; second_s = 0;
            first_m = 2; second_m = 0;
            power = 8'd100;
            temperature_out = 8'd100;
        end else if (beverage) begin
            first_s = 0; second_s = 0;
            first_m = 1; second_m = 0;
            power = 8'd70;
            temperature_out = 8'd80;
        end else if (reheat) begin
            first_s = 0; second_s = 3;
            first_m = 1; second_m = 0;
            power = 8'd70;
            temperature_out = 8'd70;
        end else if (defrost) begin
            first_s = 0; second_s = 0;
            first_m = 3; second_m = 0;
            power = 8'd35;
            temperature_out = 8'd25;
        end else if (pizza) begin
            first_s = 0; second_s = 3;
            first_m = 4; second_m = 0;
            power = 8'd80;
            temperature_out = 8'd75;
        end else if (potato) begin
            first_s = 0; second_s = 0;
            first_m = 4; second_m = 0;
            power = 8'd100;
            temperature_out = 8'd90;
        end else if (vegetable) begin
            first_s = 0; second_s = 3;
            first_m = 3; second_m = 0;
            power = 8'd80;
            temperature_out = 8'd85;
        end else if (dinner) begin
            first_s = 0; second_s = 0;
            first_m = 3; second_m = 0;
            power = 8'd80;
            temperature_out = 8'd80;
        end else if (baby_milk) begin
            first_s = 0; second_s = 0;
            first_m = 1; second_m = 0;
            power = 8'd50;
            temperature_out = 8'd35;
        end else if (keep_warm) begin
            first_s = 0; second_s = 0;
            first_m = 3; second_m = 0;
            power = 8'd10;
            temperature_out = 8'd65;
        end
    end

endmodule

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
