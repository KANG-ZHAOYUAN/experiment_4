// S3����������ģ�飺DK5-DK4��ʾ��ʵ�����ݡ�������������Ҫ��
module cnt_s3_no_debounce (
    input  wire        clk,         // 50MHzʱ��
    input  wire        rst,         // �첽��λ������Ч��
    input  wire        key_s3,      // ԭʼ���룺S3��������������
    output reg [7:0]   cnt_out      // ���������8λ����4λ=DK5����4λ=DK4��00~99��
);

// -------------------------- 1. ���S3�����أ����������ס������� --------------------------
reg prev_key_s3;  // ��һ����S3�ź�

always @(posedge clk or posedge rst) begin
    if (rst) begin
        prev_key_s3 <= 1'b0;
    end else begin
        prev_key_s3 <= key_s3;  // �洢��һ�����ź�
    end
end

wire key_s3_rise;  // S3�����أ���ǰ1����һ����0��
assign key_s3_rise = key_s3 & ~prev_key_s3;// �����ؼ��

// -------------------------- 2. 8λ������00~99ѭ���� --------------------------
// ��4λ��ʮλ��0~9������4λ����λ��0~9��
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;                       // ��λ����,count_outֱ�Ӱ���ʮ���Ƶ��߼������м���
    end else if (key_s3_rise == 1'b1) begin     // �����ش�������
        if (cnt_out[3:0] == 4'h9) begin         // ��λ��9����λ���㣬ʮλ��1
            cnt_out[3:0] <= 4'h0;
            if (cnt_out[7:4] == 4'h9) begin     // ʮλ��9���������㣨00~99ѭ��������Ȼ���ڸ�λ��9������£�ʮλ�ſ�����9������
                cnt_out[7:4] <= 4'h0;
            end else begin
                cnt_out[7:4] <= cnt_out[7:4] + 4'b1; //��λ����
            end
        end else begin  // ��λδ��9����λ��1
            cnt_out[3:0] <= cnt_out[3:0] + 4'b1; 
        end

    end else begin
        cnt_out <= cnt_out;  // �޴��������ּ���
    end
end

endmodule