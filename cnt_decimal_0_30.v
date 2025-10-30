// ʮ����0-30����ģ�飺DK1-DK0��ʾ��ʵ�����ݡ�0.1s���ѭ��������Ҫ��
module cnt_decimal_0_30 (
    input  wire        clk,         
    input  wire        rst,         // �첽��λ������Ч��
    input  wire        key_s2,      // ��ͣ���ƣ�S2������ʵ������Ҫ��
    output reg [7:0]   cnt_out      // ���������8λ����4λ=DK1����4λ=DK0��00~30��
);

// -------------------------- 1. 0.1s���������Ƶ��50MHz��10Hz��50_000_000 * 0.1 = 5_000_000�� --------------------------
parameter DIV_CNT_MAX = 22'd5_000_000;  // 22λ����������5000000
reg [21:0] div_cnt;  // ��Ƶ������
reg        tick;     // 0.1s�������壨1��clk���ڸߣ�

always @(posedge clk or posedge rst) begin
    if (rst) begin
        div_cnt <= 22'd0;
        tick    <= 1'b0;
    end else begin
        if (div_cnt == DIV_CNT_MAX - 1'b1) begin  // ������4999999ʱ��������������
            div_cnt <= 22'd0;
            tick    <= 1'b1;
        end else begin
            div_cnt <= div_cnt + 1'b1;
            tick    <= 1'b0;
        end
    end
end

// -------------------------- 2. S2������ͣ״̬�л��������ش����� --------------------------
reg run_flag;      // ���б�־��1=������0=��ͣ����λ��=1��ʵ�����ݡ���λ��ʼ��������
reg prev_key_s2;   // ��һ����S2�ź�

always @(posedge clk or posedge rst) begin
    if (rst) begin
        run_flag    <= 1'b1;  // ��λ��Ĭ������
        prev_key_s2 <= 1'b0;
    end else begin
        prev_key_s2 <= key_s2;
        // S2�������л�״̬�����С���ͣ����ͣ������
        if (key_s2 & ~prev_key_s2) begin
            run_flag <= ~run_flag;
        end else begin
            run_flag <= run_flag;
        end
    end
end

// -------------------------- 3. 0~30ѭ������ --------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;  // ��λ����
    end else if (tick == 1'b1 && run_flag == 1'b1) begin  // 0.1s����������ʱ����
        if (cnt_out == 8'h30) begin  // ������30�����㣨ʵ�����ݡ���30�ٴ�0��ʼ����
            cnt_out <= 8'h00;
        end else begin
            // ��λ��9ʱ����λ���㣬ʮλ��1�������λ��1
            if (cnt_out[3:0] == 4'h9) begin
                cnt_out[3:0] <= 4'h0;
                cnt_out[7:4] <= cnt_out[7:4] + 1'b1;
            end else begin
                cnt_out[3:0] <= cnt_out[3:0] + 1'b1;
            end
        end
    end else begin
        cnt_out <= cnt_out;  // �޴�������ͣ�����ּ���
    end
end

endmodule