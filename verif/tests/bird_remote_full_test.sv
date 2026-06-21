import bird_pkg::*;

`ifndef BIRD_REMOTE_FULL_TEST_SV
`define BIRD_REMOTE_FULL_TEST_SV

class bird_remote_full_test;

  bird_env env;
  bird_remote_generator remote_gen;

  function new(bird_env env);
    this.env        = env;
    this.remote_gen = new();
  endfunction

  task check_no_drop(string name, bit [15:0] before_val);
    if (env.vif.drop_cnt === before_val)
      $display("[REM_FULL] PASS %s: drop_cnt unchanged (%0d)", name, before_val);
    else
      $error("[REM_FULL] FAIL %s: drop_cnt changed before=%0d after=%0d",
             name, before_val, env.vif.drop_cnt);
  endtask

  task run();
    bird_packet pkt, frag1, frag2, frag3;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("============================================================");
    $display("TEST START: bird_remote_full_test");
    $display("============================================================");

    // REM_001: single fragment remote packet
    $display("[REM_FULL] REM_001: single fragment remote packet");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    pkt = remote_gen.create_single_fragment_remote_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(30);

    check_no_drop("REM_001", drop_before);

    // REM_002: two fragments in order
    $display("[REM_FULL] REM_002: two fragments in order");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    frag1 = remote_gen.create_two_fragment_packet_frag1();
    frag2 = remote_gen.create_two_fragment_packet_frag2();

    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);

    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    env.wait_cycles(30);

    check_no_drop("REM_002", drop_before);

    // REM_003: three fragments in order
    $display("[REM_FULL] REM_003: three fragments in order");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[1];
    d[0] = 8'hA1;
    frag1 = remote_gen.create_remote_fragment(5'd20, 5'd1, d);

    d = new[2];
    d[0] = 8'hB1;
    d[1] = 8'hB2;
    frag2 = remote_gen.create_remote_fragment(5'd20, 5'd2, d);

    d = new[3];
    d[0] = 8'hC1;
    d[1] = 8'hC2;
    d[2] = 8'hC3;
    frag3 = remote_gen.create_remote_fragment(5'd20, 5'd3, d);

    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);
    env.coverage.sample_packet(frag3);

    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    env.driver.drive_packet(frag3);
    env.wait_cycles(30);

    check_no_drop("REM_003", drop_before);

    // REM_005: three fragments out of order
    $display("[REM_FULL] REM_005: three fragments out of order");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[1];
    d[0] = 8'hD1;
    frag1 = remote_gen.create_remote_fragment(5'd21, 5'd1, d);

    d = new[2];
    d[0] = 8'hE1;
    d[1] = 8'hE2;
    frag2 = remote_gen.create_remote_fragment(5'd21, 5'd2, d);

    d = new[2];
    d[0] = 8'hF1;
    d[1] = 8'hF2;
    frag3 = remote_gen.create_remote_fragment(5'd21, 5'd3, d);

    env.coverage.sample_packet(frag3);
    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);
    env.coverage.sample_reorder(1'b1);

    env.driver.drive_packet(frag3);
    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    env.wait_cycles(30);

    check_no_drop("REM_005", drop_before);

    // REM_006: one remote packet at a time
    $display("[REM_FULL] REM_006: only one remote packet at a time");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'h10;
    d[1] = 8'h11;
    frag1 = remote_gen.create_remote_fragment(5'd22, 5'd1, d);

    d = new[2];
    d[0] = 8'h99;
    d[1] = 8'h98;
    frag2 = remote_gen.create_remote_fragment(5'd23, 5'd2, d);

    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);
    env.coverage.sample_seq_mismatch(1'b1);

    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[REM_FULL] PASS REM_006a: mismatched fragment dropped (+1)");
    else
      $error("[REM_FULL] FAIL REM_006a: expected +1 drop, got delta=%0d",
             env.vif.drop_cnt - drop_before);

    d = new[2];
    d[0] = 8'h12;
    d[1] = 8'h13;
    frag2 = remote_gen.create_remote_fragment(5'd22, 5'd2, d);

    env.coverage.sample_packet(frag2);
    env.driver.drive_packet(frag2);
    env.wait_cycles(30);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[REM_FULL] PASS REM_006b: original packet completed, no extra drop");
    else
      $error("[REM_FULL] FAIL REM_006b: unexpected additional drop, delta=%0d",
             env.vif.drop_cnt - drop_before);

    // REM_012: minimum payload remote fragment
    $display("[REM_FULL] REM_012: minimum payload remote fragment");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[1];
    d[0] = 8'h7A;

    pkt = remote_gen.create_remote_fragment(5'd24, 5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    check_no_drop("REM_012", drop_before);

    // REM_013: maximum payload remote fragment
    $display("[REM_FULL] REM_013: maximum payload remote fragment");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[255];
    foreach (d[i])
      d[i] = byte'(i);

    pkt = remote_gen.create_remote_fragment(5'd25, 5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(300);

    check_no_drop("REM_013", drop_before);

    // REM_014: maximum FRAG_NUM value
    $display("[REM_FULL] REM_014: 31 fragments, same SEQ_NUM");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    for (int f = 1; f <= 31; f++) begin
      bird_packet frag;
      byte unsigned fd[];

      fd = new[2];
      fd[0] = byte'(f);
      fd[1] = byte'(8'hF0 + f[3:0]);

      frag = remote_gen.create_remote_fragment(5'd26, f[4:0], fd);
      env.coverage.sample_packet(frag);
      env.driver.drive_packet(frag);
    end

    env.wait_cycles(60);
    check_no_drop("REM_014", drop_before);

    // REM_015: two consecutive remote packets
    $display("[REM_FULL] REM_015: two consecutive remote packets, different SEQ_NUM");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'h01;
    d[1] = 8'h02;

    pkt = remote_gen.create_remote_fragment(5'd27, 5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    d = new[3];
    d[0] = 8'h03;
    d[1] = 8'h04;
    d[2] = 8'h05;

    pkt = remote_gen.create_remote_fragment(5'd28, 5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    check_no_drop("REM_015", drop_before);

    $display("============================================================");
    $display("TEST END: bird_remote_full_test");
    $display("============================================================");
  endtask

endclass

`endif