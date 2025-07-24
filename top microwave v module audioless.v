`timescale 1ns / 1ps // Sets default time unit and precision for all modules in this file

// ====================================================================
// Module: top_microwave.v
// Top-level module for the microwave oven system.
// Connects all sub-modules and manages overall functionality.
// ====================================================================
module top_microwave(
    input timer_input, // Placeholder for future expansion, currently not used
    input door_open,   // Input indicating if the microwave door is open
    input popcorn,     // Preset button for popcorn
    input beverage,    // Preset button for beverage
    input reheat,      // Preset button for reheating food
    input defrost,     // Preset button for defrosting food
    input pizza,       // Preset button for pizza
    input potato,      // Preset button for potato
    input vegetable,   // Preset button for cooking vegetables
    input dinner,      // Preset button for dinner
    input baby_milk,   // Preset button for warming baby milk
    input keep_warm,   // Preset button for keeping food warm
    input clk,         // System clock (e.g., 50MHz)
    input reset,       // Asynchronous reset signal
    output [3:0] first_second_out,  // BCD output for units of seconds display
    output [3:0] first_minute_out,  // BCD output for units of minutes display
    output [3:0] second_second_out, // BCD output for tens of seconds display
    output [3:0] second_minute_out, // BCD output for tens of minutes display
    output [7:0] temperature,       // 8-bit output for internal temperature display/control
    output play_audio,              // 1-bit output to indicate audio playback (fixed to 0 as audio logic is removed)
    input start,                    // Start button input
    input stop,                     // Stop/Clear button input
    output buzzer,                  // 1-bit output to control the buzzer
    output reg [7:0] power,         // 8-bit register to hold the microwave power level (0-100)
    output [6:0] seven_segment_1,   // 7-segment display output for first_second_out
    output [6:0] seven_segment_2,   // 7-segment display output for second_second_out
    output [6:0] seven_segment_3,   // 7-segment display output for first_minute_out
    output [6:0] seven_segment_4,   // 7-segment display output for second_minute_out
    input [3:0] set_time_digit      // 4-bit input for custom time digits (from number pad)
);

    // Internal wires for connecting sub-modules
    wire sec_clock_out;             // 1Hz clock output from second_clock module
    wire [3:0] time_entered_fs,     // Units of seconds from time_to_cook
               time_entered_ss,     // Tens of seconds from time_to_cook
               time_entered_fm,     // Units of minutes from time_to_cook
               time_entered_sm;     // Tens of minutes from time_to_cook
    wire [3:0] preset_time_fs,      // Units of seconds from preset_cook
               preset_time_ss,      // Tens of seconds from preset_cook
               preset_time_fm,      // Units of minutes from preset_cook
               preset_time_sm;      // Tens of minutes from preset_cook
    wire [7:0] preset_power_level;  // Power level from preset_cook
    wire [7:0] preset_temperature_out; // Temperature from preset_cook

    wire timer_clear_signal;        // Signal from stop_clear to clear the timer display
    wire microwave_power_on_signal; // Signal from start_30_button to turn on microwave power
    wire microwave_power_off_signal; // Signal from buzzer to turn off microwave power
    // wire buzzer_active; // This signal is internal to the buzzer module, not needed here.
    wire magnetron_control;         // Control signal for magnetron (output of PWM)

    // Registers for current display values (driven by the timer module's outputs)
    reg [3:0] current_first_s_display;
    reg [3:0] current_second_s_display;
    reg [3:0] current_first_m_display;
    reg [3:0] current_second_m_display;

    // These signals are now Wires and driven by assign statements
    wire [3:0] timer_load_first_s;
    wire [3:0] timer_load_second_s;
    wire [3:0] timer_load_first_m;
    wire [3:0] timer_load_second_m;
    wire timer_load_enable;          // Enable signal to load new time into timer

    // Register for custom time entry mode
    reg custom_time_enable;

    // ------------------------------------------------------------
    // Sub-module Instantiations
    // ------------------------------------------------------------

    // Instance of the clock divider (generates a 1Hz clock from system clock)
    second_clock create_sec (
        .sys_clk(clk),
        .reset(reset),
        .clk_1s(sec_clock_out)
    );

    // Logic for custom_time_enable (activates when a digit is pressed)
    // Exits custom time mode if start or stop button is pressed.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            custom_time_enable <= 0;
        end else if (set_time_digit != 4'bxxxx) begin // If a valid digit (0-9) is input
            custom_time_enable <= 1;
        end else if (start || stop) begin // If Start or Stop is pressed, exit custom time entry
            custom_time_enable <= 0;
        end
    end

    // Instance for setting custom cook time (captures digits entered by user)
    time_to_cook custom_timer_setter (
        .clk_1s(sec_clock_out), // Uses 1Hz clock for synchronous digit capture (assumed for button presses)
        .reset(reset),
        .digit_input(set_time_digit),
        .first_sec_out(time_entered_fs),
        .second_sec_out(time_entered_ss),
        .first_min_out(time_entered_fm),
        .second_min_out(time_entered_sm)
    );

    // Instance of preset_cook to determine initial time, power, and temperature
    // based on selected preset button or custom time entry.
    preset_cook predefinde (
        .clk(clk), // Clock for any internal sequential logic in preset_cook
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
        .custom_time(custom_time_enable), // Indicates if in custom time entry mode
        .in_first_s(time_entered_fs),     // Passed time digits if in custom mode
        .in_second_s(time_entered_ss),
        .in_first_m(time_entered_fm),
        .in_second_m(time_entered_sm),
        .temperature_out(preset_temperature_out), // Output temperature level for the selected mode
        .first_s(preset_time_fs),         // Output preset/custom time (units seconds)
        .second_s(preset_time_ss),        // Output preset/custom time (tens seconds)
        .first_m(preset_time_fm),         // Output preset/custom time (units minutes)
        .second_m(preset_time_sm),        // Output preset/custom time (tens minutes)
        .power(preset_power_level)        // Output power level for the selected mode
    );

    // Assign the temperature output from the preset_cook module to the top-level output
    assign temperature = preset_temperature_out;

    // Instance of stop_clear module to handle the stop button logic
    stop_clear stop_controller (
        .stop(stop),
        .power_in(power), // Current microwave power state (for potential future logic within stop_clear)
        .power_out(microwave_power_on_signal), // Output to signal power off to the main power logic
        .clear_timer_signal(timer_clear_signal) // Output to signal timer clear
    );

    // Instance of start_30_button module to handle start button presses (add 30s, turn on)
    start_30_button start_controller (
        .clk(clk),
        .reset(reset),
        .prev_power_state(power > 0), // FIXED: Passes a 1-bit boolean (0 if power is 0, 1 if power > 0)
        .microwave_power_on(microwave_power_on_signal), // Output to signal power on to the main power logic
        .current_first_sec(current_first_s_display),    // Current time from display (input for +30s calculation)
        .current_second_sec(current_second_s_display),
        .current_first_min(current_first_m_display),
        .current_second_min(current_second_m_display),
        .new_first_s(timer_load_first_s),   // Output calculated new time (units seconds)
        .new_second_s(timer_load_second_s), // Output calculated new time (tens seconds)
        .new_first_m(timer_load_first_m),   // Output calculated new time (units minutes)
        .new_second_m(timer_load_second_m), // Output calculated new time (tens minutes)
        .start_button(start)                // Start button input
    );

    // Logic to select which time value (preset/custom or +30s) to load into the main countdown timer.
    // This forms a priority encoder: Start button takes highest priority, then presets, then clear.
    // CHANGED: Using conditional assignments for combinatorial logic
    assign timer_load_enable = (start || custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm || timer_clear_signal);

    assign timer_load_first_s = start ? start_controller.new_first_s :
                                (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_fs :
                                timer_clear_signal ? 4'd0 : 4'd0; // Default to 0 if no condition met

    assign timer_load_second_s = start ? start_controller.new_second_s :
                                 (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_ss :
                                 timer_clear_signal ? 4'd0 : 4'd0;

    assign timer_load_first_m = start ? start_controller.new_first_m :
                                (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_fm :
                                timer_clear_signal ? 4'd0 : 4'd0;

    assign timer_load_second_m = start ? start_controller.new_second_m :
                                 (custom_time_enable || popcorn || beverage || reheat || defrost || pizza || potato || vegetable || dinner || baby_milk || keep_warm) ? preset_time_sm :
                                 timer_clear_signal ? 4'd0 : 4'd0;


    // Main timer module for countdown.
    // It takes the loaded time and counts down using the 1Hz clock.
    timer cook_timer (
        .clk_1s(sec_clock_out), // 1Hz clock for countdown
        .reset(reset),
        .load_time_en(timer_load_enable), // Enable to load new time
        .initial_first_sec(timer_load_first_s),   // Time to load (units seconds)
        .initial_second_sec(timer_load_second_s), // Time to load (tens seconds)
        .initial_first_min(timer_load_first_m),   // Time to load (units minutes)
        .initial_second_min(timer_load_second_m), // Time to load (tens minutes)
        .current_first_s(current_first_s_display),    // Current time output (units seconds)
        .current_second_s(current_second_s_display),  // Current time output (tens seconds)
        .current_first_m(current_first_m_display),    // Current time output (units minutes)
        .current_second_m(current_second_m_display),  // Current time output (tens minutes)
        .clear_input(timer_clear_signal) // Signal to clear timer to 00:00
    );

    // Assign the current time digits from the timer module to the top-level outputs
    // These outputs will typically drive the 7-segment display modules.
    assign first_second_out = current_first_s_display;
    assign second_second_out = current_second_s_display;
    assign first_minute_out = current_first_m_display;
    assign second_minute_out = current_second_m_display;

    // Seven-segment display instances for each digit of the timer.
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

    // Audio output is permanently off as audio control logic has been removed.
    assign play_audio = 1'b0;

    // Buzzer instance: Activates when the timer reaches 00:00.
    buzzer kitchen_buzzer(
        .first_s(first_second_out),
        .second_s(second_second_out),
        .first_m(first_minute_out),
        .second_m(second_minute_out),
        .clk_1s(sec_clock_out), // Uses 1Hz clock for buzzer logic
        .buzzer_on(buzzer),     // Output to control external buzzer
        .microwave_power_off(microwave_power_off_signal) // Output to signal main power logic to turn off
    );

    // Logic to control the main microwave power level.
    // Power is set based on preset/custom, turned off by buzzer or stop button.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            power <= 8'd0; // Microwave off on reset
        end else if (microwave_power_on_signal) begin // Signal from start button or preset selection
            power <= preset_power_level; // Set power to the level from preset_cook
        end else if (microwave_power_off_signal) begin // Signal from buzzer (timer expired)
            power <= 8'd0; // Turn off power
        end else if (timer_clear_signal) begin // Signal from stop button
            power <= 8'd0; // Turn off power
        end
        // If power is currently 0 (off), and no button is pressed to turn it on, it remains 0.
        // If power is >0 (on), and no signal to turn it off, it remains at its level.
    end

    // PWM for magnetron power control. This module would drive the actual magnetron hardware.
    pwm_power magnetron_pwm (
        .clk(clk),           // Use fast system clock for PWM generation
        .duty_cycle(power),  // Input duty cycle based on microwave power level (0-100)
        .magnetron_on(magnetron_control) // Output PWM signal for magnetron
    );

endmodule


// ====================================================================
// Module: buzzer.v
// Controls the microwave buzzer based on timer completion.
// ====================================================================
module buzzer(
    input [3:0] first_s,        // Units of seconds digit from timer
    input [3:0] second_s,       // Tens of seconds digit from timer
    input [3:0] first_m,        // Units of minutes digit from timer
    input [3:0] second_m,       // Tens of minutes digit from timer
    input clk_1s,               // 1-second clock input for timed buzzer operation
    output reg buzzer_on,       // Output to control the physical buzzer
    output reg microwave_power_off // Output signal to inform top module to turn off microwave power
);

    reg [3:0] beep_count; // Counter for the duration of the buzzer sound

    // Initialize registers at simulation start
    initial begin
        beep_count = 0;
        buzzer_on = 0;
        microwave_power_off = 0;
    end

    always @(posedge clk_1s) begin
        // Default to not turning off power and buzzer off
        microwave_power_off <= 0;
        buzzer_on <= 0;

        // Check if the timer has reached 00:00:00:00
        if ((first_s == 4'd0) && (second_s == 4'd0) && (first_m == 4'd0) && (second_m == 4'd0)) begin
            // Timer is at 00:00.
            microwave_power_off <= 1; // Signal top module to turn off microwave power.

            // Control buzzer beeping duration
            if (beep_count < 4'd3) begin // Beep for 3 seconds (adjustable duration)
                buzzer_on <= 1;
                beep_count <= beep_count + 1;
            end else begin
                buzzer_on <= 0;          // Turn off buzzer after 3 seconds
                beep_count <= 4'd0;      // Reset beep counter
            end
        end else begin
            // If timer is not 00:00, ensure beep_count is reset.
            beep_count <= 4'd0;
        end
    end

endmodule


// ====================================================================
// Module: seven_segment.v
// Converts a 4-bit BCD number (0-9) to 7-segment display signals.
// Assuming common cathode display (segment 'on' is '1', 'off' is '0').
// ====================================================================
module seven_segment (
    input [3:0] number, // 4-bit BCD input (0-9)
    input reset,        // Asynchronous reset
    output reg a,        // Segment A output
    output reg b,        // Segment B output
    output reg c,        // Segment C output
    output reg d,        // Segment D output
    output reg e,        // Segment E output
    output reg f,        // Segment F output
    output reg g        // Segment G output
);

// Combinational logic to map BCD number to 7-segment display segments
// Pattern: {a,b,c,d,e,f,g}
//   --a--
//  f     b
//  --g--
// e     c
//  --d--
always @(*) begin
    if (reset) begin
        // All segments off on reset (assuming common cathode: 0=off, 1=on)
        a = 0; b = 0; c = 0; d = 0; e = 0; f = 0; g = 0;
    end else begin
        case (number)
            4'd0: {a,b,c,d,e,f,g} = 7'b1111110; // Displays 0
            4'd1: {a,b,c,d,e,f,g} = 7'b0110000; // Displays 1
            4'd2: {a,b,c,d,e,f,g} = 7'b1101101; // Displays 2
            4'd3: {a,b,c,d,e,f,g} = 7'b1111001; // Displays 3
            4'd4: {a,b,c,d,e,f,g} = 7'b0110011; // Displays 4
            4'd5: {a,b,c,d,e,f,g} = 7'b1011011; // Displays 5
            4'd6: {a,b,c,d,e,f,g} = 7'b1011111; // Displays 6
            4'd7: {a,b,c,d,e,f,g} = 7'b1110000; // Displays 7
            4'd8: {a,b,c,d,e,f,g} = 7'b1111111; // Displays 8
            4'd9: {a,b,c,d,e,f,g} = 7'b1111011; // Displays 9
            default: {a,b,c,d,e,f,g} = 7'b0000000; // All segments off for invalid input
        endcase
    end
end

endmodule


// ====================================================================
// Module: second_clock.v
// Generates a 1Hz clock signal from a higher frequency system clock.
// ====================================================================
module second_clock (
    input sys_clk,  // High frequency system clock input (e.g., 50 MHz)
    input reset,    // Asynchronous reset
    output reg clk_1s // 1-second clock output
);

    // Parameter for counting up to 1 second.
    // For a 50MHz sys_clk, 50,000,000 cycles = 1 second.
    // To generate a 1Hz clock (50% duty cycle), clk_1s toggles every 0.5 seconds.
    // So, the counter should count from 0 to (CLK_FREQ/2 - 1).
    parameter CLK_FREQ = 50_000_000;      // System clock frequency in Hz
    parameter COUNT_MAX = (CLK_FREQ / 2) - 1; // Max count for half-period of 1Hz clock

    reg [25:0] count; // Counter large enough to reach COUNT_MAX (2^25 = 33.5M, 2^26 = 67.1M)

    always @(posedge sys_clk or posedge reset) begin
        if (reset) begin
            count <= 0;      // Reset counter to 0
            clk_1s <= 0;      // Initialize 1-second clock to low
        end else begin
            if (count == COUNT_MAX) begin
                count <= 0;           // Reset counter when max count is reached
                clk_1s <= ~clk_1s;    // Toggle the 1-second clock output
            end else begin
                count <= count + 1;   // Increment counter
            end
        end
    end

endmodule


// ====================================================================
// Module: pwm_power.v
// Generates a Pulse Width Modulation (PWM) signal for magnetron control.
// The duty cycle is controlled by `duty_cycle` input (0-100%).
// ====================================================================
module pwm_power (
    input clk,           // High frequency clock (e.g., 50 MHz)
    input [7:0] duty_cycle, // Desired duty cycle percentage (0 to 100)
    output reg magnetron_on // PWM output signal for magnetron control
);
    reg [7:0] counter; // Counter for the PWM period (counts from 0 to PWM_PERIOD_MAX-1)

    // Parameter defining the resolution of the PWM. 100 levels for percentage.
    parameter PWM_PERIOD_MAX = 100;

    always @(posedge clk) begin
        // Increment counter, wrapping around at PWM_PERIOD_MAX
        if (counter == (PWM_PERIOD_MAX - 1)) begin
            counter <= 0;
        end else begin
            counter <= counter + 1;
        end

        // Determine magnetron_on state based on duty_cycle
        if (duty_cycle == 8'd0) begin // 0% duty cycle: always off
            magnetron_on <= 0;
        end else if (duty_cycle == 8'd100) begin // 100% duty cycle: always on
            magnetron_on <= 1;
        end else if (counter < duty_cycle) begin // For 1% to 99% duty cycle
            magnetron_on <= 1;
        end else begin
            magnetron_on <= 0;
        end
    end
endmodule


// ====================================================================
// Module: preset_cook.v
// Provides predefined cooking times, power levels, and temperatures
// based on selected preset buttons or custom time input.
// ====================================================================
module preset_cook (
    input clk, // System clock (included for consistency, but logic is combinatorial/resets)
    input reset,
    input popcorn, beverage, reheat, defrost, pizza, potato, vegetable,
    input dinner, baby_milk, keep_warm, // Preset selection buttons
    input custom_time,         // Flag indicating if custom time entry is active
    input [3:0] in_first_s,    // Custom time input: units of seconds
    input [3:0] in_second_s,   // Custom time input: tens of seconds
    input [3:0] in_first_m,    // Custom time input: units of minutes
    input [3:0] in_second_m,   // Custom time input: tens of minutes
    output reg [7:0] temperature_out, // Output: Target temperature for the cooking mode
    output reg [3:0] first_s,         // Output: Preset/custom time - units of seconds
    output reg [3:0] second_s,        // Output: Preset/custom time - tens of seconds
    output reg [3:0] first_m,         // Output: Preset/custom time - units of minutes
    output reg [3:0] second_m,        // Output: Preset/custom time - tens of minutes
    output reg [7:0] power           // Output: Preset/custom power level (0-100)
);

    // Combinational logic to set time, power, and temperature based on selection.
    // Priority: Custom time > Popcorn > Beverage > ...
    always @(*) begin
        // Default values when no specific button is pressed or custom_time is inactive.
        // These are effectively the 'off' or 'idle' state values.
        first_s = 0;
        second_s = 0;
        first_m = 0;
        second_m = 0;
        power = 0;
        temperature_out = 8'd0; // Reset/default temperature to 0 (ambient)

        if (reset) begin
            // On reset, all outputs explicitly go to 0.
            // This is already handled by the default values above, but explicit for clarity.
        end else if (custom_time) begin
            // If custom time mode is active, use the time entered by the user.
            first_s = in_first_s;
            second_s = in_second_s;
            first_m = in_first_m;
            second_m = in_second_m;
            power = 8'd100; // Default to 100% power for custom time
            temperature_out = 8'd75; // Default temperature for custom time (adjustable)
        end else if (popcorn) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 2; second_m = 0; // 2 minutes (02:00)
            power = 8'd100; // Full power
            temperature_out = 8'd100; // High temp
        end else if (beverage) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 1; second_m = 0; // 1 minute (01:00)
            power = 8'd70; // Medium power
            temperature_out = 8'd80; // Medium-high temp
        end else if (reheat) begin
            first_s = 0; second_s = 3; // 30 seconds
            first_m = 1; second_m = 0; // 1 minute (01:30)
            power = 8'd70; // Medium power
            temperature_out = 8'd70; // Medium temp
        end else if (defrost) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 3; second_m = 0; // 3 minutes (03:00)
            power = 8'd35; // Low power
            temperature_out = 8'd25; // Close to ambient (defrosts without cooking)
        end else if (pizza) begin
            first_s = 0; second_s = 3; // 30 seconds
            first_m = 4; second_m = 0; // 4 minutes (04:30)
            power = 8'd80; // High power
            temperature_out = 8'd75;
        end else if (potato) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 4; second_m = 0; // 4 minutes (04:00)
            power = 8'd100; // Full power
            temperature_out = 8'd90;
        end else if (vegetable) begin
            first_s = 0; second_s = 3; // 30 seconds
            first_m = 3; second_m = 0; // 3 minutes (03:30)
            power = 8'd80; // High power
            temperature_out = 8'd85;
        end else if (dinner) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 3; second_m = 0; // 3 minutes (03:00)
            power = 8'd80; // High power
            temperature_out = 8'd80;
        end else if (baby_milk) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 1; second_m = 0; // 1 minute (01:00)
            power = 8'd50; // Medium-low power
            temperature_out = 8'd35; // Warm, not hot
        end else if (keep_warm) begin
            first_s = 0; second_s = 0; // 0 seconds
            first_m = 3; second_m = 0; // 3 minutes (03:00)
            power = 8'd10; // Very low power
            temperature_out = 8'd65; // Keep warm temperature
        end
        // If no preset or custom time is active, outputs remain at their default (0) values.
    end

endmodule


// ====================================================================
// Module: start_30_button.v
// Handles the logic for the "Start" button, including adding 30 seconds
// to the current time and signaling microwave power on.
// ====================================================================
module start_30_button (
    input clk,            // System clock for synchronous logic (debouncing, state update)
    input reset,          // Asynchronous reset
    input prev_power_state, // 1-bit input: Current state of microwave (0=off, 1=on)
    output reg microwave_power_on, // 1-bit output: Signal to turn microwave power on/off
    input [3:0] current_first_sec,  // Current time displayed: units of seconds
    input [3:0] current_second_sec, // Current time displayed: tens of seconds
    input [3:0] current_first_min,  // Current time displayed: units of minutes
    input [3:0] current_second_min, // Current time displayed: tens of minutes
    output reg [3:0] new_first_s,    // Output: Updated units of seconds for timer load
    output reg [3:0] new_second_s,   // Output: Updated tens of seconds for timer load
    output reg [3:0] new_first_m,    // Output: Updated units of minutes for timer load
    output reg [3:0] new_second_m,   // Output: Updated tens of minutes for timer load
    input start_button               // Level-sensitive start button input
);

    // Signals for debouncing/edge detection of the start button to ensure a single trigger
    reg start_button_sync;
    reg start_button_prev;
    wire start_button_edge;

    // Synchronize button input to avoid metastability issues from asynchronous inputs.
    // This creates a 2-flip-flop synchronizer chain.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_button_sync <= 0;
            start_button_prev <= 0;
        end else begin
            start_button_sync <= start_button;    // First stage
            start_button_prev <= start_button_sync; // Second stage
        end
    end

    // Detect the rising edge of the synchronized start button signal.
    // This ensures the action only happens once per button press.
    assign start_button_edge = (start_button_sync == 1'b1) && (start_button_prev == 1'b0);

    reg [9:0] total_seconds_current; // Holds current time converted to total seconds
    reg [9:0] total_seconds_new;     // Holds new time after adding 30 seconds

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            microwave_power_on <= 0; // Microwave power off on reset
            new_first_s <= 4'd0;     // New time outputs reset to 0
            new_second_s <= 4'd0;
            new_first_m <= 4'd0;
            new_second_m <= 4'd0;
        end else begin
            // Default `microwave_power_on` to 0, it will be set to 1 only on edge
            microwave_power_on <= 0;

            // Default `new_time` outputs to the current display time if no start edge detected
            // This ensures they continuously reflect the current time when no action is taken.
            new_first_s <= current_first_sec;
            new_second_s <= current_second_sec;
            new_first_m <= current_first_min;
            new_second_m <= current_second_min;

            if (start_button_edge) begin // Action happens only on the rising edge of start_button
                microwave_power_on <= 1; // Signal to turn on microwave power

                // Convert current time (BCD digits) to total seconds for arithmetic
                total_seconds_current = (current_second_min * 600) + (current_first_min * 60) +
                                        (current_second_sec * 10) + current_first_sec;

                // Add 30 seconds to the total time
                total_seconds_new = total_seconds_current + 30;

                // Cap the time at the maximum displayable value (99 minutes 59 seconds = 5999 seconds).
                // This prevents the timer from rolling over past a valid displayable range.
                if (total_seconds_new > (99 * 60 + 59)) begin
                    total_seconds_new = (99 * 60 + 59);
                end

                // Convert the new total seconds back into BCD digits for the timer load outputs.
                new_second_m <= (total_seconds_new / 600);     // Tens of minutes (e.g., for 1234 seconds -> 20 min -> 2)
                new_first_m  <= (total_seconds_new / 60) % 10; // Units of minutes (e.g., for 1234 seconds -> 20 min -> 0)
                new_second_s <= (total_seconds_new % 60) / 10; // Tens of seconds (e.g., for 34 seconds -> 3)
                new_first_s  <= (total_seconds_new % 60) % 10; // Units of seconds (e.g., for 34 seconds -> 4)
            end
        end
    end

endmodule


// ====================================================================
// Module: stop_clear.v
// Handles the logic for the "Stop/Clear" button.
// It signals to turn off microwave power and clear the timer display.
// ====================================================================
module stop_clear(
    input stop, // Input: Stop/Clear button signal (level-sensitive)
    input [7:0] power_in, // Input: Current microwave power state (for potential future logic, currently not used)
    output reg power_out, // Output: Signal to the top module to turn off microwave power
    output reg clear_timer_signal // Output: Signal to clear the timer display to 00:00
);

    // This module's outputs are combinational based on the 'stop' input.
    // When 'stop' is asserted, it clears the timer and signals power off.
    always @(*) begin
        if (stop) begin
            clear_timer_signal = 1; // Assert signal to clear the timer display
            power_out = 0;          // Signal to turn microwave power off
        end else begin
            clear_timer_signal = 0; // De-assert when stop is not pressed
            power_out = 0;          // Default to 0 when not active.
                                    // The main 'power' control in top_microwave will manage current power state.
        end
    end

endmodule


// ====================================================================
// Module: time_to_cook.v
// Manages the entry of custom cooking time digits from a keypad.
// It shifts digits into a 4-digit buffer (MM:SS format).
// ====================================================================
module time_to_cook (
    input clk_1s,        // 1-second clock (for synchronous digit capture)
    input reset,         // Asynchronous reset
    input [3:0] digit_input, // 4-bit BCD input from number pad (0-9, or 4'bxxxx for no input)
    output reg [3:0] first_sec_out,  // Output: Units of seconds digit
    output reg [3:0] second_sec_out, // Output: Tens of seconds digit
    output reg [3:0] first_min_out,  // Output: Units of minutes digit
    output reg [3:0] second_min_out  // Output: Tens of minutes digit
);

    // Internal registers to hold the last 4 entered digits.
    // Array order: digit_buffer[0] = M2, [1] = M1, [2] = S2, [3] = S1 (rightmost digit)
    reg [3:0] digit_buffer [0:3];

    // Initial block for simulation setup: sets all outputs and buffer to 0.
    initial begin
        first_sec_out = 4'd0;
        second_sec_out = 4'd0;
        first_min_out = 4'd0;
        second_min_out = 4'd0;
        for (int i = 0; i < 4; i = i + 1) begin
            digit_buffer[i] = 4'd0;
        end
    end

    // Synchronous logic to capture and shift digits on the positive edge of clk_1s.
    always @(posedge clk_1s or posedge reset) begin
        if (reset) begin
            // On reset, clear all digits and buffer.
            first_sec_out <= 4'd0;
            second_sec_out <= 4'd0;
            first_min_out <= 4'd0;
            second_min_out <= 4'd0;
            for (int i = 0; i < 4; i = i + 1) begin
                digit_buffer[i] <= 4'd0;
            end
        end else begin
            if (digit_input != 4'bxxxx) begin // If a new valid digit (0-9) is pressed
                // Shift existing digits left: M2 <- M1, M1 <- S2, S2 <- S1, New Digit -> S1
                digit_buffer[0] <= digit_buffer[1]; // Old M1 becomes new M2
                digit_buffer[1] <= digit_buffer[2]; // Old S2 becomes new M1
                digit_buffer[2] <= digit_buffer[3]; // Old S1 becomes new S2
                digit_buffer[3] <= digit_input;     // New digit becomes new S1 (rightmost)
            end
            // Continuously assign outputs from the internal buffer.
            // This is combinatorial and will reflect the latest buffer state immediately.
            first_sec_out <= digit_buffer[3];
            second_sec_out <= digit_buffer[2];
            first_min_out <= digit_buffer[1];
            second_min_out <= digit_buffer[0];
        end
    end

endmodule


// ====================================================================
// Module: timer.v
// This module implements the countdown timer logic for the microwave.
// It loads an initial time and decrements it every second.
// ====================================================================
module timer (
    input clk_1s,        // 1-second clock for decrementing the timer
    input reset,         // Asynchronous reset
    input load_time_en,  // Enable signal to load a new initial time
    input [3:0] initial_first_sec,  // Initial time: units of seconds
    input [3:0] initial_second_sec, // Initial time: tens of seconds
    input [3:0] initial_first_min,  // Initial time: units of minutes
    input [3:0] initial_second_min, // Initial time: tens of minutes
    output reg [3:0] current_first_s,   // Output: Current units of seconds
    output reg [3:0] current_second_s,  // Output: Current tens of seconds
    output reg [3:0] current_first_m,   // Output: Current units of minutes
    output reg [3:0] current_second_m,  // Output: Current tens of minutes
    input clear_input // Signal to clear the timer display to 00:00 (from stop_clear module)
);

    // Internal registers to hold the current time digits during countdown.
    reg [3:0] fs, ss, fm, sm; // units_sec, tens_sec, units_min, tens_min

    // Initial block to set initial values for simulation.
    initial begin
        fs = 4'd0;
        ss = 4'd0;
        fm = 4'd0;
        sm = 4'd0;
    end

    // Main sequential logic for timer operation.
    always @(posedge clk_1s or posedge reset) begin
        if (reset || clear_input) begin // If reset or clear is active, set time to 00:00
            fs <= 4'd0;
            ss <= 4'd0;
            fm <= 4'd0;
            sm <= 4'd0;
        end else if (load_time_en) begin // If load enable is high, load the new initial time
            fs <= initial_first_sec;
            ss <= initial_second_sec;
            fm <= initial_first_min;
            sm <= initial_second_min;
        end else begin // If not resetting/clearing and not loading, then countdown
            // Check if timer has already reached 00:00. If so, stop decrementing.
            if ((fs == 4'd0) && (ss == 4'd0) && (fm == 4'd0) && (sm == 4'd0)) begin
                // Timer is already at 00:00, do nothing. Values remain at 0.
            end else begin
                // Decrement units of seconds (fs)
                if (fs > 4'd0) begin
                    fs <= fs - 1;
                end else begin // fs is 0, so rollover and decrement tens of seconds (ss)
                    fs <= 4'd9; // Reset fs to 9 (e.g., 05 -> 59)
                    if (ss > 4'd0) begin
                        ss <= ss - 1;
                    end else begin // ss is 0, so rollover and decrement units of minutes (fm)
                        ss <= 4'd5; // Reset ss to 5 (e.g., 10:00 -> 09:59)
                        if (fm > 4'd0) begin
                            fm <= fm - 1;
                        end else begin // fm is 0, so rollover and decrement tens of minutes (sm)
                            fm <= 4'd9; // Reset fm to 9 (e.g., 01:00 -> 00:59)
                            if (sm > 4'd0) begin
                                sm <= sm - 1;
                            end else begin // sm is 0, which means 00:00:00:00 (all digits are zero)
                                // Timer has reached absolute zero, ensure all digits are 0 and stop.
                                // This branch is theoretically for the final tick when sm becomes 0.
                                fs <= 4'd0;
                                ss <= 4'd0;
                                fm <= 4'd0;
                                sm <= 4'd0;
                            end
                        end
                    end
                end
            end
        end
    end

    // Assign internal countdown registers to the output ports.
    // These outputs are declared as `output reg` and are combinatorially driven by `fs`, etc.
    always @(*) begin
        current_first_s = fs;
        current_second_s = ss;
        current_first_m = fm;
        current_second_m = sm;
    end

endmodule

