module audio_control(
    input [3:0] first_s,
    input [3:0] first_m,
    input [3:0] second_m,
    input [7:0] temperature,
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
    output reg [16:0] mem_addr,
    output reg play_audio
);

    reg [7:0] total_time;

    always @(*) begin
        total_time = first_m * 10 + second_m;
        play_audio = 0;
        mem_addr = 17'bx;

        if (door_open) begin
            mem_addr = 17'h0000;         
            play_audio = 1;
        end
        else if (temperature > 8'd100) begin
            mem_addr = 17'h1000;         
            play_audio = 1;
        end
        else if (total_time > 8'd30) begin
            mem_addr = 17'h2000;          
            play_audio = 1;
        end
        else if (popcorn) begin
            mem_addr = 17'h3000;
            play_audio = 1;
        end
        else if (beverage) begin
            mem_addr = 17'h4000;
            play_audio = 1;
        end
        else if (reheat) begin
            mem_addr = 17'h5000;
            play_audio = 1;
        end
        else if (defrost) begin
            mem_addr = 17'h6000;
            play_audio = 1;
        end
        else if (pizza) begin
            mem_addr = 17'h7000;
            play_audio = 1;
        end
        else if (potato) begin
            mem_addr = 17'h8000;
            play_audio = 1;
        end
        else if (vegetable) begin
            mem_addr = 17'h9000;
            play_audio = 1;
        end
        else if (dinner) begin
            mem_addr = 17'hA000;
            play_audio = 1;
        end
        else if (baby_milk) begin
            mem_addr = 17'hB000;
            play_audio = 1;
        end
        else if (keep_warm) begin
            mem_addr = 17'hC000;
            play_audio = 1;
        end
    end

endmodule

