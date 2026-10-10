module project (
    input  wire       clk,
    input  wire [1:0] mode_sel,
    output wire       buzzer,
    output wire [6:0] seg_hr_tens,
    output wire [6:0] seg_hr_ones,
    output wire [6:0] seg_min_tens,
    output wire [6:0] seg_min_ones
);

    parameter [4:0] INIT_HR    = 5'd16;
    parameter [5:0] INIT_MIN   = 6'd25;
    parameter [5:0] INIT_SEC   = 6'd0;
    parameter [3:0] INIT_MONTH = 4'd9;
    parameter [4:0] INIT_DAY   = 5'd15;

    parameter [4:0] ALARM_HR   = 5'd16;
    parameter [5:0] ALARM_MIN  = 6'd26;

    reg [25:0] tick_counter = 26'd0;
    reg [5:0]  sec          = INIT_SEC;
    reg [5:0]  min          = INIT_MIN;
    reg [4:0]  hr           = INIT_HR;
    reg [3:0]  month        = INIT_MONTH;
    reg [4:0]  day          = INIT_DAY;

    reg [4:0]  days_in_month;
    always @(*) begin
        case (month)
            4'd2:            days_in_month = 5'd28;
            4'd4, 4'd6,
            4'd9, 4'd11:     days_in_month = 5'd30;
            default:         days_in_month = 5'd31;
        endcase
    end

    always @(posedge clk) begin
        if (tick_counter >= 26'd49_999_999) begin
            tick_counter <= 26'd0;
            if (sec == 6'd59) begin
                sec <= 6'd0;
                if (min == 6'd59) begin
                    min <= 6'd0;
                    if (hr == 5'd23) begin
                        hr <= 5'd0;
                        if (day >= days_in_month) begin
                            day <= 5'd1;
                            if (month == 4'd12)
                                month <= 4'd1;
                            else
                                month <= month + 1'b1;
                        end else begin
                            day <= day + 1'b1;
                        end
                    end else begin
                        hr <= hr + 1'b1;
                    end
                end else begin
                    min <= min + 1'b1;
                end
            end else begin
                sec <= sec + 1'b1;
            end
        end else begin
            tick_counter <= tick_counter + 1'b1;
        end
    end

    wire is_alarm_active = (hr == ALARM_HR) && (min == ALARM_MIN);

    reg [15:0] beep_cnt = 16'd0;
    reg        tone_1khz = 1'b0;

    always @(posedge clk) begin
        if (beep_cnt >= 16'd24_999) begin
            beep_cnt <= 16'd0;
            tone_1khz <= ~tone_1khz;
        end else begin
            beep_cnt <= beep_cnt + 1'b1;
        end
    end

    wire beep_gate = sec[0];
    assign buzzer = is_alarm_active ? (beep_gate & tone_1khz) : 1'b0;

    reg [3:0] disp_d3;
    reg [3:0] disp_d2;
    reg [3:0] disp_d1;
    reg [3:0] disp_d0;

    always @(*) begin
        case (mode_sel)
            2'b00: begin
                disp_d3 = hr / 10;
                disp_d2 = hr % 10;
                disp_d1 = min / 10;
                disp_d0 = min % 10;
            end
            2'b01: begin
                disp_d3 = day / 10;
                disp_d2 = day % 10;
                disp_d1 = month / 10;
                disp_d0 = month % 10;
            end
            2'b10: begin
                disp_d3 = ALARM_HR / 10;
                disp_d2 = ALARM_HR % 10;
                disp_d1 = ALARM_MIN / 10;
                disp_d0 = ALARM_MIN % 10;
            end
            default: begin
                disp_d3 = hr / 10;
                disp_d2 = hr % 10;
                disp_d1 = min / 10;
                disp_d0 = min % 10;
            end
        endcase
    end

    seven_seg_cc dec_h1 (.bcd(disp_d3), .seg(seg_hr_tens));
    seven_seg_cc dec_h0 (.bcd(disp_d2), .seg(seg_hr_ones));
    seven_seg_cc dec_m1 (.bcd(disp_d1), .seg(seg_min_tens));
    seven_seg_cc dec_m0 (.bcd(disp_d0), .seg(seg_min_ones));

endmodule

module seven_seg_cc (
    input  wire [3:0] bcd,
    output reg  [6:0] seg
);
    always @(*) begin
        case (bcd)
            4'd0: seg = 7'b0111111;
            4'd1: seg = 7'b0000110;
            4'd2: seg = 7'b1011011;
            4'd3: seg = 7'b1001111;
            4'd4: seg = 7'b1100110;
            4'd5: seg = 7'b1101101;
            4'd6: seg = 7'b1111101;
            4'd7: seg = 7'b0000111;
            4'd8: seg = 7'b1111111;
            4'd9: seg = 7'b1101111;
            default: seg = 7'b0000000;
        endcase
    end
endmodule