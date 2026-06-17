RD_RESET_TEST_SV
`define BIRD_RESET_TEST_SV

`include "bird_pkg.sv"
`include "bird_if.sv"
import bird_pkg::*;

class bird_reset_test;

  virtual bird_if    vif;
  mailbox #(bird_packet) mbx;

  int pass_count = 0;
  int fail_count = 0;

  function new(virtual bird_if vif, mailbox #(bird_packet) mbx);
    this.vif = vif;
    this.mbx = mbx;
  endfunction

  task run();
    $display("[RESET_TEST] Starting reset tests");

    test_basic_reset();
    test_reset_mid_packet();
    test_reset_clears_drop_cnt();
    test_reset_recovery();
    test_reset_local_output();
    test_reset_remote_output();
    test_multiple_resets();
    test_in_rdy_during_reset();

    $display("[RESET_TEST] Results: %0d PASS, %0d FAIL", pass_count, fail_count);
  endtask

  // PRO_005 - Basic reset behavior
  task test_basic_reset();
    $display("[RESET_TEST] PRO_005: Basic reset behavior");

    // assert reset
    vif.driver_cb.rst_n <= 0;
    repeat (5) @(vif.driver_cb);

    // check all outputs deasserted during reset
    if (vif.local_cb.local_vld !== 0) begin
      $error("[RESET_TEST] PRO_005 FAIL: local_vld not 0 during reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_005 PASS: local_vld = 0 during reset");
      pass_count++;
    end

    if (vif.remote_cb.remote_vld !== 0) begin
      $error("[RESET_TEST] PRO_005 FAIL: remote_vld not 0 during reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_005 PASS: remote_vld = 0 during reset");
      pass_count++;
    end

    if (vif.drop_cnt !== 0) begin
      $error("[RESET_TEST] PRO_005 FAIL: drop_cnt not 0 during reset, got %0d", vif.drop_cnt);
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_005 PASS: drop_cnt = 0 during reset");
      pass_count++;
    end

    // release reset
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // check outputs still deasserted after reset
    if (vif.local_cb.local_vld !== 0) begin
      $error("[RESET_TEST] PRO_005 FAIL: local_vld not 0 after reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_005 PASS: local_vld = 0 after reset");
      pass_count++;
    end

    $display("[RESET_TEST] PRO_005 Done");
  endtask

  // PRO_006 - Reset mid-packet
  task test_reset_mid_packet();
    bird_packet pkt;
    $display("[RESET_TEST] PRO_006: Reset mid-packet");

    // make sure reset is released
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // start sending a remote fragment
    pkt = new();
    pkt.pkt_type    = REMOTE_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 1;
    pkt.payload_len = 8;
    pkt.payload     = new[8];
    foreach (pkt.payload[i]) pkt.payload[i] = i;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);

    // drive cfg and first 2 bytes manually
    vif.driver_cb.cfg     <= pkt.cfg_word;
    vif.driver_cb.in_vld  <= 1;
    vif.driver_cb.data_in <= pkt.payload[0];
    @(vif.driver_cb);

    vif.driver_cb.data_in <= pkt.payload[1];
    @(vif.driver_cb);

    // assert reset mid-packet
    vif.driver_cb.rst_n  <= 0;
    vif.driver_cb.in_vld <= 0;
    repeat (3) @(vif.driver_cb);

    // check all outputs cleared
    if (vif.local_cb.local_vld !== 0) begin
      $error("[RESET_TEST] PRO_006 FAIL: local_vld not 0 after mid-packet reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_006 PASS: local_vld = 0 after mid-packet reset");
      pass_count++;
    end

    if (vif.remote_cb.remote_vld !== 0) begin
      $error("[RESET_TEST] PRO_006 FAIL: remote_vld not 0 after mid-packet reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_006 PASS: remote_vld = 0 after mid-packet reset");
      pass_count++;
    end

    if (vif.drop_cnt !== 0) begin
      $error("[RESET_TEST] PRO_006 FAIL: drop_cnt not 0 after reset, got %0d", vif.drop_cnt);
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_006 PASS: drop_cnt = 0 after reset");
      pass_count++;
    end

    // release reset
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    $display("[RESET_TEST] PRO_006 Done");
  endtask

  // PRO_007 - Reset clears drop_cnt
  task test_reset_clears_drop_cnt();
    bird_packet pkt;
    bit [15:0] cnt_before;
    $display("[RESET_TEST] PRO_007: Reset clears drop_cnt");

    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // send a bad packet to increment drop_cnt
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 0; // invalid → drop
    pkt.frag_num    = 1;
    pkt.payload_len = 4;
    pkt.payload     = new[4];
    pkt.payload[0]  = 8'hAA;
    pkt.payload[1]  = 8'hBB;
    pkt.payload[2]  = 8'hCC;
    pkt.payload[3]  = 8'hDD;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);

    mbx.put(pkt);
    repeat (30) @(vif.driver_cb);

    // verify drop_cnt incremented
    if (vif.drop_cnt == 0) begin
      $error("[RESET_TEST] PRO_007 FAIL: drop_cnt did not increment before reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_007 PASS: drop_cnt = %0d before reset", vif.drop_cnt);
      pass_count++;
    end

    // assert reset
    vif.driver_cb.rst_n <= 0;
    repeat (3) @(vif.driver_cb);

    // check drop_cnt cleared
    if (vif.drop_cnt !== 0) begin
      $error("[RESET_TEST] PRO_007 FAIL: drop_cnt not cleared after reset, got %0d", vif.drop_cnt);
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_007 PASS: drop_cnt = 0 after reset");
      pass_count++;
    end

    // release reset
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    $display("[RESET_TEST] PRO_007 Done");
  endtask

  // PRO_008 - Normal operation resumes after reset
  task test_reset_recovery();
    bird_packet pkt;
    $display("[RESET_TEST] PRO_008: Normal operation resumes after reset");

    // assert then release reset
    vif.driver_cb.rst_n <= 0;
    repeat (3) @(vif.driver_cb);
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // send valid local packet
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 1;
    pkt.payload_len = 4;
    pkt.payload     = new[4];
    pkt.payload[0]  = 8'hAA;
    pkt.payload[1]  = 8'hBB;
    pkt.payload[2]  = 8'hCC;
    pkt.payload[3]  = 8'hDD;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);

    mbx.put(pkt);

    // wait and check local_vld goes high
    begin
      int timeout = 0;
      while (!vif.local_cb.local_vld) begin
        @(vif.local_cb);
        timeout++;
        if (timeout > 50) begin
          $error("[RESET_TEST] PRO_008 FAIL: local_vld never went high after reset");
          fail_count++;
          return;
        end
      end
    end

    $display("[RESET_TEST] PRO_008 PASS: BIRD accepted packet after reset");
    pass_count++;

    // check drop_cnt still 0
    if (vif.drop_cnt !== 0) begin
      $error("[RESET_TEST] PRO_008 FAIL: drop_cnt not 0 after valid packet");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_008 PASS: drop_cnt = 0");
      pass_count++;
    end

    $display("[RESET_TEST] PRO_008 Done");
  endtask

  // PRO_009 - Reset while outputting on local interface
  task test_reset_local_output();
    bird_packet pkt;
    $display("[RESET_TEST] PRO_009: Reset while outputting on local interface");

    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // send valid local packet
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 1;
    pkt.payload_len = 10;
    pkt.payload     = new[10];
    foreach (pkt.payload[i]) pkt.payload[i] = i;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);

    // hold local_rdy low so output stays active longer
    vif.driver_cb.local_rdy <= 0;
    mbx.put(pkt);
    repeat (5) @(vif.driver_cb);

    // assert reset mid-output
    vif.driver_cb.rst_n <= 0;
    repeat (2) @(vif.driver_cb);

    // check local_vld deasserted
    if (vif.local_cb.local_vld !== 0) begin
      $error("[RESET_TEST] PRO_009 FAIL: local_vld still high during reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_009 PASS: local_vld deasserted during reset");
      pass_count++;
    end

    // release reset and restore local_rdy
    vif.driver_cb.rst_n   <= 1;
    vif.driver_cb.local_rdy <= 1;
    repeat (2) @(vif.driver_cb);

    $display("[RESET_TEST] PRO_009 Done");
  endtask

  // PRO_010 - Reset while outputting on remote interface
  task test_reset_remote_output();
    $display("[RESET_TEST] PRO_010: Reset while outputting on remote interface");

    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // hold remote_rdy low
    vif.driver_cb.remote_rdy <= 0;
    repeat (3) @(vif.driver_cb);

    // assert reset
    vif.driver_cb.rst_n <= 0;
    repeat (2) @(vif.driver_cb);

    // check remote_vld deasserted
    if (vif.remote_cb.remote_vld !== 0) begin
      $error("[RESET_TEST] PRO_010 FAIL: remote_vld still high during reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_010 PASS: remote_vld deasserted during reset");
      pass_count++;
    end

    // release reset and restore remote_rdy
    vif.driver_cb.rst_n    <= 1;
    vif.driver_cb.remote_rdy <= 1;
    repeat (2) @(vif.driver_cb);

    $display("[RESET_TEST] PRO_010 Done");
  endtask

  // PRO_011 - Multiple resets in a row
  task test_multiple_resets();
    $display("[RESET_TEST] PRO_011: Multiple resets in a row");

    repeat (3) begin
      // assert reset
      vif.driver_cb.rst_n <= 0;
      repeat (3) @(vif.driver_cb);

      // check outputs
      if (vif.local_cb.local_vld !== 0 || vif.remote_cb.remote_vld !== 0 || vif.drop_cnt !== 0) begin
        $error("[RESET_TEST] PRO_011 FAIL: outputs not cleared during reset");
        fail_count++;
      end else begin
        $display("[RESET_TEST] PRO_011 PASS: outputs cleared during reset");
        pass_count++;
      end

      // release reset
      vif.driver_cb.rst_n <= 1;
      repeat (2) @(vif.driver_cb);
    end

    $display("[RESET_TEST] PRO_011 Done");
  endtask

  // PRO_012 - in_rdy behavior during reset
  task test_in_rdy_during_reset();
    $display("[RESET_TEST] PRO_012: in_rdy behavior during reset");

    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // assert reset
    vif.driver_cb.rst_n <= 0;
    repeat (2) @(vif.driver_cb);

    // check in_rdy deasserted during reset
    if (vif.driver_cb.in_rdy !== 0) begin
      $error("[RESET_TEST] PRO_012 FAIL: in_rdy still high during reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_012 PASS: in_rdy deasserted during reset");
      pass_count++;
    end

    // release reset
    vif.driver_cb.rst_n <= 1;
    repeat (2) @(vif.driver_cb);

    // check in_rdy reasserts after reset
    if (vif.driver_cb.in_rdy !== 1) begin
      $error("[RESET_TEST] PRO_012 FAIL: in_rdy not reasserted after reset");
      fail_count++;
    end else begin
      $display("[RESET_TEST] PRO_012 PASS: in_rdy reasserted after reset");
      pass_count++;
    end

    $display("[RESET_TEST] PRO_012 Done");
  endtask

endclass : bird_reset_test

`endif

