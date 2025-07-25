`timescale 1ns / 1ps

module top_microwave_tb;

    reg timer_input;
    reg door_open;
    reg popcorn;
    reg beverage;
    reg reheat;
    reg defrost;
    reg pizza;
    reg potato;
    reg vegetable;
    reg dinner;
    reg baby_milk;
    reg keep_warm;
    reg clk;
    reg reset;
    reg start;
    reg stop;
    reg [3:0] set_time_digit;

    wire [3:0] first_second_out;
    wire [3:0] first_minute_out;
    wire [3:0] second_second_out;
    wire [3:0] second_minute_out;
    wire [7:0] temperature;
    wire play_audio;
    wire buzzer;
    wire [7:0] power;
    wire [6:0] seven_segment_1;
    wire [6:0] seven_segment_2;
    wire [6:0] seven_segment_3;
    wire [6:0] seven_segment_4;

    parameter CLK_PERIOD = 20;

    top_microwave dut (
        .timer_input(timer_input),
        .door_open(door_open),
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
        .clk(clk),
        .reset(reset),
        .first_second_out(first_second_out),
        .first_minute_out(first_minute_out),
        .second_second_out(second_second_out),
        .second_minute_out(second_minute_out),
        .temperature(temperature),
        .play_audio(play_audio),
        .start(start),
        .stop(stop),
        .buzzer(buzzer),
        .power(power),
        .seven_segment_1(seven_segment_1),
        .seven_segment_2(seven_segment_2),
        .seven_segment_3(seven_segment_3),
        .seven_segment_4(seven_segment_4),
        .set_time_digit(set_time_digit)
    );

    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2) clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    initial begin
        $monitor("Time=%0t | Reset=%b | DoorOpen=%b | Start=%b | Stop=%b | SetTimeDigit=%x | CurrentTime: %d%d:%d%d | Power=%d | Buzzer=%b | PlayAudio=%b | Temp=%d",
                 $time, reset, door_open, start, stop, set_time_digit,
                 second_minute_out, first_minute_out, second_second_out, first_second_out,
                 power, buzzer, play_audio, temperature);
    end

    initial begin
        timer_input = 1'b0;
        door_open = 1'b0;
        popcorn = 1'b0;
        beverage = 1'b0;
        reheat = 1'b0;
        defrost = 1'b0;
        pizza = 1'b0;
        potato = 1'b0;
        vegetable = 1'b0;
        dinner = 1'b0;
        baby_milk = 1'b0;
        keep_warm = 1'b0;
        start = 1'b0;
        stop = 1'b0;
        set_time_digit = 4'bxxxx;

        reset = 1'b1;
        #100;
        reset = 1'b0;
        # (CLK_PERIOD * 5);

        set_time_digit = 4'd1; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        set_time_digit = 4'd3; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        set_time_digit = 4'd0; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        # (CLK_PERIOD * 5);

        start = 1'b1;
        # (CLK_PERIOD * 2);
        start = 1'b0;
        # (CLK_PERIOD * 10);

        start = 1'b1;
        # (CLK_PERIOD * 2);
        start = 1'b0;
        # (CLK_PERIOD * 10);

        stop = 1'b1;
        # (CLK_PERIOD * 2);
        stop = 1'b0;
        # (CLK_PERIOD * 10);

        popcorn = 1'b1;
        # (CLK_PERIOD * 5);
        popcorn = 1'b0;

        start = 1'b1;
        # (CLK_PERIOD * 2);
        start = 1'b0;
        # (200 * CLK_PERIOD);

        door_open = 1'b1;
        # (CLK_PERIOD * 5);
        door_open = 1'b0;
        # (CLK_PERIOD * 5);

        # (50 * CLK_PERIOD);
        # (CLK_PERIOD * 10);
        $finish;
    end

endmodule
