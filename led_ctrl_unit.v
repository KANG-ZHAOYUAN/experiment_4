// 数码管动态驱动模块：遵循实验原理“核心驱动模块”接口定义
//  已经进行了解读，其中display信号需要计算后传入
module led_ctrl_unit (
    input  wire        clk,         // 50MHz时钟
    input  wire        rst,         // 异步复位（高有效）
    input  wire        display_en,  // 数码管使能（sw0=1=显示，0=全灭）
    input  wire [31:0] display,     // 待显示数据（DK7-DK0：31:28~3:0）
    output reg [7:0]   led_en,      // 位选（低有效，DK7[7]~DK0[0]）
    output reg [7:0]   led_cx       // 段选（低有效，CA[0]~DP[7]，实验原理引脚定义）
);

// -------------------------- 1. 2ms刷新周期分频（50MHz→500Hz） --------------------------
// 分频计算：50MHz = 50_000_000 Hz，2ms = 0.002s，计数最大值=50_000_000 * 0.002 = 100_000
reg [16:0]  div_cnt;  // 17位计数器：0~131071，覆盖100_000,这是自己模块的内部信号
reg         div_clk;  // 分频后时钟（500Hz，2ms周期）

always @(posedge clk or posedge rst) begin
    if (rst) begin
        div_cnt <= 17'd0;
        div_clk <= 1'b0;
    end else if (div_cnt == 17'd99_999) begin  // 计数到99999时翻转（占空比50%）
        div_cnt <= 17'd0;
        div_clk <= ~div_clk;
    end else begin
        div_cnt <= div_cnt + 1'b1;
        div_clk <= div_clk;
    end
end

// -------------------------- 2. 位选轮询计数器（0~7：对应DK7~DK0） --------------------------
reg [2:0]  bit_cnt;     // 3位计数器：0→DK0，1→DK1，…，7→DK7（实验原理“从左到右DK7-DK0”）
                        // bit_cnt 信号可以标注当前正在扫描的数码管位置

always @(posedge div_clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 3'd0;  // 复位后从最右侧DK0开始扫描
    end else begin
        if(bit_cnt == 3'd7) begin
            bit_cnt <= 3'd0;
        end else begin
            bit_cnt <= bit_cnt + 3'd1;
        end
    end
    // div_clk每来一次，bit_cnt加1，循环扫描0-7
end

// -------------------------- 3. 共阳极数码管段码表（实验原理要求：低电平有效） --------------------------

// 0时亮，1时灭
reg [7:0]  seg_table [0:9]; // 段码查找表，10个数字0-9的段码，顺序为CA,CB,CC,CD,CE,CF,CG,DP（bit0到bit7）
initial begin
    seg_table[0] = 8'h03;  // 0：CA,CB,CC,CD,CE,CF点亮
    seg_table[1] = 8'h9F;  // 1：仅CB,CC点亮
    seg_table[2] = 8'h25;  // 2：CA,CB,CD,CE,CG点亮
    seg_table[3] = 8'h0D;  // 3：CA,CB,CC,CD,CG点亮
    seg_table[4] = 8'h99;  // 4：CB,CC,CF,CG点亮
    seg_table[5] = 8'h49;  // 5：CA,CC,CD,CF,CG点亮
    seg_table[6] = 8'h41;  // 6：CA,CC,CD,CE,CF,CG点亮
    seg_table[7] = 8'h1F;  // 7：CA,CB,CC点亮
    seg_table[8] = 8'h01;  // 8：全亮
    seg_table[9] = 8'h09;  // 9：CA,CB,CC,CD,CF,CG点亮
end
// -------------------------- 4. 输出位选与段选 --------------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        led_en <= 8'h00;    
        led_cx <= 8'hFD;    // 只亮CG
    end else if (display_en == 1'b0) begin
        led_en <= 8'hFF;  
        led_cx <= 8'hFF;  //cx的全称是common_cathode
    end else begin
        // 位选：仅当前轮询的数码管为0（低有效），其余为1
        case (bit_cnt)
            3'd7: led_en <= 8'h7F;  // DK7有效（bit7=0）0111_1111
            3'd6: led_en <= 8'hBF;  // DK6有效 (bit6=0) 1011_1111
            3'd5: led_en <= 8'hDF;  // DK5有效 (bit5=0) 1101_1111
            3'd4: led_en <= 8'hEF;  // DK4有效 (bit4=0) 1110_1111
            3'd3: led_en <= 8'hF7;  // DK3有效 (bit3=0) 1111_0111
            3'd2: led_en <= 8'hFB;  // DK2有效 (bit2=0) 1111_1011
            3'd1: led_en <= 8'hFD;  // DK1有效 (bit1=0) 1111_1101
            3'd0: led_en <= 8'hFE;  // DK0有效 (bit0=0) 1111_1110
            default: led_en <= 8'hFF; //默认状态是全灭
        endcase
        // 段选：根据当前轮询的数码管，从display中取4位数据，查段码表

        case (bit_cnt)
            3'd7: led_cx <= seg_table[display[31:28]];  // DK7：display[31:28]
            3'd6: led_cx <= seg_table[display[27:24]];  // DK6：display[27:24]
            3'd5: led_cx <= seg_table[display[23:20]];  // DK5：display[23:20]
            3'd4: led_cx <= seg_table[display[19:16]];  // DK4：display[19:16]
            3'd3: led_cx <= seg_table[display[15:12]];  // DK3：display[15:12]
            3'd2: led_cx <= seg_table[display[11:8]];   // DK2：display[11:8]
            3'd1: led_cx <= seg_table[display[7:4]];    // DK1：display[7:4]
            3'd0: led_cx <= seg_table[display[3:0]];    // DK0：display[3:0]
            default: led_cx <= 8'hFF; //默认状态是全灭
        endcase
    end
end

endmodule