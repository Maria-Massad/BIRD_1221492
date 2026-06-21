`include "bird_if.sv"
`include "bird_pkg.sv"
import bird_pkg::*;
`include "bird_local_generator.sv"
`include "bird_remote_generator.sv"
`include "bird_drop_generator.sv"
`include "bird_driver.sv"
`include "bird_input_monitor.sv"
`include "bird_local_monitor.sv"
`include "bird_remote_monitor.sv"
`include "bird_scoreboard.sv"
`include "bird_assertions.sv"
`include "bird_coverage.sv"
`include "bird_env.sv"
`include "bird_drop_conditions_test.sv"
`include "bird_sanity_test.sv"
`include "bird_backpressure_test.sv"
`include "bird_remote_reorder_test.sv"
`include "bird_reset_test.sv"
`include "bird_remote_full_test.sv"
`include "bird_drop_full_test.sv"
`include "bird_proto_full_test.sv"
`include "bird_loc_full_test.sv"
`include "bird_legacy_extra_test.sv"

module bird_tb;

  logic clk;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  bird_if bird_vif(clk);

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

  bird_assertions assertions_inst(.vif(bird_vif));

  bird_env                  env;
  bird_drop_conditions_test drop_test;
  bird_sanity_test          sanity_test;
  bird_backpressure_test    bp_test;
  bird_remote_reorder_test  remote_test;
  bird_reset_test           reset_test;
  bird_remote_full_test     remote_full_test;
  bird_drop_full_test       drop_full_test;
  bird_proto_full_test      proto_full_test;
  bird_loc_full_test        loc_full_test;
  bird_legacy_extra_test    legacy_extra_test;

 
  bit RUN_DROP_010_WRAPAROUND = 1'b0;

  task automatic apply_reset();
    bird_vif.rst_n = 1'b0;
    repeat (5) @(posedge clk);
    bird_vif.rst_n = 1'b1;
    repeat (5) @(posedge clk);
  endtask

  initial begin
    bird_vif.rst_n      = 1'b0;
    bird_vif.in_vld     = 1'b0;
    bird_vif.data_in    = 8'h00;
    bird_vif.cfg        = 32'h0000_0000;
    bird_vif.local_rdy  = 1'b1;
    bird_vif.remote_rdy = 1'b1;

    env              = new(bird_vif);
    drop_test        = new(env);
    sanity_test      = new(env);
    bp_test          = new(env);
    remote_test      = new(env);
    reset_test       = new(env);
    remote_full_test = new(env);
    drop_full_test   = new(env);
    proto_full_test  = new(env);
    loc_full_test    = new(env);
    legacy_extra_test = new(env);

    env.init();
    env.start_monitors();
    apply_reset();

    $display("============================================================");
    $display("BIRD TESTBENCH - ALL TESTS");
    $display("============================================================");

    $display("\n>>> TEST 1: Sanity (LOC_001/002/004/006/008/009)");
    sanity_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 2: Reset (PRO_005/006/007/008/012)");
    reset_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 3: Drop Conditions (LOC_007/011/012/013, DROP_002/003/004/005/007/008)");
    drop_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 4: Backpressure (LOC_010, PRO_002/004)");
    bp_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 5: Remote Reorder (REM_004)");
    remote_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 6: Remote Full (REM_001/002/003/005/006/012/013/014/015)");
    remote_full_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 7: Local Full (LOC_003 constrained-random)");
    loc_full_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 8: Protocol Full (PRO_001/003/009/010/011/013)");
    proto_full_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 9: Drop Full fast subset (DROP_006/009/011)");
    drop_full_test.run();
    apply_reset();
    env.prepare_for_test();

    $display("\n>>> TEST 10: Legacy Extra (converted from the original five extra-test files)");
    legacy_extra_test.run();
    apply_reset();
    env.prepare_for_test();

    if (RUN_DROP_010_WRAPAROUND) begin
      $display("\n>>> TEST 11: Drop Full wrap-around (DROP_010) -- this will take a while");
      drop_full_test.run_drop010_wraparound();
    end
    else begin
      $display("\n>>> TEST 11: SKIPPED -- DROP_010 wrap-around (RUN_DROP_010_WRAPAROUND=0)");
    end

    repeat (20) @(posedge clk);
    env.report();

    $display("============================================================");
    $display("ALL TESTS FINISHED");
    $display("============================================================");
    $finish;
  end

endmodule
