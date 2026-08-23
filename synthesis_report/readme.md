# 参考综合报告

以LCMXO2-4000HC-4MG132C器件作为参考，使用Lattice Diamond 3.13进行综合。包含各个模块的资源消耗情况，便于其他人对本项目进行FPGA资源评估。

[Synthesis Report(综合报告)](process/GitTest_impl1_synplify.html)
[Mapping Report(映射报告)](process/GitTest_impl1_mrp.html)
[Place and Route Report(布局&布线报告)](process/GitTest_impl1_par.html)
[PAD](process/GitTest_impl1_pad.html)

时序分析报告

[Map TRACE](analysis/GitTest_impl1_tw1.html)
[Place & Route TRACE](analysis/GitTest_impl1_twr.html)

层次结构资源消耗表[数据来源](hierarchy_resources.csv):

| Hierarchy Node                                           | LUT4              | PFU Registers | IO Registers | EBR  | Distributed RAM | Carry Cells | SLICE               |
| -------------------------------------------------------- | ----------------- | ------------- | ------------ | ---- | --------------- | ----------- | ------------------- |
| XT_Soc_Risc_V（顶层模块/总和）                           | 3223(7.62939e-05) | 1702(0)       | 53(53)       | 8(0) | 108(0)          | 210(0)      | 1947(-0.00984192)   |
| u_AF_GPIO_BUS                                            | 159(159)          | 170(170)      | 0(0)         | 0(0) | 0(0)            | 0(0)        | 102.33(102.33)      |
| u_DM                                                     | 210(208)          | 148(144)      | 0(0)         | 0(0) | 0(0)            | 0(0)        | 96.45(94.42)        |
| u_DM/u_OncePulse_dmcontrol_reset                         | 1(1)              | 2(2)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.7(0.7)            |
| u_DM/u_SyncAsyncReset                                    | 1(1)              | 2(2)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1.33(1.33)          |
| u_External_INT_Ctrl                                      | 19(19)            | 32(32)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 14.58(14.58)        |
| u_HarvardBootstrap                                       | 61(32)            | 19(19)        | 0(0)         | 0(0) | 0(0)            | 4(4)        | 27.83(17.66)        |
| u_HarvardBootstrap/u_ROM                                 | 29(29)            | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 10.17(10.17)        |
| u_HarvardSystemRAM                                       | 137.17(12.67)     | 5(3)          | 0(0)         | 8(0) | 0(0)            | 0(0)        | 64.12(6.01)         |
| u_HarvardSystemRAM/u_AlignedRAM_Adapte                   | 60(60)            | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 26.58(26.58)        |
| u_HarvardSystemRAM/u_SystemRAM                           | 64.5(64.5)        | 2(2)          | 0(0)         | 8(8) | 0(0)            | 0(0)        | 31.53(31.53)        |
| u_JtagDTM                                                | 108(101)          | 254(162)      | 0(0)         | 0(0) | 0(0)            | 0(0)        | 95.92(70.25)        |
| u_JtagDTM/u_CDC_MCP_Formulation                          | 7(4)              | 92(84)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 25.67(22.92)        |
| u_JtagDTM/u_CDC_MCP_Formulation/u_OncePulse_ack          | 1(1)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1(1)                |
| u_JtagDTM/u_CDC_MCP_Formulation/u_OncePulse_en           | 0(0)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.75(0.75)          |
| u_JtagDTM/u_CDC_MCP_Formulation/u_StopAndWaitFSM_receive | 1(1)              | 1(1)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.5(0.5)            |
| u_JtagDTM/u_CDC_MCP_Formulation/u_StopAndWaitFSM_send    | 1(1)              | 1(1)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.5(0.5)            |
| u_LEDSD_Direct_BUS                                       | 20(6)             | 12(12)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 8.58(4.91)          |
| u_LEDSD_Direct_BUS/u_LEDSD_Direct                        | 14(14)            | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 3.67(3.67)          |
| u_LED_LBUS                                               | 0(0)              | 8(8)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 2(2)                |
| u_RISC_V_Core                                            | 1586(0)           | 607(0)        | 0(0)         | 0(0) | 96(0)           | 132(0)      | 981.77(3.05176e-05) |
| u_RISC_V_Core/trap                                       | 3(3)              | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1(1)                |
| u_RISC_V_Core/u_CSR                                      | 297(297)          | 203(203)      | 0(0)         | 0(0) | 0(0)            | 33(33)      | 154.67(154.67)      |
| u_RISC_V_Core/u_CoreCtrl                                 | 111(111)          | 33(33)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 55.92(55.92)        |
| u_RISC_V_Core/u_CoreReg                                  | 192(192)          | 0(0)          | 0(0)         | 0(0) | 96(96)          | 0(0)        | 181.75(181.75)      |
| u_RISC_V_Core/u_DebugCtrl                                | 57(57)            | 126(126)      | 0(0)         | 0(0) | 0(0)            | 0(0)        | 51.83(51.83)        |
| u_RISC_V_Core/u_ExceptionCtrl                            | 45.5(45.5)        | 1(1)          | 0(0)         | 0(0) | 0(0)            | 16(16)      | 19.25(19.25)        |
| u_RISC_V_Core/u_ExceptionPipeLine                        | 4.5(4.5)          | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 2.12(2.12)          |
| u_RISC_V_Core/u_ID_EX                                    | 41(41)            | 176(176)      | 0(0)         | 0(0) | 0(0)            | 0(0)        | 57.48(57.48)        |
| u_RISC_V_Core/u_IF_ID                                    | 29(29)            | 33(33)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 20.98(20.98)        |
| u_RISC_V_Core/u_InstructionDecode                        | 179(179)          | 0(0)          | 0(0)         | 0(0) | 0(0)            | 8(8)        | 61.02(61.02)        |
| u_RISC_V_Core/u_InstructionExecute                       | 597(597)          | 0(0)          | 0(0)         | 0(0) | 0(0)            | 59(59)      | 349.5(349.5)        |
| u_RISC_V_Core/u_PC_Reg                                   | 30(30)            | 32(32)        | 0(0)         | 0(0) | 0(0)            | 16(16)      | 26.25(26.25)        |
| u_ROM_Reg                                                | 317(317)          | 30(30)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 158.25(158.25)      |
| u_ResetController                                        | 48(41)            | 33(27)        | 0(0)         | 0(0) | 0(0)            | 8(8)        | 32.92(29.17)        |
| u_ResetController/u_WISHBONE_MASTER                      | 7(7)              | 6(6)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 3.75(3.75)          |
| u_ResetWishboneOverride                                  | 19(19)            | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 9.17(9.17)          |
| u_SoftwareINT                                            | 4(4)              | 32(32)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 9.67(9.67)          |
| u_SystemTimer                                            | 137(136)          | 166(163)      | 0(0)         | 0(0) | 0(0)            | 66(66)      | 128.25(126.83)      |
| u_SystemTimer/u_OncePulse                                | 1(1)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1.42(1.42)          |
| u_SystmePLL                                              | 0(0)              | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0(0)                |
| u_UART                                                   | 96(47)            | 83(46)        | 0(0)         | 0(0) | 12(0)           | 0(0)        | 62.42(26.92)        |
| u_UART/u_ClockDivider                                    | 3(3)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 3(3)                |
| u_UART/u_rx_FIFO_SC                                      | 22(22)            | 15(15)        | 0(0)         | 0(0) | 6(6)            | 0(0)        | 14.58(14.58)        |
| u_UART/u_rx_OncePulse                                    | 0(0)              | 2(2)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.5(0.5)            |
| u_UART/u_tx_FIFO_SC                                      | 23(23)            | 15(15)        | 0(0)         | 0(0) | 6(6)            | 0(0)        | 16.82(16.82)        |
| u_UART/u_tx_OncePulse                                    | 1(1)              | 2(2)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.6(0.6)            |
| u_WISHBONE_Adapter                                       | 16(13)            | 29(3)         | 0(0)         | 0(0) | 0(0)            | 0(0)        | 12.58(4.58)         |
| u_WISHBONE_Adapter/u_WISHBONE_MASTER                     | 3(3)              | 26(26)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 8(8)                |
| u_XT_HB                                                  | 153.83(131.83)    | 6(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 63(51.67)           |
| u_XT_HB/u_MMIO                                           | 16(16)            | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 7.83(7.83)          |
| u_XT_HB/u_XT_BusArbiter                                  | 6(0)              | 6(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 3.5(0)              |
| u_XT_HB/u_XT_BusArbiter/gen_polling.u_ReadArbiter        | 3(3)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1.75(1.75)          |
| u_XT_HB/u_XT_BusArbiter/gen_polling.u_WriteArbiter       | 3(3)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1.75(1.75)          |
| u_XT_HB32_Adapter                                        | 96(96)            | 1(1)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 46.67(46.67)        |
| u_XT_LB                                                  | 36(29)            | 67(25)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 30.5(17.25)         |
| u_XT_LB/u_CDC_MCP_Formulation                            | 7(3)              | 42(34)        | 0(0)         | 0(0) | 0(0)            | 0(0)        | 13.25(9.66)         |
| u_XT_LB/u_CDC_MCP_Formulation/u_OncePulse_ack            | 1(1)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 1.17(1.17)          |
| u_XT_LB/u_CDC_MCP_Formulation/u_OncePulse_en             | 0(0)              | 3(3)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.83(0.83)          |
| u_XT_LB/u_CDC_MCP_Formulation/u_StopAndWaitFSM_receive   | 1(1)              | 1(1)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.67(0.67)          |
| u_XT_LB/u_CDC_MCP_Formulation/u_StopAndWaitFSM_send      | 2(2)              | 1(1)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0.92(0.92)          |
| u_efb                                                    | 0(0)              | 0(0)          | 0(0)         | 0(0) | 0(0)            | 0(0)        | 0(0)                |
