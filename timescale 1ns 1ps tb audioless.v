// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module top_microwave_tb;

    // Inputs to the top_microwave module
    reg timer_input; // Placeholder, not used in your current top_microwave
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
    reg [3:0] set_time_digit; // Input for custom time digits

    // Outputs from the top_microwave module
    wire [3:0] first_second_out;
    wire [3:0] first_minute_out;
    wire [3:0] second_second_out;
    wire [3:0] second_minute_out;
    wire [7:0] temperature;
    wire play_audio; // Should always be 0 as audio logic is removed
    wire buzzer;
    wire [7:0] power;
    wire [6:0] seven_segment_1;
    wire [6:0] seven_segment_2;
    wire [6:0] seven_segment_3;
    wire [6:0] seven_segment_4;

    // Clock period definition (for 50MHz clock)
    parameter CLK_PERIOD = 20; // 20ns for 50MHz (1/50,000,000 * 1,000,000,000 ns)

    // Instantiate the Device Under Test (DUT)
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

    // Clock generation
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2) clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // Monitor for key signals
    initial begin
        $monitor("Time=%0t | Reset=%b | DoorOpen=%b | Start=%b | Stop=%b | SetTimeDigit=%x | CurrentTime: %d%d:%d%d | Power=%d | Buzzer=%b | PlayAudio=%b | Temp=%d",
                 $time, reset, door_open, start, stop, set_time_digit,
                 second_minute_out, first_minute_out, second_second_out, first_second_out,
                 power, buzzer, play_audio, temperature);
    end

    // Test Scenarios
    initial begin
        // Initialize all inputs
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
        set_time_digit = 4'bxxxx; // No digit input initially

        // Scenario 1: Initial Reset
        $display("\n--- Scenario 1: Initial Reset and Idle ---");
        reset = 1'b1;
        #100; // Hold reset for a short period
        reset = 1'b0;
        # (CLK_PERIOD * 5); // Allow some cycles to stabilize in idle

        // Scenario 2: Custom Time Entry (1 min 30 sec) and Start
        $display("\n--- Scenario 2: Custom Time Entry (1m30s) & Start ---");
        // Enter '1'
        set_time_digit = 4'd1; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        // Enter '3'
        set_time_digit = 4'd3; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        // Enter '0'
        set_time_digit = 4'd0; # (CLK_PERIOD * 2); set_time_digit = 4'bxxxx;
        // Now time should be 01:30
        # (CLK_PERIOD * 5); // Allow time_to_cook to update

        start = 1'b1;
        # (CLK_PERIOD * 2); // Hold start briefly
        start = 1'b0;
        # (CLK_PERIOD * 10); // Let it cook for a few seconds

        // Scenario 3: Add 30 Seconds During Cook
        $display("\n--- Scenario 3: Add 30 Seconds ---");
        start = 1'b1;
        # (CLK_PERIOD * 2); // Hold start briefly
        start = 1'b0;
        # (CLK_PERIOD * 10); // Let it cook with added time

        // Scenario 4: Stop/Clear
        $display("\n--- Scenario 4: Stop/Clear ---");
        stop = 1'b1;
        # (CLK_PERIOD * 2); // Hold stop briefly
        stop = 1'b0;
        # (CLK_PERIOD * 10); // Observe timer clear and power off

        // Scenario 5: Preset Cook (Popcorn - 2 minutes)
        $display("\n--- Scenario 5: Preset Cook (Popcorn: 2m0s) ---");
        popcorn = 1'b1;
        # (CLK_PERIOD * 5); // Allow preset_cook to update
        popcorn = 1'b0; // Release button, the preset time is latched

        start = 1'b1;
        # (CLK_PERIOD * 2);
        start = 1'b0;
        # (200 * CLK_PERIOD); // Let it cook for most of the 2 minutes (120 seconds)

        // Scenario 6: Simulate Door Open
        $display("\n--- Scenario 6: Door Open during cook ---");
        door_open = 1'b1;
        # (CLK_PERIOD * 5);
        door_open = 1'b0;
        # (CLK_PERIOD * 5); // Continue cooking

        // Scenario 7: Wait for Buzzer (complete the cook cycle)
        $display("\n--- Scenario 7: Wait for Buzzer ---");
        // We let it run until the timer reaches 00:00.
        // The `$monitor` will show the countdown and buzzer activation.
        # (50 * CLK_PERIOD); // Give it enough time to reach 0 and buzz

        // End simulation
        $display("\n--- Simulation Complete ---");
        # (CLK_PERIOD * 10);
        $finish;
    end

endmodule
