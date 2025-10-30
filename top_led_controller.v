// ����ģ�飺����������ģ�飬ʵ��ʵ��4��������
module top_led_controller (
    input  wire        clk,         // ������̶�ʱ�ӣ�100MHz��ʵ��ԭ��Ĭ�ϣ�
    input  wire        rst,         // �첽��λ��S1����������Ч��ʵ������Ҫ��
    input  wire        key_s2,      // ʮ���Ƽ�����ͣ��S2������ʵ������Ҫ��
    input  wire        key_s3,      // ����������S3������ʵ������Ҫ��
    input  wire        sw0,         // ���������ʹ�ܣ����뿪�أ��ϲ�=1=��ʾ��ʵ������Ҫ��
    output reg [7:0]   led_en,      // �����λѡ������Ч��DK7-DK0��ʵ��ԭ��Ҫ��
    output reg [7:0]   led_cx       // ����ܶ�ѡ������Ч��CA~DP��ʵ��ԭ��Ҫ�󣩣�7������ܣ�����С����
);

// -------------------------- 1. ����ѧ�ź���λ --------------------------
// ʾ����ѧ�ź���λΪ��23������STUDENT_ID_TEN=4'h2��DK7����STUDENT_ID_ONE=4'h3��DK6��
parameter STUDENT_ID_TEN = 4'h5;  
parameter STUDENT_ID_ONE = 4'h0;  

// -------------------------- 2. �ڲ��źŶ��壨��ģ������ӣ� --------------------------
wire [7:0]  cnt_s3_no_deb_out;    // S3���������������DK5-DK4������cnt_s3_no_debounce��
wire [7:0]  cnt_s3_deb_out;       // S3���������������DK3-DK2������cnt_s3_with_debounce��
wire [7:0]  cnt_dec_0_30_out;     // ʮ����0-30���������DK1-DK0������cnt_decimal_0_30��
wire        key_s3_deb_rise;      // S3�����������أ�����key_debounce_15ms������������������
wire [31:0] display;              // ����ʾ���ݣ�����led_ctrl_unit��,ÿ�������4λBCD�룬BCD������ֱ�����ӵ���������ʮ��������
wire        key_s2_deb_out;       // S2�������ȶ����������key_debounce_15ms������ʮ���Ƽ�����ͣ��

// -------------------------- 3. ������ʾ���ݣ�display[31:0]��ӦDK7-DK0�� --------------------------
// λ����䣺DK7[31:28]��DK6[27:24]��DK5[23:20]��DK4[19:16]��DK3[15:12]��DK2[11:8]��DK1[7:4]��DK0[3:0]
assign display = {
    STUDENT_ID_TEN,  // DK7��ѧ��ʮλ
    STUDENT_ID_ONE,  // DK6��ѧ�Ÿ�λ
    cnt_s3_no_deb_out[7:4], cnt_s3_no_deb_out[3:0],  // DK5-DK4��S3��������������4λ=DK5����4λ=DK4��
    cnt_s3_deb_out[7:4], cnt_s3_deb_out[3:0],        // DK3-DK2��S3��������������4λ=DK3����4λ=DK2��
    cnt_dec_0_30_out[7:4], cnt_dec_0_30_out[3:0]     // DK1-DK0��ʮ����0-30��������4λ=DK1����4λ=DK0��
};

// -------------------------- 4. ������ģ�� --------------------------
// 4.1 ����ܶ�̬����ģ��
led_ctrl_unit u_led_ctrl_unit (
    .clk(clk),
    .rst(rst),
    .display_en(sw0),   // SW0���������ʹ�ܣ�ʵ������Ҫ��
    .display(display),  // ����ʾ���ݣ�32λ��DK7-DK0��
    .led_en(led_en),    // �����λѡ
    .led_cx(led_cx)     // ����ܶ�ѡ
);

// 4.2.1 S3����15ms����ģ��
key_debounce_15ms u_key_debounce_15ms_for_key_3 (
    .clk(clk),
    .rst(rst),
    .key_in(key_s3),
    .key_out(),                    // �ȶ����δʹ�ã�����������
    .rise_pulse(key_s3_deb_rise),  // �����������أ�����������������
    .fall_pulse()      // �½���δʹ��
);

// 4.2.2 S2����15ms����ģ��
key_debounce_15ms u_key_debounce_15ms_for_key_2 (
    .clk(clk),
    .rst(rst),
    .key_in(key_s2),
    .key_out(key_s2_deb_out),      // �������ȶ����
    .rise_pulse(),                 // ������δʹ��
    .fall_pulse()                  // �½���δʹ��
);

// 4.3 S3����������ģ�飨DK5-DK4��
cnt_s3_no_debounce u_cnt_s3_no_debounce (
    .clk(clk),
    .rst(rst),
    .key_s3(key_s3),                // ԭʼS3�źţ���������
    .cnt_out(cnt_s3_no_deb_out)     //��Ϊ���ݵ����
);

// 4.4 S3����������ģ�飨DK3-DK2��
cnt_s3_with_debounce u_cnt_s3_with_debounce (
    .clk(clk),
    .rst(rst),
    .key_s3_rise(key_s3_deb_rise),  // ������������
    .cnt_out(cnt_s3_deb_out)
);

// 4.5 ʮ����0-30����ģ�飨DK1-DK0��
cnt_decimal_0_30 u_cnt_decimal_0_30 (
    .clk(clk),
    .rst(rst),
    .key_s2(key_s2_deb_out),   // S2��ͣ���ƣ�ʵ������Ҫ��
    .cnt_out(cnt_dec_0_30_out)
);

endmodule