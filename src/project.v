`default_nettype none

module tt_um_freq_counter (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ============================================================
    // 1. INPUT SYNCHRONIZER (Prevents Metastability)
    // ============================================================
    reg signal_sync0;
    reg signal_sync1;
    reg signal_prev;

    always @(posedge clk) begin
        if (!rst_n) begin
            signal_sync0 <= 1'b0;
            signal_sync1 <= 1'b0;
            signal_prev  <= 1'b0;
        end else begin
            signal_sync0 <= ui_in[0];
            signal_sync1 <= signal_sync0;
            signal_prev  <= signal_sync1;
        end
    end

    wire rising_edge = signal_sync1 && !signal_prev;

    // ============================================================
    // 2. PRESCALER (Divide Input Frequency by 100)
    // ============================================================
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
