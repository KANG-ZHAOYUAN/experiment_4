// S3无消抖计数模块：DK5-DK4显示，实验内容“无消抖计数”要求
module cnt_s3_no_debounce (
    input  wire        clk,         // 50MHz时钟
    input  wire        rst,         // 异步复位（高有效）
    input  wire        key_s3,      // 原始输入：S3按键（无消抖）
    output reg [7:0]   cnt_out      // 计数输出（8位：高4位=DK5，低4位=DK4，00~99）
);

// -------------------------- 1. 检测S3上升沿（避免持续按住多计数） --------------------------
reg prev_key_s3;  // 上一周期S3信号

always @(posedge clk or posedge rst) begin
    if (rst) begin
        prev_key_s3 <= 1'b0;
    end else begin
        prev_key_s3 <= key_s3;  // 存储上一周期信号
    end
end

wire key_s3_rise;  // S3上升沿（当前1，上一周期0）
assign key_s3_rise = key_s3 & ~prev_key_s3;// 上升沿检测

// -------------------------- 2. 8位计数（00~99循环） --------------------------
// 高4位：十位（0~9），低4位：个位（0~9）
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;                       // 复位清零,count_out直接按照十进制的逻辑来进行计数
    end else if (key_s3_rise == 1'b1) begin     // 上升沿触发计数
        if (cnt_out[3:0] == 4'h9) begin         // 个位满9，个位清零，十位加1
            cnt_out[3:0] <= 4'h0;
            if (cnt_out[7:4] == 4'h9) begin     // 十位满9，整体清零（00~99循环），显然，在个位满9的情况下，十位才可能满9会清零
                cnt_out[7:4] <= 4'h0;
            end else begin
                cnt_out[7:4] <= cnt_out[7:4] + 4'b1; //进位操作
            end
        end else begin  // 个位未满9，个位加1
            cnt_out[3:0] <= cnt_out[3:0] + 4'b1; 
        end

    end else begin
        cnt_out <= cnt_out;  // 无触发，保持计数
    end
end

endmodule