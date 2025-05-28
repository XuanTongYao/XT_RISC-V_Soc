// 模块: 数码管16进制同步显示，每段数码管直接与IO口相连接
// 功能: 将4bit数据以16进制显示到数码管，每个数据与输出端口一一对应。
//       也可以启用扩展编码，输入5bit的数据进行显示。
//       可控制选位，无灭零功能，支持小数点
// 版本: v0.9
// 作者: 姚萱彤
// <<< 参 数 >>> //
// NUM:      使用的数码管的数量
// COM:      指定公共端为阴阳极
// E_CODE:   是否启用扩展编码，1为启用，0为不启用
//
// <<< 端 口 >>> //
// data_in:         并行数据输入多个4/5bit的数据      ...[7:4] [3:0]/...[9:5] [4:0]
// dig:             并行选位输入,通常处于公共端状态时有效
// dp:              并行小数点输入
// ledsd:           多个9引脚的数码管端口             ...[17:9] [8:0] 每个端口高2位连接DIG，Dp；低7位连g-a段

module LEDSD_Direct #(
    parameter bit E_CODE = 0,
    parameter bit COM = 1,
    parameter int NUM = 2
) (
    input        [3+E_CODE:0] data_in[NUM],
    input                     dig    [NUM],
    input                     dp     [NUM],
    output logic [       8:0] ledsd  [NUM]
);
  localparam int WIDTH = 4 + E_CODE;

  //生成数码管信号连线
  logic [6:0] code[NUM];
  generate
    for (genvar i = 0; i < NUM; i = i + 1) begin : gen_multi_LEDSD
      always_comb begin
        unique case (data_in[i])
          5'd0: code[i] = {7{COM}} ^ {7'h3F};  //0
          5'd1: code[i] = {7{COM}} ^ {7'h06};  //1
          5'd2: code[i] = {7{COM}} ^ {7'h5B};  //2
          5'd3: code[i] = {7{COM}} ^ {7'h4F};  //3
          5'd4: code[i] = {7{COM}} ^ {7'h66};  //4
          5'd5: code[i] = {7{COM}} ^ {7'h6D};  //5
          5'd6: code[i] = {7{COM}} ^ {7'h7D};  //6
          5'd7: code[i] = {7{COM}} ^ {7'h07};  //7
          5'd8: code[i] = {7{COM}} ^ {7'h7F};  //8
          5'd9: code[i] = {7{COM}} ^ {7'h6F};  //9
          5'd10: code[i] = {7{COM}} ^ {7'h77};  //A
          5'd11: code[i] = {7{COM}} ^ {7'h7C};  //b
          5'd12: code[i] = {7{COM}} ^ {7'h39};  //C
          5'd13: code[i] = {7{COM}} ^ {7'h5E};  //d
          5'd14: code[i] = {7{COM}} ^ {7'h79};  //E
          5'd15: code[i] = {7{COM}} ^ {7'h71};  //F
          //扩展编码
          5'd16: code[i] = {7{COM}} ^ {7'h76};  //H
          5'd17: code[i] = {7{COM}} ^ {7'h38};  //L
          5'd18: code[i] = {7{COM}} ^ {7'h54};  //n
          5'd19: code[i] = {7{COM}} ^ {7'h5C};  //o
          5'd20: code[i] = {7{COM}} ^ {7'h73};  //P
          5'd21: code[i] = {7{COM}} ^ {7'h67};  //q
          5'd22: code[i] = {7{COM}} ^ {7'h3E};  //U
          5'd23: code[i] = {7{COM}} ^ {7'h6E};  //y
          5'd24: code[i] = {7{COM}} ^ {7'h40};  //-
          5'd25: code[i] = {7{COM}} ^ {7'h48};  //=
          default: code[i] = {7{COM}} ^ {7'b0};
        endcase
      end
      assign ledsd[i] = {COM ^ dig[i], COM ^ dp[i], code[i]};
    end
  endgenerate


endmodule
