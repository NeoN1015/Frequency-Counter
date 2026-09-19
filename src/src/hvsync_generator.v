`default_nettype none

module hvsync_generator (
    input  wire clk,
    input  wire reset,
    output wire hsync,
    output wire vsync,
    output wire display_on,
    output wire [9:0] hpos,
    output wire [9:0] vpos
);

    // 640x480 @ 60Hz timing (25.175 MHz pixel clock)
    parameter H_DISPLAY       = 640;
    parameter H_FRONT         = 16;
    parameter H_SYNC          = 96;
    parameter H_BACK          = 48;
    parameter H_TOTAL         = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // 800

    parameter V_DISPLAY       = 480;
    parameter V_FRONT         = 10;
    parameter V_SYNC          = 2;
    parameter V_BACK          = 33;
    parameter V_TOTAL         = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Horizontal counter
    always @(posedge clk) begin
        if (reset) begin
            h_count <= 10'd0;
        end else if (h_count == H_TOTAL - 1) begin
            h_count <= 10'd0;
        end else begin
            h_count <= h_count + 10'd1;
        end
    end

    // Vertical counter
    always @(posedge clk) begin
        if (reset) begin
            v_count <= 10'd0;
        end else if (h_count == H_TOTAL - 1) begin
            if (v_count == V_TOTAL - 1)
                v_count <= 10'd0;
            else
                v_count <= v_count + 10'd1;
        end
    end

    assign hpos        = h_count;
    assign vpos        = v_count;
    assign hsync       = ~((h_count >= H_DISPLAY + H_FRONT) &&
                           (h_count <  H_DISPLAY + H_FRONT + H_SYNC));
    assign vsync       = ~((v_count >= V_DISPLAY + V_FRONT) &&
                           (v_count <  V_DISPLAY + V_FRONT + V_SYNC));
    assign display_on  = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);

endmodule
