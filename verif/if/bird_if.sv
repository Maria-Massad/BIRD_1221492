`ifndef BIRD_IF_SV
`define BIRD_IF_SV

interface bird_if(input logic clk);

  logic        rst_n;
  logic [15:0] drop_cnt;

  logic        in_vld;
  logic        in_rdy;
  logic [7:0]  data_in;
  logic [31:0] cfg;

  logic       local_vld;
  logic       local_rdy;
  logic [7:0] data_local;

  logic        remote_vld;
  logic        remote_rdy;
  logic [31:0] data_remote;

  // Main driver clocking block used by bird_driver.
  clocking drv_cb @(posedge clk);
    default input #1step output #1ns;

    output in_vld;
    output data_in;
    output cfg;
    output local_rdy;
    output remote_rdy;

    input  rst_n;
    input  in_rdy;
    input  local_vld;
    input  data_local;
    input  remote_vld;
    input  data_remote;
    input  drop_cnt;
  endclocking

  // Compatibility driver clocking block used by member test files.
  clocking driver_cb @(posedge clk);
    default input #1step output #1ns;

    output rst_n;
    output in_vld;
    output data_in;
    output cfg;
    output local_rdy;
    output remote_rdy;

    input  in_rdy;
    input  local_vld;
    input  data_local;
    input  remote_vld;
    input  data_remote;
    input  drop_cnt;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step output #1ns;

    input rst_n;
    input in_vld;
    input in_rdy;
    input data_in;
    input cfg;
    input local_vld;
    input local_rdy;
    input data_local;
    input remote_vld;
    input remote_rdy;
    input data_remote;
    input drop_cnt;
  endclocking

  // Compatibility read-only clocking blocks used directly by tests.
  clocking local_cb @(posedge clk);
    default input #1step output #1ns;
    input local_vld;
    input local_rdy;
    input data_local;
  endclocking

  clocking remote_cb @(posedge clk);
    default input #1step output #1ns;
    input remote_vld;
    input remote_rdy;
    input data_remote;
  endclocking

  modport DRIVER (
    clocking drv_cb,
    input clk,
    input rst_n
  );

  modport MONITOR (
    clocking mon_cb,
    input clk,
    input rst_n
  );

  modport DUT (
    input  clk,
    input  rst_n,
    input  in_vld,
    output in_rdy,
    input  data_in,
    input  cfg,
    output local_vld,
    input  local_rdy,
    output data_local,
    output remote_vld,
    input  remote_rdy,
    output data_remote,
    output drop_cnt
  );

endinterface

`endif
