// S3有消抖计数模块：DK3-DK2显示，实验内容“消抖稳定计数”要求
module cnt_s3_with_debounce (
    input  wire        clk,         // 50MHz时钟
    input  wire        rst,         // 异步复位（高有效）
    input  wire        key_s3_rise, // 触发输入：S3消抖后上升沿（来自key_debounce_15ms）
    output reg [7:0]   cnt_out      // 计数输出（8位：高4位=DK3，低4位=DK2，00~99）
);

// -------------------------- 8位计数（00~99循环） --------------------------
// 高4位：十位（0~9），低4位：个位（0~9），逻辑与无消抖一致，仅触发源不同
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;  // 复位清零
    end else if (key_s3_rise == 1'b1) begin  // 消抖后上升沿触发计数
        if (cnt_out[3:0] == 4'h9) begin  // 个位满9，个位清零，十位加1
            cnt_out[3:0] <= 4'h0;
            if (cnt_out[7:4] == 4'h9) begin  // 十位满9，整体清零（00~99循环）
                cnt_out[7:4] <= 4'h0;
            end else begin
                cnt_out[7:4] <= cnt_out[7:4] + 1'b1;
            end
        end else begin  // 个位未满9，个位加1
            cnt_out[3:0] <= cnt_out[3:0] + 1'b1;
        end
    end else begin
        cnt_out <= cnt_out;  // 无触发，保持计数
    end
end

endmodule