import bird_pkg::*;

`ifndef BIRD_LEGACY_EXTRA_TEST_SV
`define BIRD_LEGACY_EXTRA_TEST_SV

class bird_legacy_extra_test;

  bird_env env;
  bird_remote_generator remote_gen;

  function new(bird_env env);
    this.env        = env;
    this.remote_gen = new();
  endfunction

  task test_valid_gaps_on_input_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_INPUT_VALID_GAPS");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[3];
    d[0] = 8'h41;
    d[1] = 8'h42;
    d[2] = 8'h43;

    pkt = new();
    pkt.make_local(5'd18, d);
    env.coverage.sample_packet(pkt);

    env.driver.set_local_ready(1'b0);
    env.driver.drive_input_byte(pkt.payload[0], pkt.cfg);
    env.driver.idle(2);
    env.driver.drive_input_byte(pkt.payload[1], pkt.cfg);
    env.driver.idle(2);
    env.driver.drive_input_byte(pkt.payload[2], pkt.cfg);
    env.driver.idle(2);
    env.driver.drive_input_byte(pkt.crc16[15:8], pkt.cfg);
    env.driver.idle(2);
    env.driver.drive_input_byte(pkt.crc16[7:0], pkt.cfg);
    env.driver.idle(5);
    env.driver.set_local_ready(1'b1);
    env.wait_cycles(40);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_INPUT_VALID_GAPS: drop_cnt unchanged with gapped input");
    else
      $error("[LEGACY] FAIL EXTRA_INPUT_VALID_GAPS: drop_cnt changed unexpectedly");
  endtask

  task test_remote_backpressure_extra();
    bird_packet frag1, frag2;
    byte unsigned d[];
    bit [15:0] drop_before;
    bit [31:0] held_word;
    bit        stable_ok;
    int        timeout;

    $display("[LEGACY] EXTRA_REMOTE_BACKPRESSURE_STABILITY");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'h71;
    d[1] = 8'h72;
    frag1 = remote_gen.create_remote_fragment(5'd19, 5'd1, d);

    d = new[2];
    d[0] = 8'h73;
    d[1] = 8'h74;
    frag2 = remote_gen.create_remote_fragment(5'd19, 5'd2, d);

    env.coverage.sample_packet(frag1);
    env.coverage.sample_packet(frag2);

    env.driver.set_remote_ready(1'b0);
    env.driver.drive_packet(frag1);
    env.driver.drive_packet(frag2);

    timeout = 0;
    while (!env.vif.remote_vld && (timeout < 80)) begin
      env.wait_cycles(1);
      timeout++;
    end

    if (!env.vif.remote_vld) begin
      $error("[LEGACY] FAIL EXTRA_REMOTE_BACKPRESSURE: remote_vld never asserted under backpressure");
    end
    else begin
      held_word = env.vif.data_remote;
      stable_ok = 1'b1;

      repeat (5) begin
        env.wait_cycles(1);
        if (!env.vif.remote_vld || (env.vif.data_remote !== held_word))
          stable_ok = 1'b0;
      end

      if (stable_ok)
        $display("[LEGACY] PASS EXTRA_REMOTE_BACKPRESSURE: data_remote held stable while remote_rdy=0");
      else
        $error("[LEGACY] FAIL EXTRA_REMOTE_BACKPRESSURE: data_remote changed while remote_rdy=0");
    end

    env.driver.set_remote_ready(1'b1);
    env.wait_cycles(30);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_REMOTE_BACKPRESSURE: drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_REMOTE_BACKPRESSURE: drop_cnt changed");
  endtask

  task test_reset_during_local_output_extra();
    bird_packet pkt;
    byte unsigned d[];
    int timeout;

    $display("[LEGACY] EXTRA_RESET_DURING_LOCAL_OUTPUT");
    env.prepare_for_test();

    d = new[3];
    d[0] = 8'h91;
    d[1] = 8'h92;
    d[2] = 8'h93;

    pkt = new();
    pkt.make_local(5'd20, d);
    env.coverage.sample_packet(pkt);

    env.driver.set_local_ready(1'b0);
    env.driver.drive_packet(pkt);

    timeout = 0;
    while (!env.vif.local_vld && (timeout < 60)) begin
      env.wait_cycles(1);
      timeout++;
    end

    env.vif.rst_n = 1'b0;
    env.wait_cycles(4);

    if (!env.vif.local_vld && !env.vif.remote_vld && (env.vif.drop_cnt === 16'd0))
      $display("[LEGACY] PASS EXTRA_RESET_DURING_LOCAL_OUTPUT: outputs and drop_cnt cleared");
    else
      $error("[LEGACY] FAIL EXTRA_RESET_DURING_LOCAL_OUTPUT: reset did not clear visible state");

    env.vif.rst_n = 1'b1;
    env.driver.set_local_ready(1'b1);
    env.wait_cycles(5);
    env.prepare_for_test();

    d = new[2];
    d[0] = 8'hA5;
    d[1] = 8'hA6;

    pkt = new();
    pkt.make_local(5'd21, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === 16'd0)
      $display("[LEGACY] PASS EXTRA_RESET_OUTPUT_RECOVERY: normal operation resumed");
    else
      $error("[LEGACY] FAIL EXTRA_RESET_OUTPUT_RECOVERY: unexpected drop after recovery");
  endtask

  task test_local_min_len_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;
    bit        remote_seen;

    $display("[LEGACY] EXTRA_LOCAL_MIN_LEN");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;
    remote_seen = 1'b0;

    d = new[1];
    d[0] = 8'h5A;

    pkt = new();
    pkt.make_local(5'd1, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    repeat (10) begin
      env.wait_cycles(1);
      if (env.vif.remote_vld)
        remote_seen = 1'b1;
    end

    if (!remote_seen)
      $display("[LEGACY] PASS EXTRA_LOCAL_MIN_LEN: remote_vld stayed low for local packet");
    else
      $error("[LEGACY] FAIL EXTRA_LOCAL_MIN_LEN: remote_vld asserted for local packet");

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_LOCAL_MIN_LEN: drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_LOCAL_MIN_LEN: drop_cnt changed");
  endtask

  task test_local_payload_len_sweep_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_LOCAL_PAYLOAD_LEN_SWEEP (1..8 bytes)");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    for (int len = 1; len <= 8; len++) begin
      d = new[len];

      for (int i = 0; i < len; i++)
        d[i] = byte'(8'h20 + len + i);

      pkt = new();
      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(15);
    end

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_LOCAL_PAYLOAD_LEN_SWEEP: all lengths forwarded, drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_LOCAL_PAYLOAD_LEN_SWEEP: drop_cnt changed, delta=%0d",
             env.vif.drop_cnt - drop_before);
  endtask

  task test_local_seq_sweep_spec_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;
    int pass_count;

    $display("[LEGACY] EXTRA_LOCAL_SEQ_SWEEP (seq 1..5)");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;
    pass_count  = 0;

    d = new[2];
    d[0] = 8'hC0;
    d[1] = 8'hC1;

    for (int seq = 1; seq <= 5; seq++) begin
      pkt = new();
      pkt.make_local(seq[4:0], d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(15);

      if (env.vif.drop_cnt === drop_before) begin
        $display("[LEGACY] PASS EXTRA_LOCAL_SEQ_%0d: forwarded correctly", seq);
        pass_count++;
      end
      else begin
        $error("[LEGACY] FAIL EXTRA_LOCAL_SEQ_%0d: dropped, delta=%0d",
               seq, env.vif.drop_cnt - drop_before);
        drop_before = env.vif.drop_cnt;
      end
    end

    if (pass_count == 5)
      $display("[LEGACY] PASS EXTRA_LOCAL_SEQ_SWEEP: all 5 SEQ_NUM values forwarded");
    else
      $display("[LEGACY] NOTE EXTRA_LOCAL_SEQ_SWEEP: only %0d/5 SEQ_NUM values forwarded",
               pass_count);
  endtask

  task test_reserved_bit_fields_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_RESERVED_BIT_FIELDS");

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'h12;
    d[1] = 8'h34;

    pkt = new();
    pkt.make_local(5'd1, d);
    pkt.rsvd_7_1 = 7'h01;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[LEGACY] PASS EXTRA_DROP_RSVD_7_1: dropped as expected");
    else
      $error("[LEGACY] FAIL EXTRA_DROP_RSVD_7_1: expected +1 drop, delta=%0d",
             env.vif.drop_cnt - drop_before);

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    pkt = new();
    pkt.make_local(5'd1, d);
    pkt.rsvd_23_21 = 3'h1;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[LEGACY] PASS EXTRA_DROP_RSVD_23_21: dropped as expected");
    else
      $error("[LEGACY] FAIL EXTRA_DROP_RSVD_23_21: expected +1 drop, delta=%0d",
             env.vif.drop_cnt - drop_before);

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    pkt = new();
    pkt.make_local(5'd1, d);
    pkt.rsvd_31_29 = 3'h1;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[LEGACY] PASS EXTRA_DROP_RSVD_31_29: dropped as expected");
    else
      $error("[LEGACY] FAIL EXTRA_DROP_RSVD_31_29: expected +1 drop, delta=%0d",
             env.vif.drop_cnt - drop_before);
  endtask

  task test_cfg_boundary_values_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_CFG_BOUNDARY_VALUES");

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'h31;
    d[1] = 8'h32;

    pkt = new();
    pkt.make_local(5'd31, d);
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_LOCAL_SEQ_MAX: SEQ_NUM=31 accepted");
    else
      $error("[LEGACY] FAIL EXTRA_LOCAL_SEQ_MAX: SEQ_NUM=31 unexpectedly dropped");

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    pkt = new();
    pkt.make_local(5'd1, d);
    pkt.seq_num = 5'd0;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[LEGACY] PASS EXTRA_DROP_SEQ_ZERO_BOUNDARY");
    else
      $error("[LEGACY] FAIL EXTRA_DROP_SEQ_ZERO_BOUNDARY: delta=%0d",
             env.vif.drop_cnt - drop_before);

    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    pkt = remote_gen.create_remote_fragment(5'd2, 5'd1, d);
    pkt.frag_num = 5'd0;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === (drop_before + 16'd1))
      $display("[LEGACY] PASS EXTRA_DROP_FRAG_ZERO_BOUNDARY");
    else
      $error("[LEGACY] FAIL EXTRA_DROP_FRAG_ZERO_BOUNDARY: delta=%0d",
             env.vif.drop_cnt - drop_before);
  endtask

  task test_multiple_bad_packets_extra();
    bird_packet pkt;
    byte unsigned d[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_MULTIPLE_BAD_PACKETS_DROP_COUNT");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d = new[2];
    d[0] = 8'hD0;
    d[1] = 8'hD1;

    pkt = new();
    pkt.make_local(5'd1, d);
    pkt.seq_num = 5'd0;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(10);

    pkt = remote_gen.create_remote_fragment(5'd3, 5'd1, d);
    pkt.frag_num = 5'd0;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(10);

    pkt = new();
    pkt.make_local(5'd3, d);
    pkt.frag_num = 5'd2;
    pkt.finalize_packet();
    env.coverage.sample_packet(pkt);
    env.driver.drive_packet(pkt);
    env.wait_cycles(15);

    if (env.vif.drop_cnt === (drop_before + 16'd3))
      $display("[LEGACY] PASS EXTRA_MULTIPLE_BAD_PACKETS: drop_cnt incremented once per dropped packet");
    else
      $error("[LEGACY] FAIL EXTRA_MULTIPLE_BAD_PACKETS: expected +3, got delta=%0d",
             env.vif.drop_cnt - drop_before);

    if (!env.vif.local_vld && !env.vif.remote_vld)
      $display("[LEGACY] PASS EXTRA_MULTIPLE_BAD_PACKETS: no outputs from bad packets");
    else
      $error("[LEGACY] FAIL EXTRA_MULTIPLE_BAD_PACKETS: unexpected output asserted");
  endtask

  task test_remote_three_frag_inorder_extra();
    bird_packet f1, f2, f3;
    byte unsigned d1[], d2[], d3[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_REMOTE_3FRAG_INORDER");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d1 = new[1];
    d1[0] = 8'hA1;

    d2 = new[2];
    d2[0] = 8'hB1;
    d2[1] = 8'hB2;

    d3 = new[3];
    d3[0] = 8'hC1;
    d3[1] = 8'hC2;
    d3[2] = 8'hC3;

    f1 = remote_gen.create_remote_fragment(5'd14, 5'd1, d1);
    f2 = remote_gen.create_remote_fragment(5'd14, 5'd2, d2);
    f3 = remote_gen.create_remote_fragment(5'd14, 5'd3, d3);

    env.coverage.sample_packet(f1);
    env.coverage.sample_packet(f2);
    env.coverage.sample_packet(f3);

    env.driver.set_remote_ready(1'b0);
    env.driver.drive_packet(f1);
    env.driver.drive_packet(f2);
    env.driver.drive_packet(f3);
    env.driver.set_remote_ready(1'b1);
    env.wait_cycles(40);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_REMOTE_3FRAG_INORDER: drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_REMOTE_3FRAG_INORDER: drop_cnt changed");
  endtask

  task test_remote_three_frag_out_of_order_extra();
    bird_packet f1, f2, f3;
    byte unsigned d1[], d2[], d3[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_REMOTE_3FRAG_REORDER");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d1 = new[2];
    d1[0] = 8'h11;
    d1[1] = 8'h12;

    d2 = new[1];
    d2[0] = 8'h21;

    d3 = new[2];
    d3[0] = 8'h31;
    d3[1] = 8'h32;

    f1 = remote_gen.create_remote_fragment(5'd15, 5'd1, d1);
    f2 = remote_gen.create_remote_fragment(5'd15, 5'd2, d2);
    f3 = remote_gen.create_remote_fragment(5'd15, 5'd3, d3);

    env.coverage.sample_packet(f3);
    env.coverage.sample_packet(f1);
    env.coverage.sample_packet(f2);
    env.coverage.sample_reorder(1'b1);

    env.driver.drive_packet(f3);
    env.driver.drive_packet(f1);
    env.driver.drive_packet(f2);
    env.wait_cycles(40);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_REMOTE_3FRAG_REORDER: drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_REMOTE_3FRAG_REORDER: drop_cnt changed");
  endtask

  task test_remote_two_consecutive_packets_extra();
    bird_packet p1, p2;
    byte unsigned d1[], d2[];
    bit [15:0] drop_before;

    $display("[LEGACY] EXTRA_REMOTE_TWO_CONSECUTIVE_PACKETS");
    env.prepare_for_test();
    drop_before = env.vif.drop_cnt;

    d1 = new[2];
    d1[0] = 8'hE1;
    d1[1] = 8'hE2;

    p1 = remote_gen.create_remote_fragment(5'd16, 5'd1, d1);
    env.coverage.sample_packet(p1);
    env.driver.drive_packet(p1);
    env.wait_cycles(20);

    d2 = new[3];
    d2[0] = 8'hF1;
    d2[1] = 8'hF2;
    d2[2] = 8'hF3;

    p2 = remote_gen.create_remote_fragment(5'd17, 5'd1, d2);
    env.coverage.sample_packet(p2);
    env.driver.drive_packet(p2);
    env.wait_cycles(20);

    if (env.vif.drop_cnt === drop_before)
      $display("[LEGACY] PASS EXTRA_REMOTE_TWO_CONSECUTIVE: drop_cnt unchanged");
    else
      $error("[LEGACY] FAIL EXTRA_REMOTE_TWO_CONSECUTIVE: drop_cnt changed");
  endtask

  task run();
    $display("============================================================");
    $display("TEST START: bird_legacy_extra_test");
    $display("============================================================");

    test_valid_gaps_on_input_extra();
    test_remote_backpressure_extra();
    test_reset_during_local_output_extra();

    test_local_min_len_extra();
    test_local_payload_len_sweep_extra();
    test_local_seq_sweep_spec_extra();

    test_reserved_bit_fields_extra();
    test_cfg_boundary_values_extra();
    test_multiple_bad_packets_extra();

    test_remote_three_frag_inorder_extra();
    test_remote_three_frag_out_of_order_extra();
    test_remote_two_consecutive_packets_extra();

    $display("============================================================");
    $display("TEST END: bird_legacy_extra_test");
    $display("============================================================");
  endtask

endclass

`endif