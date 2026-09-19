`default_nettype none

module tt_um_freq_counter (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (1 = output, 0 = input)
    input  wire       ena,      // Always 1 when the design is powered
    input  wire       clk,      // Clock (50 MHz)
    input  wire       rst_n     // Reset (active low)
);

    // ============================================================
    // INPUT
    // ============================================================
    wire signal_in = ui_in[0];  // Frequency signal goes to pin 0

    // ============================================================
    // EDGE DETECTOR + PRESCALER (divide by 100)
    // ============================================================
    reg       signal_prev;
    reg [6:0] prescale_cnt;   // 0 to 99
    reg       divided_pulse;  // One pulse every 100 rising edges

    always @(posedge clk) begin
        if (!rst_n) begin
            signal_prev   <= 0;
            prescale_cnt  <= 0;
            divided_pulse <= 0;
        end else begin
            signal_prev <= signal_in;

            // Detect rising edge of input
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
    // ============================================================
    // 50 MHz clock = 50,000,000 cycles/second
    // 1 millisecond = 50,000 cycles
    localparam WINDOW_CYCLES = 50_000;

    reg [15:0] window_cnt;    // 16 bits (max 65,535)
    reg        window_open;   // 1 = counting, 0 = latching

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
    reg [7:0] freq_count;     // Running count
    reg [7:0] freq_latched;   // Stable output

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
    // OUTPUT ASSIGNMENT
    // ============================================================
    assign uo_out  = freq_latched;
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    // Prevent unused signal warnings
    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
