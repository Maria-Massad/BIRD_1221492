import bird_pkg::*;

`ifndef BIRD_DROP_FULL_TEST_SV
`define BIRD_DROP_FULL_TEST_SV

class bird_drop_full_test;

  bird_env env;
  bird_remote_generator remote_gen;

  function new(bird_env env);
    this.env        = env;
    this.remote_gen = new();
  endfunction

  task flush_pipeline();
    bird_packet flush;
    byte unsigned d[];
    flush = new();
    d     = new[2];
    d[0]  = 8'hAA;
    d[1]  = 8'hBB;
    flush.make_local(5'd1, d);
    env.driver.drive_packet(flush);
    env.wait_cycles(5);
  endtask

  
  task run();
    bird_packet pkt, frag1, frag2;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("============================================================");
    $display("TEST START: bird_drop_full_test");
    $display("============================================================");

    //-------------------------------------------------------------
    // DROP_006: drop_cnt unaffected by valid complete remote packet
    //-------------------------------------------------------------
    $display("[DROP_FULL] DROP_006: drop_cnt unaffected by valid remote packet");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;
    frag1 = remote_gen.create_two_fragment_packet_frag1();
    frag2 = remote_gen.create_two_fragment_packet_frag2();
    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);
    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    env.wait_cycles(30);
    if (env.vif.drop_cnt === drop_before)
      $display("[DROP_FULL] PASS DROP_006: drop_cnt unchanged after valid remote packet");
    else
      $error("[DROP_FULL] FAIL DROP_006: drop_cnt changed unexpectedly, delta=%0d",
             env.vif.drop_cnt - drop_before);

    //-------------------------------------------------------------
    // DROP_009: FRAG_NUM=1 arrives while previous SEQ_NUM packet
    // is still incomplete.
    // Step 1: send frag_num=2 for seq=30 first (establishes an
    //         incomplete accumulation -- frag1 still missing)
    // Step 2: send frag_num=1 for a DIFFERENT seq=31
    //         -> spec: previous (seq=30) packet is dropped (+1),
    //            new packet (seq=31) accumulation starts
    // Step 3: complete seq=31 with frag_num=2 to confirm recovery
    //-------------------------------------------------------------
    $display("[DROP_FULL] DROP_009: FRAG_NUM=1 while previous packet incomplete");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2]; d[0] = 8'h20; d[1] = 8'h21;
    pkt = remote_gen.create_remote_fragment(5'd30, 5'd2, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(10);

    d = new[2]; d[0] = 8'h22; d[1] = 8'h23;
    pkt = remote_gen.create_remote_fragment(5'd31, 5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[DROP_FULL] PASS DROP_009a: incomplete seq=30 packet dropped (+1)");
    else
      $error("[DROP_FULL] FAIL DROP_009a: expected +1 drop, got delta=%0d",
             env.vif.drop_cnt - drop_before);

    d = new[2]; d[0] = 8'h24; d[1] = 8'h25;
    pkt = remote_gen.create_remote_fragment(5'd31, 5'd2, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(30);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[DROP_FULL] PASS DROP_009b: new packet (seq=31) completed, no extra drop");
    else
      $error("[DROP_FULL] FAIL DROP_009b: unexpected additional drop, delta=%0d",
             env.vif.drop_cnt - drop_before);

    //-------------------------------------------------------------
    // DROP_011: buffered data cleared after drop -- next valid
    // packet must be processed cleanly with no leftover state.
    //-------------------------------------------------------------
    $display("[DROP_FULL] DROP_011: buffered data cleared after drop");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2]; d[0] = 8'h40; d[1] = 8'h41;
    pkt = remote_gen.create_remote_fragment(5'd32, 5'd2, d); // incomplete, frag1 missing
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(10);

    d = new[2]; d[0] = 8'h42; d[1] = 8'h43;
    pkt = remote_gen.create_remote_fragment(5'd33, 5'd1, d); // forces drop of seq=32
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(20);

    begin
      bird_packet local_pkt;
      byte unsigned ld[];
      local_pkt = new();
      ld = new[3]; ld[0] = 8'h55; ld[1] = 8'h66; ld[2] = 8'h77;
      local_pkt.make_local(5'd1, ld);
      env.coverage.sample_packet(local_pkt);
      env.driver.drive_packet(local_pkt);
      env.wait_cycles(20);
    end

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[DROP_FULL] PASS DROP_011: no leftover contamination, exactly 1 drop recorded");
    else
      $error("[DROP_FULL] FAIL DROP_011: unexpected drop_cnt delta=%0d",
             env.vif.drop_cnt - drop_before);

    $display("============================================================");
    $display("TEST END: bird_drop_full_test (fast subset)");
    $display("============================================================");
  endtask

  //-------------------------------------------------------------------------
  // run_drop010_wraparound() -- DROP_010 ONLY.
  // Drives 65536 invalid packets back-to-back to force drop_cnt to wrap
  // from 65535 to 0. This is SLOW (hundreds of thousands of clock cycles)
  // -- call separately, or guard it behind a flag in bird_tb.sv, if your
  // simulation time budget is tight before the deadline.
  //-------------------------------------------------------------------------
  task run_drop010_wraparound();
    $display("============================================================");
    $display("TEST START: bird_drop_full_test (DROP_010 wrap-around)");
    $display("============================================================");

    env.prepare_for_test();

    for (int n = 0; n < 65536; n++) begin
      bird_packet bad;
      byte unsigned bd[];
      bad = new();
      bd = new[1]; bd[0] = 8'hEE;
      bad.make_local(5'd1, bd);
      bad.seq_num = 5'd0;        // invalid -> drop
      bad.finalize_packet();
      env.driver.drive_packet(bad);
      if (n % 8192 == 0)
        $display("[DROP_FULL] DROP_010 progress: %0d/65536 sent, drop_cnt=%0d",
                 n, env.vif.drop_cnt);
    end
    flush_pipeline();
    env.wait_cycles(20);

    if (env.vif.drop_cnt === 16'd0)
      $display("[DROP_FULL] PASS DROP_010: drop_cnt wrapped from 65535 to 0 correctly");
    else
      $error("[DROP_FULL] FAIL DROP_010: drop_cnt=%0d, expected wrap to 0",
             env.vif.drop_cnt);

    $display("============================================================");
    $display("TEST END: bird_drop_full_test (DROP_010 wrap-around)");
    $display("============================================================");
  endtask

endclass

`endif

