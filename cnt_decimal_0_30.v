// 十进制0-30计数模块：DK1-DK0显示，实验内容“0.1s间隔循环计数”要求
module cnt_decimal_0_30 (
    input  wire        clk,         
    input  wire        rst,         // 异步复位（高有效）
    input  wire        key_s2,      // 启停控制：S2按键（实验内容要求）
    output reg [7:0]   cnt_out      // 计数输出（8位：高4位=DK1，低4位=DK0，00~30）
);

// -------------------------- 1. 0.1s计数间隔分频（50MHz→10Hz：50_000_000 * 0.1 = 5_000_000） --------------------------
parameter DIV_CNT_MAX = 22'd5_000_000;  // 22位计数器覆盖5000000
reg [21:0] div_cnt;  // 分频计数器
reg        tick;     // 0.1s触发脉冲（1个clk周期高）

always @(posedge clk or posedge rst) begin
    if (rst) begin
        div_cnt <= 22'd0;
        tick    <= 1'b0;
    end else begin
        if (div_cnt == DIV_CNT_MAX - 1'b1) begin  // 计数到4999999时，产生触发脉冲
            div_cnt <= 22'd0;
            tick    <= 1'b1;
        end else begin
            div_cnt <= div_cnt + 1'b1;
            tick    <= 1'b0;
        end
    end
end

// -------------------------- 2. S2按键启停状态切换（上升沿触发） --------------------------
reg run_flag;      // 运行标志：1=计数，0=暂停（复位后=1，实验内容“复位后开始计数”）
reg prev_key_s2;   // 上一周期S2信号

always @(posedge clk or posedge rst) begin
    if (rst) begin
        run_flag    <= 1'b1;  // 复位后默认运行
        prev_key_s2 <= 1'b0;
    end else begin
        prev_key_s2 <= key_s2;
        // S2上升沿切换状态：运行→暂停，暂停→运行
        if (key_s2 & ~prev_key_s2) begin
            run_flag <= ~run_flag;
        end else begin
            run_flag <= run_flag;
        end
    end
end

// -------------------------- 3. 0~30循环计数 --------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_out <= 8'h00;  // 复位清零
    end else if (tick == 1'b1 && run_flag == 1'b1) begin  // 0.1s触发且运行时计数
        if (cnt_out == 8'h30) begin  // 计数到30，清零（实验内容“到30再从0开始”）
            cnt_out <= 8'h00;
        end else begin
            // 个位满9时，个位清零，十位加1；否则个位加1
            if (cnt_out[3:0] == 4'h9) begin
                cnt_out[3:0] <= 4'h0;
                cnt_out[7:4] <= cnt_out[7:4] + 1'b1;
            end else begin
                cnt_out[3:0] <= cnt_out[3:0] + 1'b1;
            end
        end
    end else begin
        cnt_out <= cnt_out;  // 无触发或暂停，保持计数
    end
end

endmodule