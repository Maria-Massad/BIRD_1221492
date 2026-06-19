//=============================================================================
// bird_tb.sv
// Top-level testbench
// Reference: BIRD Functional Specification
//=============================================================================
`timescale 1ns/1ps

// Include order matters — each file must come after files it depends on

// 1. Interface — everything needs this
`include "tb/interface/bird_if.sv"

// 2. Packet class — generators and monitors need it
`include "tb/generators/bird_packet.sv"

// 3. Generators — env needs them
`include "tb/generators/bird_local_generator.sv"
`include "tb/generators/bird_remote_generator.sv"
`include "tb/generators/bird_drop_generator.sv"

// 4. Driver — env needs it
`include "tb/drivers/bird_driver.sv"

// 5. Monitors — env needs them
`include "tb/monitors/bird_input_monitor.sv"
`include "tb/monitors/bird_local_monitor.sv"
`include "tb/monitors/bird_remote_monitor.sv"

// 6. Checkers and coverage — env needs them
`include "tb/checkers/bird_scoreboard.sv"
`include "tb/checkers/bird_assertions.sv"
`include "tb/coverage/bird_coverage.sv"

// 7. Environment — tests need it
`include "tb/env/bird_env.sv"

// 8. Tests last — they need everything above
`include "tb/tests/bird_local_basic_test.sv"
`include "tb/tests/bird_remote_reorder_test.sv"
`include "tb/tests/bird_drop_conditions_test.sv"
`include "tb/tests/bird_reset_test.sv"
`include "tb/tests/bird_backpressure_test.sv"
`include "tb/tests/bird_coverage_test.sv"

module bird_tb;

  //-------------------------------------------------------------------------
  // Clock
  //-------------------------------------------------------------------------
  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  //-------------------------------------------------------------------------
  // Interface instance
  //-------------------------------------------------------------------------
  bird_if bird_vif(clk);

  //-------------------------------------------------------------------------
  // DUT instance
  //-------------------------------------------------------------------------
  bird dut (
    .clk         (bird_vif.clk),
    .rst_n       (bird_vif.rst_n),
    .drop_cnt    (bird_vif.drop_cnt),
    .in_vld      (bird_vif.in_vld),
    .in_rdy      (bird_vif.in_rdy),
    .data_in     (bird_vif.data_in),
    .cfg         (bird_vif.cfg),
    .local_vld   (bird_vif.local_vld),
    .local_rdy   (bird_vif.local_rdy),
    .data_local  (bird_vif.data_local),
    .remote_vld  (bird_vif.remote_vld),
    .remote_rdy  (bird_vif.remote_rdy),
    .data_remote (bird_vif.data_remote)
  );

  //-------------------------------------------------------------------------
  // Assertions instance
  //-------------------------------------------------------------------------
  bird_assertions assertions_inst(.vif(bird_vif));

  //-------------------------------------------------------------------------
  // Environment and test objects
  //-------------------------------------------------------------------------
  bird_env              env;
  bird_local_basic_test     local_test;
  bird_remote_reorder_test  remote_test;
  bird_drop_conditions_test drop_test;
  bird_reset_test           reset_test;
  bird_backpressure_test    bp_test;
  bird_coverage_test        cov_test;

  //-------------------------------------------------------------------------
  // Reset task — spec §9
  //-------------------------------------------------------------------------
  task automatic apply_reset();
    $display("[%0t] TB: Applying reset", $time);
    bird_vif.rst_n = 1'b0;
    repeat (5) @(posedge clk);
    bird_vif.rst_n = 1'b1;
    repeat (5) @(posedge clk);
    $display("[%0t] TB: Reset released", $time);
  endtask

  //-------------------------------------------------------------------------
  // Main flow
  //-------------------------------------------------------------------------
  initial begin
    // safe defaults
    bird_vif.rst_n      = 1'b0;
    bird_vif.in_vld     = 1'b0;
    bird_vif.data_in    = 8'h00;
    bird_vif.cfg        = 32'h0000_0000;
    bird_vif.local_rdy  = 1'b1;
    bird_vif.remote_rdy = 1'b1;

    // build env and tests
    env         = new(bird_vif);
    local_test  = new(env);
    remote_test = new(env);
    drop_test   = new(env);
    reset_test  = new(env);
    bp_test     = new(env);
    cov_test    = new(env);

    // initialize and start monitors
    env.init();
    env.start_monitors();

    // apply reset
    apply_reset();

    $display("============================================================");
    $display("BIRD TESTBENCH STARTED");
    $display("============================================================");

    // run tests
    local_test.run();
    remote_test.run();
    drop_test.run();
    reset_test.run();
    bp_test.run();
    cov_test.run();

    // wait for any in-flight data
    repeat (20) @(posedge clk);

    // final report
    env.report();

    $display("============================================================");
    $display("BIRD TESTBENCH FINISHED");
    $display("============================================================");

    $finish;
  end

endmodule
