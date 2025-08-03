`timescale 1ns / 1ps // ??n v? th?i gian m� ph?ng l� 1ns, ?? ch�nh x�c l� 1ps

module tb_brightness_adjust_rgb;

    // -------------------------------------------------------------------------
    // Khai b�o t�n hi?u cho DUT (Device Under Test)
    // C�c t�n hi?u n�y s? k?t n?i v?i c�c c?ng c?a module brightness_adjust_rgb
    // ??u ra c?a testbench l� ??u v�o c?a DUT, v� ng??c l?i.
    // -------------------------------------------------------------------------

    // C�c t�n hi?u Clock v� Reset
    reg clk;
    reg rst;

    // AXI4-Stream Slave Interface (??u ra t? Testbench -> ??u v�o DUT)
    reg  [23:0] s_axis_tdata;
    reg         s_axis_tvalid;
    wire        s_axis_tready; // ?�y l� t�n hi?u input cho testbench, output t? DUT
    reg         s_axis_tlast;

    // AXI4-Stream Master Interface (??u v�o Testbench <- ??u ra DUT)
    wire [23:0] m_axis_tdata;
    wire        m_axis_tvalid;
    reg         m_axis_tready; // ?�y l� t�n hi?u output t? testbench, input cho DUT
    wire        m_axis_tlast;

    // Tham s? cho DUT (ph?i kh?p v?i tham s? c?a module DUT)
    parameter integer TEST_SCALE_FACTOR = 128; // V� d?: nh�n 2 (128 = 2 * 64)
    // parameter integer TEST_SCALE_FACTOR = 32; // V� d?: gi?m 50% (32 = 0.5 * 64)
    // parameter integer TEST_SCALE_FACTOR = 77; // V� d?: t?ng 20% (77 = 1.2 * 64)


    // -------------------------------------------------------------------------
    // Kh?i t?o DUT (Device Under Test)
    // K?t n?i c�c t�n hi?u c?a testbench v?i c�c c?ng c?a DUT
    // -------------------------------------------------------------------------
    brightness_adjust_rgb #(
        .scale_factor(TEST_SCALE_FACTOR)
    ) dut (
        .clk(clk),
        .rst(rst),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // -------------------------------------------------------------------------
    // T?o xung Clock
    // -------------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Chu k? clock l� 10ns (t?n s? 100MHz)
    end

    // -------------------------------------------------------------------------
    // T?o k?ch b?n ki?m th? (Test Scenario)
    // -------------------------------------------------------------------------
    initial begin
        // 1. Kh?i t?o v� Reset h? th?ng
        rst = 1; // K�ch ho?t reset
        s_axis_tvalid = 0; // Kh�ng g?i d? li?u
        s_axis_tdata = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1; // Lu�n s?n s�ng nh?n d? li?u ??u ra t? DUT (?? DUT kh�ng b? t?c ngh?n)

        #20;      // ??i m?t ch�t sau reset
        rst = 0;  // Nh? reset

        // 2. G?i m?t s? pixel m?u qua AXI4-Stream
        // D? li?u m?u: R(255), G(128), B(64)
        // L?u �: DUT c� th? c� ?? tr? (latency) do pipeline v� m?ch nh�n
        // n�n ??u ra s? xu?t hi?n sau v�i chu k? clock.

        $display("--------------------------------------------------");
        $display("Bat dau gui du lieu pixel mau...");
        $display("He so dieu chinh: %0d (tuong duong chia 64)", TEST_SCALE_FACTOR);
        $display("--------------------------------------------------");

        // Pixel 1: M�u ?? t??i (FF0000)
        @(posedge clk);
        s_axis_tdata  = 24'hFF0000; // R=255, G=0, B=0
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        wait(s_axis_tready); // ??i DUT s?n s�ng nh?n
        $display("[%0t] Gui Pixel 1: s_axis_tdata = 0x%h, s_axis_tlast = %0d", $time, s_axis_tdata, s_axis_tlast);

        // Pixel 2: M�u xanh l� c�y (00FF00)
        @(posedge clk);
        s_axis_tdata  = 24'h00FF00; // R=0, G=255, B=0
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        wait(s_axis_tready);
        $display("[%0t] Gui Pixel 2: s_axis_tdata = 0x%h, s_axis_tlast = %0d", $time, s_axis_tdata, s_axis_tlast);

        // Pixel 3: M�u xanh d??ng (0000FF)
        @(posedge clk);
        s_axis_tdata  = 24'h0000FF; // R=0, G=0, B=255
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        wait(s_axis_tready);
        $display("[%0t] Gui Pixel 3: s_axis_tdata = 0x%h, s_axis_tlast = %0d", $time, s_axis_tdata, s_axis_tlast);

        // Pixel 4: M�u x�m trung b�nh (808080) - s? ???c l�m s�ng/t?i
        @(posedge clk);
        s_axis_tdata  = 24'h808080; // R=128, G=128, B=128
        s_axis_tvalid = 1;
        s_axis_tlast  = 0;
        wait(s_axis_tready);
        $display("[%0t] Gui Pixel 4: s_axis_tdata = 0x%h, s_axis_tlast = %0d", $time, s_axis_tdata, s_axis_tlast);

        // Pixel 5: M�u tr?ng (FFFFFF) - cu?i khung (tlast=1)
        @(posedge clk);
        s_axis_tdata  = 24'hFFFFFF; // R=255, G=255, B=255
        s_axis_tvalid = 1;
        s_axis_tlast  = 1; // ?�nh d?u ?�y l� pixel cu?i c�ng c?a khung
        wait(s_axis_tready);
        $display("[%0t] Gui Pixel 5 (LAST): s_axis_tdata = 0x%h, s_axis_tlast = %0d", $time, s_axis_tdata, s_axis_tlast);

        // Ng?ng g?i d? li?u sau khi g?i xong
        @(posedge clk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        $display("[%0t] Ngung gui du lieu.", $time);

        // 3. ??i DUT x? l� v� ??y h?t d? li?u ra
        // Ch? th�m m?t th?i gian ?? DUT ho�n th�nh x? l� v� ??y t?t c? c�c pixel ra
        // ?? tr? s? b?ng s? pipeline stages + latency c?a b? nh�n.
        // Trong tr??ng h?p n�y, c� th? kho?ng 3-5 chu k? clock.
        #100; // ??i ?? l�u ?? to�n b? d? li?u ra
        $display("--------------------------------------------------");
        $display("Ket thuc mo phong.");
        $display("--------------------------------------------------");
        $finish; // K?t th�c m� ph?ng
    end

    // -------------------------------------------------------------------------
    // Ki?m tra ??u ra v� hi?n th? (Monitoring Output)
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (m_axis_tvalid && m_axis_tready) begin // N?u DUT g?i d? li?u h?p l? v� Testbench s?n s�ng nh?n
            // T�nh to�n gi� tr? d? ki?n (expected value)
            // (pixel_in * TEST_SCALE_FACTOR) / 64
            // Do c� pipeline, gi� tr? pixel_in_pipe s? t??ng ?ng v?i ??u v�o c?a v�i chu k? tr??c
            // ?? ki?m tra ch�nh x�c, b?n c?n theo d�i pixel_in_pipe ho?c bi?t r� latency c?a DUT.
            // ? ?�y, ch�ng ta s? in gi� tr? m_axis_tdata v� m_axis_tlast.
            $display("[%0t] Nhan Pixel OUT: m_axis_tdata = 0x%h (R=%0d, G=%0d, B=%0d), m_axis_tlast = %0d",
                     $time, m_axis_tdata, m_axis_tdata[23:16], m_axis_tdata[15:8], m_axis_tdata[7:0], m_axis_tlast);

            // Ki?m tra t�n hi?u TLAST
            if (m_axis_tlast) begin
                $display("       -> TLAST duoc truyen dung tai thoi diem: %0t", $time);
            end

            // V� d? ki?m tra m?t gi� tr? c? th? (?? bi?t latency, b?n c?n quan s�t waveform)
            // if ($time == X ns && m_axis_tdata == expected_value) begin
            //    $display("Test PASSED for specific pixel at time X");
            // end else if ($time == X ns) begin
            //    $display("Test FAILED for specific pixel at time X. Expected Y, Got Z");
            // end
        end
    end

endmodule