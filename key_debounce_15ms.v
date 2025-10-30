//这是用来消抖的信号，模块的接口定义如下：

//模块名称：key_debounce_15ms
//功能描述：对机械按键输入信号进行15ms延时消抖处理，输出稳定的按键信号及其上升沿/下降沿脉冲
//输入信号：
//  clk      ：系统固定时钟，频率100MHz
//  rst      ：异步复位信号（高有效，对应实验中S1按键复位），复位信号不需要进行消抖处理
//  key_in   ：原始按键输入（对应实验中S3按键，含机械抖动）
//输出信号：
//  key_out  ：15ms延时消抖后的稳定按键输出
//  rise_pulse：消抖后上升沿脉冲（1个clk周期高电平，触发S3计数）
//  fall_pulse：消抖后下降沿脉冲（1个clk周期高电平，备用）

module key_debounce_15ms (
    input  wire        clk,         // 系统固定时钟：100MHz
    input  wire        rst,         // 异步复位信号（高有效，对应实验中S1按键复位），复位信号不需要进行消抖处理
    input  wire        key_in,      // 原始按键输入（对应实验中S3按键，含机械抖动）
    output reg         key_out,     // 15ms延时消抖后的稳定按键输出
    output reg         rise_pulse,  // 消抖后上升沿脉冲（1个clk周期高电平，触发S3计数）
    output reg         fall_pulse   // 消抖后下降沿脉冲（1个clk周期高电平，备用）
    //rise_pulse是一个脉冲信号，只会在一个时钟周期内为高电平，用于触发S3按键的计数操作。
    //fall_pulse也是一个脉冲信号，只会在一个时钟周期内为高电平，通常用于检测S3按键的松开动作，
    //虽然在本实验中，fall_pulse并没有没有直接使用，但它可以作为备用信号，以备将来可能的功能扩展。
);


parameter DEBOUNCE_CNT_MAX = 21'd1_500_000;
//2^21-1 = 2,097,151，足够覆盖1,500,000  
// 19位计数器覆盖0~750000（满足15ms计数）
//计算方法：15ms / 10ns = 1,500,000个时钟周期（100MHz时钟周期为10ns）

//内部信号定义
reg [2:0]  sync_key;         // 按键输入两级同步寄存器（消除亚稳态，实验时序稳定性要求）
reg [20:0] debounce_cnt;     // 15ms消抖计数器（21位，匹配DEBOUNCE_CNT_MAX）
reg        prev_key_out;     // 上一周期稳定输出（用于边沿检测）

// -------------------------- 步骤1：按键输入同步处理 --------------------------
// 逻辑：使用三级寄存器对按键输入信号进行同步，
always @(posedge clk or posedge rst) begin
    if (rst) begin
        sync_key[0] <= 1'b0;
        sync_key[1] <= 1'b0;
        sync_key[2] <= 1'b0;
    end else begin
        sync_key[0] <= key_in;      // 第一级同步：采集S3原始信号
        sync_key[1] <= sync_key[0]; // 第二级同步：稳定同步后信号，消除亚稳态
        sync_key[2] <= sync_key[1]; // 第三级寄存器：备用，可用于进一步稳定或调试观察
    end
end
//这实在是太安全了！使用两级寄存器同步按键信号，信号会慢两个时钟周期到达后续逻辑


// -------------------------- 步骤2：15ms消抖计数器 --------------------------
// 逻辑：当同步后按键（sync_key[1]）与当前稳定输出（key_out）不一致时，启动15ms计数；
// 计数满750000（15ms）后停止计数，确认按键进入稳态；状态一致时计数器清零。
always @(posedge clk or posedge rst) begin
    if (rst) begin
        debounce_cnt <= 21'd0;
    end else if (sync_key[2] != key_out) begin  // 检测到S3状态变化（含抖动）
        if (debounce_cnt < DEBOUNCE_CNT_MAX) begin
            debounce_cnt <= debounce_cnt + 1'b1; // 计数器递增，累计15ms
        end else begin
            debounce_cnt <= debounce_cnt;        // 计数满15ms，保持数值等待稳态确认
        end
    end else begin                              // S3状态无变化（稳定或抖动结束）
        debounce_cnt <= 21'd0;                  // 计数器清零，重新等待状态变化
        //只要在抖动，就会一直清零
    end
end

// -------------------------- 步骤3：15ms延时后更新稳定输出 --------------------------
// 逻辑：计数器满750000（15ms）时，确认S3状态稳定，将同步后信号赋值给key_out
always @(posedge clk or posedge rst) begin
    if (rst) begin
        key_out <= 1'b0; 
    end else if (debounce_cnt == DEBOUNCE_CNT_MAX) begin
        key_out <= sync_key[2];  // 15ms延时后确认稳态，更新稳定输出
    end else begin
        key_out <= key_out;      // 未达到15ms，保持原稳定输出，过滤抖动
    end
end

// -------------------------- 步骤4：生成上升沿/下降沿脉冲 --------------------------
// 逻辑：对比当前稳定输出（key_out）与上一周期输出（prev_key_out），检测S3稳定边沿
always @(posedge clk or posedge rst) begin
    if (rst) begin
        prev_key_out <= 1'b0;
        rise_pulse   <= 1'b0;
        fall_pulse   <= 1'b0;
        //特别注意fall_pulse，他总是保持0，在"输入信号下降"时，fall_pulse其实是上升沿
    end else begin
        prev_key_out <= key_out;  // 存储当前稳定输出，用于下一周期边沿对比
        // 上升沿：S3从稳定低→稳定高（对应实验中S3“按下”动作，触发计数）
        rise_pulse <= key_out & ~prev_key_out;
        // 下降沿：S3从稳定高→稳定低（对应实验中S3“松开”动作，备用）
        fall_pulse <= ~key_out & prev_key_out;
    end
end

endmodule