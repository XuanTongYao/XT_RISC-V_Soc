interface wishbone_if #(
    int PORT_SIZE = 8
);

  logic ack;
  logic [PORT_SIZE-1:0] dat_slave, dat_master;
  logic cyc;
  logic stb;
  logic we;
  logic [PORT_SIZE-1:0] adr;

  modport master(output dat_master, cyc, stb, we, adr, input ack, dat_slave);
  modport slave(input dat_master, cyc, stb, we, adr, output ack, dat_slave);

endinterface

interface wishbone_syscon_if;

  logic clk, rst;

  modport syscon(output clk, rst);
  modport port(input clk, rst);

endinterface
