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
    // 1. INPUT SYNCHRONIZER
    // ============================================================
    reg signal_sync0, signal_sync1, signal_prev;
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
    // 2. PRESCALER (÷100)
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
                    prescale_cnt <= prescale_cnt + 1'b1;
                end
            end
        end
    end

    // ============================================================
    // 3. REFERENCE TIMER (1 ms gate @ 25 MHz pixel clock)
    //    VGA playground runs at 25.175 MHz. Use 25,000 cycles.
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
    // 4. FREQUENCY COUNTER & LATCH
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
    // 5. VGA SYNC GENERATOR
    //    hvsync_generator is provided by the playground.
    //    640x480 @ 60 Hz, 25.175 MHz pixel clock.
    // ============================================================
    wire hsync, vsync, video_active;
    wire [9:0] pix_x, pix_y;

    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // ============================================================
    // 6. DISPLAY LOGIC
    // ============================================================

    // --- BAR GRAPH ---
    // Draw a horizontal bar whose width maps freq_latched (0-255)
    // to 0-512 pixels, centred vertically.
    wire [9:0] bar_width   = {freq_latched, 1'b0};  // 0-510
    wire       bar_area    = (pix_y >= 10'd180) && (pix_y < 10'd220)
                          && (pix_x < bar_width);
    // Bar border box
    wire       bar_border  = (pix_y == 10'd175 || pix_y == 10'd224)
                          && (pix_x < 10'd515);
    wire       bar_side    = (pix_x == 10'd0 || pix_x == 10'd514)
                          && (pix_y >= 10'd175) && (pix_y <= 10'd224);

    // --- BINARY DISPLAY ---
    // Show the 8 bits of freq_latched as coloured dots, row 260-310.
    // Each bit is a 40px wide, 50px tall block.
    wire [2:0] bit_slot    = pix_x[8:6];          // 0-7 for x=0..511
    wire       in_bits_row = (pix_y >= 10'd260) && (pix_y < 10'd310)
                          && (pix_x < 10'd320);
    wire       bit_val     = freq_latched[7 - bit_slot];
    wire       bit_cell    = in_bits_row && (pix_x[5:0] < 6'd36);  // 36/64 fill

    // --- BACKGROUND GRID (subtle) ---
    wire       grid        = ((pix_x[4:0] == 5'd0) || (pix_y[4:0] == 5'd0));

    // --- COLOUR MIXING ---
    reg [1:0] R, G, B;
    always @(*) begin
        R = 2'b00; G = 2'b00; B = 2'b00;
        if (!video_active) begin
            R = 2'b00; G = 2'b00; B = 2'b00;
        end else if (bar_area) begin
            // Bar: green → yellow → red based on fill level
            R = (freq_latched > 8'd127) ? 2'b11 : 2'b00;
            G = (freq_latched < 8'd200) ? 2'b11 : 2'b00;
            B = 2'b00;
        end else if (bar_border || bar_side) begin
            R = 2'b11; G = 2'b11; B = 2'b11;  // white border
        end else if (bit_cell) begin
            // Bit is 1 → cyan, bit is 0 → dark blue
            R = 2'b00;
            G = bit_val ? 2'b11 : 2'b01;
            B = bit_val ? 2'b11 : 2'b10;
        end else if (grid) begin
            R = 2'b00; G = 2'b01; B = 2'b01;  // dim teal grid
        end else begin
            R = 2'b00; G = 2'b00; B = 2'b01;  // dark blue background
        end
    end

    // TinyVGA PMOD pinout
    assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;

    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
