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

