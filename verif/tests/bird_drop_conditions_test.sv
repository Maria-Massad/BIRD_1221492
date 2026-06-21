import bird_pkg::*;

`ifndef BIRD_DROP_CONDITIONS_TEST_SV
`define BIRD_DROP_CONDITIONS_TEST_SV

class bird_drop_conditions_test;

  bird_env env;

  function new(bird_env env);
    this.env = env;
  endfunction

<<<<<<< HEAD
 
=======
>>>>>>> 21f17b6 (Add additional BIRD test files)
  task check_drop(string name, bit [15:0] expected, bit [15:0] actual);
    if (actual === expected)
      $display("[DROP] PASS %s: drop_cnt=%0d", name, actual);
    else
      $error("[DROP] FAIL %s: expected=%0d actual=%0d",
             name, expected, actual);
  endtask

<<<<<<< HEAD
  
  task flush_pipeline();
    bird_packet flush;
    byte unsigned d[];
=======
  task flush_pipeline();
    bird_packet flush;
    byte unsigned d[];

>>>>>>> 21f17b6 (Add additional BIRD test files)
    flush = new();
    d     = new[2];
    d[0]  = 8'hAA;
    d[1]  = 8'hBB;
<<<<<<< HEAD
=======

>>>>>>> 21f17b6 (Add additional BIRD test files)
    flush.make_local(5'd1, d);
    env.driver.drive_packet(flush);
    env.wait_cycles(10);
  endtask

<<<<<<< HEAD
  //-------------------------------------------------------------------------
  // run()
  //-------------------------------------------------------------------------
=======
>>>>>>> 21f17b6 (Add additional BIRD test files)
  task run();
    bird_packet   pkt;
    bird_packet   frag1;
    bird_packet   frag2;
    bit [15:0]    expected_drop;
    bit [15:0]    drop_before;
    byte unsigned d1[];
    byte unsigned d2[];

    $display("============================================================");
    $display("TEST START: bird_drop_conditions_test");
    $display("============================================================");

    env.prepare_for_test();
    expected_drop = env.vif.drop_cnt;
    drop_before   = env.vif.drop_cnt;

<<<<<<< HEAD
    // -- Case 1: SEQ_NUM = 0 -- spec §8.1
=======
    // Case 1: invalid SEQ_NUM
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 1: SEQ_NUM=0");
    pkt = env.drop_gen.create_seq_zero_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("SEQ_ZERO", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 2: FRAG_NUM = 0 -- spec §8.1
=======
    // Case 2: invalid FRAG_NUM
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 2: FRAG_NUM=0");
    pkt = env.drop_gen.create_frag_zero_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("FRAG_ZERO", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 3: PAYLOAD_LEN = 0 -- spec §8.1
    // Use REMOTE pkt with 1 dummy byte so DUT reads cfg
    $display("[DROP] Case 3: PAYLOAD_LEN=0");
    begin
      bird_packet p = new();
=======
    // Case 3: invalid payload length
    $display("[DROP] Case 3: PAYLOAD_LEN=0");
    begin
      bird_packet p = new();

>>>>>>> 21f17b6 (Add additional BIRD test files)
      p.traffic_type = bird_packet::REMOTE_TRAFFIC;
      p.seq_num      = 5'd1;
      p.frag_num     = 5'd1;
      p.payload_len  = 8'd0;
      p.rsvd_7_1     = 7'd0;
      p.rsvd_23_21   = 3'd0;
      p.rsvd_31_29   = 3'd0;
      p.payload      = new[1];
      p.payload[0]   = 8'hFF;
<<<<<<< HEAD
=======

>>>>>>> 21f17b6 (Add additional BIRD test files)
      p.finalize_packet();
      env.coverage.sample_packet(p);
      env.driver.drive_packet(p);
    end
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("PAYLOAD_LEN_ZERO", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 4: Reserved bits non-zero -- spec §8.1
=======
    // Case 4: reserved bits are not zero
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 4: Reserved bits non-zero");
    pkt = env.drop_gen.create_reserved_bits_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("RESERVED_BITS", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 5: Local FRAG_NUM != 1 -- spec §8.1
=======
    // Case 5: local packet with invalid FRAG_NUM
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 5: LOCAL FRAG_NUM=2");
    pkt = env.drop_gen.create_local_invalid_frag_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("LOCAL_INVALID_FRAG", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 6: Remote SEQ mismatch -- spec section 8.1
    // A fragment with a different SEQ_NUM arrives while another remote packet
    // is being accumulated. The affected incomplete packet is counted once.
=======
    // Case 6: remote SEQ_NUM mismatch
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 6: Remote SEQ mismatch");
    env.drop_gen.create_remote_seq_mismatch_pair(frag1, frag2);
    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);
    env.coverage.sample_seq_mismatch(1'b1);
    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);
    flush_pipeline();
    env.wait_cycles(30);
    expected_drop++;
    check_drop("REMOTE_SEQ_MISMATCH", expected_drop, env.vif.drop_cnt);

<<<<<<< HEAD
    // -- Case 7: Missing fragment -- spec section 8.1
    // Send FRAG_NUM 1 and 3 with the same SEQ_NUM, then start a different
    // sequence. The previous packet is incomplete because FRAG_NUM 2 is absent.
=======
    // Case 7: missing remote fragment
>>>>>>> 21f17b6 (Add additional BIRD test files)
    $display("[DROP] Case 7: Missing fragment");
    begin
      bird_packet f1;
      bird_packet f3;
      bird_packet new_seq_f1;
      byte unsigned d_new[];

      env.drop_gen.create_remote_missing_fragment_pair(f1, f3);
<<<<<<< HEAD
      d_new = new[2];
      d_new[0] = 8'hD1;
      d_new[1] = 8'hD2;
=======

      d_new = new[2];
      d_new[0] = 8'hD1;
      d_new[1] = 8'hD2;

>>>>>>> 21f17b6 (Add additional BIRD test files)
      new_seq_f1 = new();
      new_seq_f1.make_remote_fragment(5'd10, 5'd1, d_new);

      env.coverage.sample_packet(f1);
      env.coverage.sample_packet(f3);
      env.coverage.sample_packet(new_seq_f1);
      env.coverage.sample_missing_fragment(1'b1);
<<<<<<< HEAD
      env.driver.drive_packet(f1);
      env.driver.drive_packet(f3);
      env.driver.drive_packet(new_seq_f1);
=======

      env.driver.drive_packet(f1);
      env.driver.drive_packet(f3);
      env.driver.drive_packet(new_seq_f1);

>>>>>>> 21f17b6 (Add additional BIRD test files)
      flush_pipeline();
      env.wait_cycles(30);
      expected_drop++;
      check_drop("MISSING_FRAG", expected_drop, env.vif.drop_cnt);
    end

<<<<<<< HEAD
    // -- Final checks --------------------------------------
    env.wait_cycles(10);
=======
    env.wait_cycles(10);

>>>>>>> 21f17b6 (Add additional BIRD test files)
    if (env.vif.local_vld)
      $error("[DROP] FAIL: local_vld high after all drops");
    else
      $display("[DROP] PASS: no local output from dropped packets");

    if (env.vif.remote_vld)
      $error("[DROP] FAIL: remote_vld high after all drops");
    else
      $display("[DROP] PASS: no remote output from dropped packets");

<<<<<<< HEAD
    $display("[DROP] Total drops this test: %0d (expected ~8)",
=======
    $display("[DROP] Total drops this test: %0d",
>>>>>>> 21f17b6 (Add additional BIRD test files)
             env.vif.drop_cnt - drop_before);

    $display("============================================================");
    $display("TEST END: bird_drop_conditions_test");
    $display("============================================================");
  endtask

endclass

<<<<<<< HEAD
`endif
=======
`endif
>>>>>>> 21f17b6 (Add additional BIRD test files)
