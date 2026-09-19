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
    // INPUT
    // ============================================================
    wire signal_in = ui_in[0];

    // ============================================================
    // EDGE DETECTOR + PRESCALER (divide by 100)
    // ============================================================
    reg       signal_prev;
    reg [6:0] prescale_cnt;
    reg       divided_pulse;

    always @(posedge clk) begin
        if (!rst_n) begin
            signal_prev   <= 0;
            prescale_cnt  <= 0;
            divided_pulse <= 0;
        end else begin
            signal_prev <= signal_in;

            if (signal_in && !signal_prev) begin
                if (prescale_cnt == 99) begin
                    prescale_cnt  <= 0;
                    divided_pulse <= 1;
                end else begin
                    prescale_cnt  <= prescale_cnt + 1;
                    divided_pulse <= 0;
                end
            end else begin
                divided_pulse <= 0;
            end
        end
    end

    // ============================================================
    // REFERENCE TIMER: 1 millisecond window
    // 50 MHz / 1000 = 50,000 cycles
    // ============================================================
    localparam WINDOW_CYCLES = 50_000;

    reg [15:0] window_cnt;
    reg        window_open;

    always @(posedge clk) begin
        if (!rst_n) begin
            window_cnt  <= 0;
            window_open <= 0;
        end else begin
            if (window_cnt == WINDOW_CYCLES - 1) begin
                window_cnt  <= 0;
                window_open <= ~window_open;
            end else begin
                window_cnt <= window_cnt + 1;
            end
        end
    end

    // ============================================================
    // FREQUENCY COUNTER
    // ============================================================
    reg [7:0] freq_count;
    reg [7:0] freq_latched;

    always @(posedge clk) begin
        if (!rst_n) begin
            freq_count   <= 0;
            freq_latched <= 0;
        end else begin
            if (window_open) begin
                if (divided_pulse)
                    freq_count <= freq_count + 1;
            end else begin
                freq_latched <= freq_count;
                freq_count   <= 0;
            end
        end
    end

    // ============================================================
    // OUTPUT
    // ============================================================
    assign uo_out  = freq_latched;
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
