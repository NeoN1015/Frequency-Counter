`default_nettype none

module tt_um_freq_counter (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,      // Expected: 25.175 MHz or 25 MHz VGA clock
    input  wire       rst_n
);

    // ============================================================
    // 1. INPUT SYNCHRONIZER
    // ============================================================
    reg signal_sync0, signal_sync1, signal_prev;

    always @(posedge clk) begin
        if (!rst_n) begin
            signal_sync0 <= 1'b0;
            signal_sync1 <= 1 me1'b0;
            signal_prev  <= 1'b0;
        end else begin
            signal_sync0 <= ui_in[0];
            signal_sync1 <= signal_sync0;
            signal_prev  <= signal_sync1;
        end
    end

    wire rising_edge = signal_sync1 && !signal_prev;

    // ============================================================
    // 2. PRESCALER (/100)
    // ============================================================
    reg [6:0] prescale_cnt;
    reg       divided_pulse;

    always @(posedge clk) begin
        if (!rst_n) begin
            prescale_cnt  <= 7'd0;
            divided_pulse <= 1'b0;
        end else begin
            divided_pulse <= 1'b0;
            if (rising_edge) begin
                if (prescale_cnt == 7'd99) begin
                    prescale_cnt  <= 7'd0;
                    divided_pulse <= 1'b1;
                end else begin
                    prescale_cnt  <= prescale_cnt + 1'b1;
                end
            end
        end
    end

    // ============================================================
    // 3. REFERENCE TIMER (1 ms Gate Window based on 25 MHz Clock)
    // 25,000 cycles = 1 millisecond
    // ============================================================
    localparam WINDOW_CYCLES = 25_000;
    reg [14:0] window_cnt;
    reg        tick_1ms;

    always @(posedge clk) begin
        if (!rst_n) begin
            window_cnt <= 15'd0;
            tick_1ms   <= 1'b0;
        end else begin
            if (window_cnt == WINDOW_CYCLES - 1) begin
                window_cnt <= 15'd0;
                tick_1ms   <= 1'b1;
            end else begin
                window_cnt <= window_cnt + 1'b1;
                tick_1ms   <= 1'b0;
            end
        end
    end

    // ============================================================
    // 4. FREQUENCY COUNTER LOGIC
    // ============================================================
    reg [7:0] freq_count;
    reg [7:0] freq_latched;

    always @(posedge clk) begin
        if (!rst_n) begin
            freq_count   <= 8'd0;
            freq_latched <= 8'd0;
        end else begin
            if (tick_1ms) begin
                freq_latched <= freq_count;
                freq_count   <= divided_pulse ? 8'd1 : 8'd0;
            end else if (divided_pulse) begin
                freq_count <= freq_count + 1'b1;
            end
        end
    end

    // ============================================================
    // 5. VGA TIMING GENERATOR (640x480 @ 60Hz)
    // ============================================================
    // Horizontal Timing: 640 visible + 16 front porch + 96 sync + 48 back porch = 800 total
    // Vertical Timing: 480 visible + 10 front porch + 2 sync + 33 back porch = 525 total
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    always @(posedge clk) begin
        if (!rst_n) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end else begin
            if (h_cnt == 10'd799) begin
                h_cnt <= 10'd0;
                if (v_cnt == 10'd524)
                    v_cnt <= 10'd0;
                else
                    v_cnt <= v_cnt + 1'b1;
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    wire hsync = ~(h_cnt >= (640 + 16) && h_cnt < (640 + 16 + 96));
    wire vsync = ~(v_cnt >= (480 + 10) && v_cnt < (480 + 10 + 2));
    wire video_on = (h_cnt < 640) && (v_cnt < 480);

    // ============================================================
    // 6. VISUAL BAR CHART GENERATOR
    // Renders a visual bar on screen proportional to freq_latched value
    // ============================================================
    wire [9:0] bar_width = {2'b00, freq_latched} * 2; // Scale factor for 8-bit count
    wire is_bar = (v_cnt >= 200 && v_cnt <= 280) && (h_cnt >= 50 && h_cnt < (50 + bar_width));
    wire is_border = (v_cnt >= 195 && v_cnt <= 285) && (h_cnt >= 45 && h_cnt <= 565) &&
                     ((v_cnt <= 198 || v_cnt >= 282) || (h_cnt <= 48 || h_cnt >= 562));

    reg [1:0] r, g, b;

    always @(*) begin
        if (!video_on) begin
            r = 2'b00;
            g = 2'b00;
            b = 2'b00;
        end else if (is_bar) begin
            r = 2'b00; // Bright Green Bar
            g = 2'b11;
            b = 2'b00;
        end else if (is_border) begin
            r = 2'b11; // White Border
            g = 2'b11;
            b = 2'b11;
        end else begin
            r = 2'b00; // Dark Blue Background
            g = 2'b00;
            b = 2'b01;
        end
    end

    // ============================================================
    // 7. OUTPUT ASSIGNMENT (TT Standard VGA PMOD)
    // ============================================================
    assign uo_out[0] = r[1];
    assign uo_out[1] = g[1];
    assign uo_out[2] = b[1];
    assign uo_out[3] = vsync;
    assign uo_out[4] = r[0];
    assign uo_out[5] = g[0];
    assign uo_out[6] = b[0];
    assign uo_out[7] = hsync;

    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule    // ============================================================
    reg [6:0] prescale_cnt;
    reg       divided_pulse;

    always @(posedge clk) begin
        if (!rst_n) begin
            prescale_cnt  <= 7'd0;
            divided_pulse <= 1'b0;
        end else begin
            divided_pulse <= 1'b0; // Default state
            if (rising_edge) begin
                if (prescale_cnt == 7'd99) begin
                    prescale_cnt  <= 7'd0;
                    divided_pulse <= 1'b1;
                end else begin
                    prescale_cnt  <= prescale_cnt + 1'b1;
                end
            end
        end
    end

    // ============================================================
    // 3. REFERENCE TIMER (1 millisecond Gate Window)
    // 50 MHz Clock = 50,000 cycles per 1 ms
    // ============================================================
    localparam WINDOW_CYCLES = 50_000;
    reg [15:0] window_cnt;
    reg        tick_1ms;

    always @(posedge clk) begin
        if (!rst_n) begin
            window_cnt <= 16'd0;
            tick_1ms   <= 1'b0;
        end else begin
            if (window_cnt == WINDOW_CYCLES - 1) begin
                window_cnt <= 16'd0;
                tick_1ms   <= 1'b1; // Single-cycle strobe every 1 ms
            end else begin
                window_cnt <= window_cnt + 1'b1;
                tick_1ms   <= 1'b0;
            end
        end
    end

    // ============================================================
    // 4. FREQUENCY COUNTER & STABLE LATCH LOGIC
    // ============================================================
    reg [7:0] freq_count;
    reg [7:0] freq_latched;

    always @(posedge clk) begin
        if (!rst_n) begin
            freq_count   <= 8'd0;
            freq_latched <= 8'd0;
        end else begin
            if (tick_1ms) begin
                freq_latched <= freq_count; // Latch result continuously for 1 ms
                freq_count   <= divided_pulse ? 8'd1 : 8'd0; // Reset counter for next window
            end else if (divided_pulse) begin
                freq_count <= freq_count + 1'b1;
            end
        end
    end

    // ============================================================
    // 5. OUTPUT ASSIGNMENTS
    // ============================================================
    assign uo_out  = freq_latched;
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    // Unused inputs warning suppressor
    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
