// 中断源接口
interface int_source_if;
  logic mextern_int;
  logic msoftware_int;
  logic mtimer_int;
  logic [30:0] custom_int_code;  // 外部中断控制器
  // 中断源都是来自不同的模块，这里只有一个硬件线程的modport
  modport hart(input mextern_int, msoftware_int, mtimer_int, custom_int_code);
endinterface
