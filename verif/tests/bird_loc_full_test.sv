import bird_pkg::*;

`ifndef BIRD_LOC_FULL_TEST_SV
`define BIRD_LOC_FULL_TEST_SV

class bird_loc_full_test;

  bird_env env;

  function new(bird_env env);
    this.env = env;
  endfunction

  task run();
    bird_packet pkt;
    bit [15:0] drop_before;
    int pass_count;

    $display("============================================================");
    $display("TEST START: bird_loc_full_test");
    $display("============================================================");

    $display("[LOC_FULL] LOC_003: randomized valid local packets");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;
    pass_count  = 0;

    for (int i = 0; i < 10; i++) begin
      pkt = new();

      if (!pkt.randomize() with { pkt_type == LOCAL_PKT; }) begin
        $error("[LOC_FULL] FAIL LOC_003[%0d]: randomize() failed", i);
        continue;
      end

      pkt.print("LOC_FULL_RAND");
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(30);

      if (env.vif.drop_cnt === drop_before) begin
        $display("[LOC_FULL] PASS LOC_003[%0d]: random packet forwarded, no drop", i);
        pass_count++;
      end
      else begin
        $error("[LOC_FULL] FAIL LOC_003[%0d]: unexpected drop, delta=%0d",
               i, env.vif.drop_cnt - drop_before);
        drop_before = env.vif.drop_cnt;
      end
    end

    if (pass_count == 10)
      $display("[LOC_FULL] PASS LOC_003: all 10 randomized local packets forwarded correctly");
    else
      $error("[LOC_FULL] FAIL LOC_003: only %0d/10 randomized packets passed", pass_count);

    $display("============================================================");
    $display("TEST END: bird_loc_full_test");
    $display("============================================================");
  endtask

endclass

`endif