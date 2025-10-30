// S3����������ģ�飺DK3-DK2��ʾ��ʵ�����ݡ������ȶ�������Ҫ��
module cnt_s3_with_debounce (
    input  wire        clk,         // 50MHzʱ��
    input  wire        rst,         // �첽��λ������Ч��
    input  wire        key_s3_rise, // �������룺S3�����������أ�����key_debounce_15ms��
    output reg [7:0]   cnt_out      // ���������8λ����4λ=DK3����4λ=DK2��00~99��
);

// -------------------------- 8λ������00~99ѭ���� --------------------------
// ��4λ��ʮλ��0~9������4λ����λ��0~9�����߼���������һ�£�������Դ��ͬ
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;  // ��λ����
    end else if (key_s3_rise == 1'b1) begin  // �����������ش�������
        if (cnt_out[3:0] == 4'h9) begin  // ��λ��9����λ���㣬ʮλ��1
            cnt_out[3:0] <= 4'h0;
            if (cnt_out[7:4] == 4'h9) begin  // ʮλ��9���������㣨00~99ѭ����
                cnt_out[7:4] <= 4'h0;
            end else begin
                cnt_out[7:4] <= cnt_out[7:4] + 1'b1;
            end
        end else begin  // ��λδ��9����λ��1
            cnt_out[3:0] <= cnt_out[3:0] + 1'b1;
        end
    end else begin
        cnt_out <= cnt_out;  // �޴��������ּ���
    end
end

endmodule