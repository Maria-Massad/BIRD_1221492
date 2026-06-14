
`include "bird_if.sv"
`include "bird_pkg.sv"
`include "bird_driver.sv"

`include "bird_sanity_test.sv"
//`include "bird_drop_test_a.sv"
//`include "bird_backpressure_test.sv"

import bird_pkg::*;

module bird_tb;

  logic clk = 0;
  always #5 clk = ~clk;
  
  bird_if dut_if(.clk(clk));
  

  

  // DUT
  bird dut (
    .clk(clk),
    .rst_n(dut_if.rst_n),

    .in_vld(dut_if.in_vld),
    .in_rdy(dut_if.in_rdy),
    .data_in(dut_if.data_in),
    .cfg(dut_if.cfg),

    .drop_cnt(dut_if.drop_cnt),

    .local_vld(dut_if.local_vld),
    .local_rdy(dut_if.local_rdy),
    .data_local(dut_if.data_local),

    .remote_vld(dut_if.remote_vld),
    .remote_rdy(dut_if.remote_rdy),
    .data_remote(dut_if.data_remote)
  );
  
  
  mailbox #(bird_packet) mbx =new();
  
  bird_driver drv;





  initial begin
    // VCD
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, bird_tb);
    
    
    // create driver and connect it
    drv = new(dut_if, mbx);

    
    // start driver in background (parallel thread) 
    fork
      drv.run();
    join_none
 
    // reset the DUT 
    drv.reset(5);
 
    // --- run tests one by one ---
    // Each test is a task defined in its own file
 
    $display("==============================================");
    $display(" BIRD Testbench Starting");
    $display("==============================================");
 
   //tests
    run_sanity_test();
    run_drop_test_a();
    //run_backpressure_test();
 
    // give DUT time to finish any in-flight packets
    drv.wait_cycles(20);
 
    $display("==============================================");
    $display(" All tests done");
    $display("==============================================");
 
    $finish;
  end
  // sanity test put pkt in mail box
  task run_sanity_test();
    bird_sanity_test t = new(dut_if, mbx);
    $display("\n--- Running: bird_sanity_test ---");
    t.run();
    drv.wait_cycles(10);
  endtask
  
  //drop test
  task run_drop_test_a();
    bird_drop_test_a t = new(dut_if, mbx);
    $display("\n--- Running: bird_drop_test_a ---");
    t.run();
    drv.wait_cycles(10);
  endtask
  /*
  //back pressure test
  task run_backpressure_test();
    bird_backpressure_test t = new(dut_if, mbx);
    $display("\n--- Running: bird_backpressure_test ---");
    t.run();
    drv.wait_cycles(10);
  endtask */

endmodule : bird_tb
