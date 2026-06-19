
`ifndef BIRD_IF_SV
`define BIRD_IF_SV

interface bird_if(input logic clk);

  
  logic rst_n; // global reset
  logic [15:0] drop_cnt; //status output

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


  clocking drv_cb @(posedge clk); //clocking block for the driver
    default input #1step output #1ns;

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

 
  // Modport used by plain SystemVerilog driver
  
  modport DRIVER (
    input  clk,
    input  rst_n,

    output in_vld,
    output data_in,
    output cfg,
    output local_rdy,
    output remote_rdy,

    input  in_rdy,
    input  local_vld,
    input  data_local,
    input  remote_vld,
    input  data_remote,
    input  drop_cnt
  );

  
  // Modport used by plain SystemVerilog monitors/checkers
 
  modport MONITOR (
    clocking mon_cb,
    input clk,
    input rst_n
  );

  
  // Modport used by DUT connection
 
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
