// 顶层模块：整合所有子模块，实现实验4完整功能
module top_led_controller (
    input  wire        clk,         // 开发板固定时钟：100MHz（实验原理默认）
    input  wire        rst,         // 异步复位：S1按键（高有效，实验内容要求）
    input  wire        key_s2,      // 十进制计数启停：S2按键（实验内容要求）
    input  wire        key_s3,      // 计数触发：S3按键（实验内容要求）
    input  wire        sw0,         // 数码管整体使能：拨码开关（上拨=1=显示，实验内容要求）
    output reg [7:0]   led_en,      // 数码管位选（低有效，DK7-DK0，实验原理要求）
    output reg [7:0]   led_cx       // 数码管段选（低有效，CA~DP，实验原理要求），7段数码管，加上小数点
);

// -------------------------- 1. 定义学号后两位 --------------------------
// 示例：学号后两位为“23”，则STUDENT_ID_TEN=4'h2（DK7），STUDENT_ID_ONE=4'h3（DK6）
parameter STUDENT_ID_TEN = 4'h5;  
parameter STUDENT_ID_ONE = 4'h0;  

// -------------------------- 2. 内部信号定义（子模块间连接） --------------------------
wire [7:0]  cnt_s3_no_deb_out;    // S3无消抖计数结果（DK5-DK4，来自cnt_s3_no_debounce）
wire [7:0]  cnt_s3_deb_out;       // S3有消抖计数结果（DK3-DK2，来自cnt_s3_with_debounce）
wire [7:0]  cnt_dec_0_30_out;     // 十进制0-30计数结果（DK1-DK0，来自cnt_decimal_0_30）
wire        key_s3_deb_rise;      // S3消抖后上升沿（来自key_debounce_15ms，触发有消抖计数）
wire [31:0] display;              // 待显示数据（传给led_ctrl_unit）,每个数码管4位BCD码，BCD最后可以直接连接到段码表，变成十进制数字
wire        key_s2_deb_out;       // S2消抖后稳定输出（来自key_debounce_15ms，控制十进制计数启停）

// -------------------------- 3. 整合显示数据（display[31:0]对应DK7-DK0） --------------------------
// 位宽分配：DK7[31:28]、DK6[27:24]、DK5[23:20]、DK4[19:16]、DK3[15:12]、DK2[11:8]、DK1[7:4]、DK0[3:0]
assign display = {
    STUDENT_ID_TEN,  // DK7：学号十位
    STUDENT_ID_ONE,  // DK6：学号个位
    cnt_s3_no_deb_out[7:4], cnt_s3_no_deb_out[3:0],  // DK5-DK4：S3无消抖计数（高4位=DK5，低4位=DK4）
    cnt_s3_deb_out[7:4], cnt_s3_deb_out[3:0],        // DK3-DK2：S3有消抖计数（高4位=DK3，低4位=DK2）
    cnt_dec_0_30_out[7:4], cnt_dec_0_30_out[3:0]     // DK1-DK0：十进制0-30计数（高4位=DK1，低4位=DK0）
};

// -------------------------- 4. 例化子模块 --------------------------
// 4.1 数码管动态驱动模块
led_ctrl_unit u_led_ctrl_unit (
    .clk(clk),
    .rst(rst),
    .display_en(sw0),   // SW0控制数码管使能（实验内容要求）
    .display(display),  // 待显示数据（32位，DK7-DK0）
    .led_en(led_en),    // 数码管位选
    .led_cx(led_cx)     // 数码管段选
);

// 4.2.1 S3按键15ms消抖模块
key_debounce_15ms u_key_debounce_15ms_for_key_3 (
    .clk(clk),
    .rst(rst),
    .key_in(key_s3),
    .key_out(),                    // 稳定输出未使用，仅用上升沿
    .rise_pulse(key_s3_deb_rise),  // 消抖后上升沿（触发有消抖计数）
    .fall_pulse()      // 下降沿未使用
);

// 4.2.2 S2按键15ms消抖模块
key_debounce_15ms u_key_debounce_15ms_for_key_2 (
    .clk(clk),
    .rst(rst),
    .key_in(key_s2),
    .key_out(key_s2_deb_out),      // 消抖后稳定输出
    .rise_pulse(),                 // 上升沿未使用
    .fall_pulse()                  // 下降沿未使用
);

// 4.3 S3无消抖计数模块（DK5-DK4）
cnt_s3_no_debounce u_cnt_s3_no_debounce (
    .clk(clk),
    .rst(rst),
    .key_s3(key_s3),                // 原始S3信号（无消抖）
    .cnt_out(cnt_s3_no_deb_out)     //作为数据的输出
);

// 4.4 S3有消抖计数模块（DK3-DK2）
cnt_s3_with_debounce u_cnt_s3_with_debounce (
    .clk(clk),
    .rst(rst),
    .key_s3_rise(key_s3_deb_rise),  // 消抖后上升沿
    .cnt_out(cnt_s3_deb_out)
);

// 4.5 十进制0-30计数模块（DK1-DK0）
cnt_decimal_0_30 u_cnt_decimal_0_30 (
    .clk(clk),
    .rst(rst),
    .key_s2(key_s2_deb_out),   // S2启停控制（实验内容要求）
    .cnt_out(cnt_dec_0_30_out)
);

endmodule