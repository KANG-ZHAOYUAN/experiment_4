// ����ܶ�̬����ģ�飺��ѭʵ��ԭ����������ģ�顱�ӿڶ���
//  �Ѿ������˽��������display�ź���Ҫ�������
module led_ctrl_unit (
    input  wire        clk,         // 50MHzʱ��
    input  wire        rst,         // �첽��λ������Ч��
    input  wire        display_en,  // �����ʹ�ܣ�sw0=1=��ʾ��0=ȫ��
    input  wire [31:0] display,     // ����ʾ���ݣ�DK7-DK0��31:28~3:0��
    output reg [7:0]   led_en,      // λѡ������Ч��DK7[7]~DK0[0]��
    output reg [7:0]   led_cx       // ��ѡ������Ч��CA[0]~DP[7]��ʵ��ԭ�����Ŷ��壩
);

// -------------------------- 1. 2msˢ�����ڷ�Ƶ��50MHz��500Hz�� --------------------------
// ��Ƶ���㣺50MHz = 50_000_000 Hz��2ms = 0.002s���������ֵ=50_000_000 * 0.002 = 100_000
reg [16:0]  div_cnt;  // 17λ��������0~131071������100_000,�����Լ�ģ����ڲ��ź�
reg         div_clk;  // ��Ƶ��ʱ�ӣ�500Hz��2ms���ڣ�

always @(posedge clk or posedge rst) begin
    if (rst) begin
        div_cnt <= 17'd0;
        div_clk <= 1'b0;
    end else if (div_cnt == 17'd99_999) begin  // ������99999ʱ��ת��ռ�ձ�50%��
        div_cnt <= 17'd0;
        div_clk <= ~div_clk;
    end else begin
        div_cnt <= div_cnt + 1'b1;
        div_clk <= div_clk;
    end
end

// -------------------------- 2. λѡ��ѯ��������0~7����ӦDK7~DK0�� --------------------------
reg [2:0]  bit_cnt;     // 3λ��������0��DK0��1��DK1������7��DK7��ʵ��ԭ��������DK7-DK0����
                        // bit_cnt �źſ��Ա�ע��ǰ����ɨ��������λ��

always @(posedge div_clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 3'd0;  // ��λ������Ҳ�DK0��ʼɨ��
    end else begin
        if(bit_cnt == 3'd7) begin
            bit_cnt <= 3'd0;
        end else begin
            bit_cnt <= bit_cnt + 3'd1;
        end
    end
    // div_clkÿ��һ�Σ�bit_cnt��1��ѭ��ɨ��0-7
end

// -------------------------- 3. ����������ܶ����ʵ��ԭ��Ҫ�󣺵͵�ƽ��Ч�� --------------------------

// 0ʱ����1ʱ��
reg [7:0]  seg_table [0:9]; // ������ұ�10������0-9�Ķ��룬˳��ΪCA,CB,CC,CD,CE,CF,CG,DP��bit0��bit7��
initial begin
    seg_table[0] = 8'h03;  // 0��CA,CB,CC,CD,CE,CF����
    seg_table[1] = 8'h9F;  // 1����CB,CC����
    seg_table[2] = 8'h25;  // 2��CA,CB,CD,CE,CG����
    seg_table[3] = 8'h0D;  // 3��CA,CB,CC,CD,CG����
    seg_table[4] = 8'h99;  // 4��CB,CC,CF,CG����
    seg_table[5] = 8'h49;  // 5��CA,CC,CD,CF,CG����
    seg_table[6] = 8'h41;  // 6��CA,CC,CD,CE,CF,CG����
    seg_table[7] = 8'h1F;  // 7��CA,CB,CC����
    seg_table[8] = 8'h01;  // 8��ȫ��
    seg_table[9] = 8'h09;  // 9��CA,CB,CC,CD,CF,CG����
end
// -------------------------- 4. ���λѡ���ѡ --------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        led_en <= 8'h00;    
        led_cx <= 8'hFD;    // ֻ��CG
    end else if (display_en == 1'b0) begin
        led_en <= 8'hFF;  
        led_cx <= 8'hFF;  //cx��ȫ����common_cathode
    end else begin
        // λѡ������ǰ��ѯ�������Ϊ0������Ч��������Ϊ1
        case (bit_cnt)
            3'd7: led_en <= 8'h7F;  // DK7��Ч��bit7=0��0111_1111
            3'd6: led_en <= 8'hBF;  // DK6��Ч (bit6=0) 1011_1111
            3'd5: led_en <= 8'hDF;  // DK5��Ч (bit5=0) 1101_1111
            3'd4: led_en <= 8'hEF;  // DK4��Ч (bit4=0) 1110_1111
            3'd3: led_en <= 8'hF7;  // DK3��Ч (bit3=0) 1111_0111
            3'd2: led_en <= 8'hFB;  // DK2��Ч (bit2=0) 1111_1011
            3'd1: led_en <= 8'hFD;  // DK1��Ч (bit1=0) 1111_1101
            3'd0: led_en <= 8'hFE;  // DK0��Ч (bit0=0) 1111_1110
            default: led_en <= 8'hFF; //Ĭ��״̬��ȫ��
        endcase
        // ��ѡ�����ݵ�ǰ��ѯ������ܣ���display��ȡ4λ���ݣ�������

        case (bit_cnt)
            3'd7: led_cx <= seg_table[display[31:28]];  // DK7��display[31:28]
            3'd6: led_cx <= seg_table[display[27:24]];  // DK6��display[27:24]
            3'd5: led_cx <= seg_table[display[23:20]];  // DK5��display[23:20]
            3'd4: led_cx <= seg_table[display[19:16]];  // DK4��display[19:16]
            3'd3: led_cx <= seg_table[display[15:12]];  // DK3��display[15:12]
            3'd2: led_cx <= seg_table[display[11:8]];   // DK2��display[11:8]
            3'd1: led_cx <= seg_table[display[7:4]];    // DK1��display[7:4]
            3'd0: led_cx <= seg_table[display[3:0]];    // DK0��display[3:0]
            default: led_cx <= 8'hFF; //Ĭ��״̬��ȫ��
        endcase
    end
end

endmodule