// ============================================================
// bird_drop_test_a.sv
// Drop Conditions Test A 
//
// Tests 3 drop conditions from spec 8.1:
//   1. SEQ_NUM = 0
//   2. FRAG_NUM = 0
//   3. PAYLOAD_LEN = 0
//
// For each: send bad packet ? verify drop_cnt increments by 1
//           verify nothing appears on local or remote output
// ============================================================
`ifndef BIRD_DROP_TEST_A_SV
`define BIRD_DROP_TEST_A_SV
 
`include "bird_pkg.sv"
`include "bird_if.sv"
 
import bird_pkg::*;
 
class bird_drop_test_a;
 
  virtual bird_if   vif;
  mailbox #(bird_packet) mbx;
 
  // test results
  int pass_count = 0;
  int fail_count = 0;
 
  function new(virtual bird_if vif, mailbox #(bird_packet) mbx);
    this.vif = vif;
    this.mbx = mbx;
  endfunction
 
 
  // run() — runs all 3 drop condition checks
  
  task run();
    $display("[DROP_A] Starting drop condition tests");
 
    test_seq_num_zero();
    test_frag_num_zero();
    test_payload_len_zero();
 
    // final report
    $display("[DROP_A] Results: %0d PASS, %0d FAIL",
             pass_count, fail_count);
  endtask
 
 
  // TEST 1 — SEQ_NUM = 0
  // spec 8.1: SEQ_NUM==0 ? drop

  task test_seq_num_zero();
    bird_packet pkt;
    bit [15:0] cnt_before;
    bit [15:0] cnt_after;
 
    $display("[DROP_A] Test 1: SEQ_NUM=0");
 
    // read drop_cnt before
    cnt_before = vif.drop_cnt;
 
    // build packet with SEQ_NUM=0 (invalid)
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 0;          // ? invalid, must be dropped
    pkt.frag_num    = 1;
    pkt.payload_len = 4;
    pkt.payload     = new[2];
    pkt.payload[0]  = 8'hAA;
    pkt.payload[1]  = 8'hBB;
   
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);
 
    // send it
    mbx.put(pkt);
 
    // wait for DUT to process
    repeat (30) @(vif.driver_cb);
 
    // read drop_cnt after
    cnt_after = vif.drop_cnt;
 
    // check drop_cnt incremented by 1
    if (cnt_after - cnt_before === 1) begin
      $display("[DROP_A] Test 1 PASS: drop_cnt incremented correctly");
      pass_count++;
    end else begin
      $error("[DROP_A] Test 1 FAIL: drop_cnt before=%0d after=%0d (expected +1)",
             cnt_before, cnt_after);
      fail_count++;
    end
 
    // check nothing on local output
    if (vif.local_vld) begin
      $error("[DROP_A] Test 1 FAIL: local_vld went high (packet should be dropped)");
      fail_count++;
    end else begin
      $display("[DROP_A] Test 1 PASS: local output stayed silent");
      pass_count++;
    end
 
  endtask
 
  
  // TEST 2 — FRAG_NUM = 0
  // spec 8.1: FRAG_NUM==0 ? drop
  
  task test_frag_num_zero();
    
    bird_packet pkt;
    bit [15:0] cnt_before;
    bit [15:0] cnt_after;
    repeat(20) @(vif.driver_cb);
 
    $display("[DROP_A] Test 2: FRAG_NUM=0");
 
    cnt_before = vif.drop_cnt;
 
    // build packet with FRAG_NUM=0 (invalid)
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 0;          // ? invalid, must be dropped
    pkt.payload_len = 4;
    pkt.payload     = new[2];
    pkt.payload[0]  = 8'h11;
    pkt.payload[1]  = 8'h22;
   
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);
 
    mbx.put(pkt);
 
    repeat (50) @(vif.driver_cb);
 
    cnt_after = vif.drop_cnt;
 
    if (cnt_after - cnt_before === 1) begin
      $display("[DROP_A] Test 2 PASS: drop_cnt incremented correctly");
      pass_count++;
    end else begin
      $error("[DROP_A] Test 2 FAIL: drop_cnt before=%0d after=%0d (expected +1)",
             cnt_before, cnt_after);
      fail_count++;
    end
 
    if (vif.local_vld) begin
      $error("[DROP_A] Test 2 FAIL: local_vld went high (packet should be dropped)");
      fail_count++;
    end else begin
      $display("[DROP_A] Test 2 PASS: local output stayed silent");
      pass_count++;
    end
 
  endtask
 
 
  // TEST 3 — PAYLOAD_LEN = 0
  // spec 8.1: PAYLOAD_LEN outside 1-255 ? drop

  task test_payload_len_zero();
    bird_packet pkt;
    bit [15:0] cnt_before;
    bit [15:0] cnt_after;
    
    repeat(20) @(vif.driver_cb);
 
    $display("[DROP_A] Test 3: PAYLOAD_LEN=0");
 
    cnt_before = vif.drop_cnt;
 
    // build packet with PAYLOAD_LEN=0 (invalid)
    // NOTE: payload array is empty because len=0
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 1;
    pkt.payload_len = 0;          // ? invalid, must be dropped
    pkt.payload  = new[1];      // ? 1 dummy byte so DUT reads cfg
    pkt.payload[0] = 8'hFF;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);  // no payload so no real CRC
 
    mbx.put(pkt);
 
    repeat (60) @(vif.driver_cb);
 
    cnt_after = vif.drop_cnt;
 
    if (cnt_after - cnt_before === 1) begin
      $display("[DROP_A] Test 3 PASS: drop_cnt incremented correctly");
      pass_count++;
    end else begin
      $error("[DROP_A] Test 3 FAIL: drop_cnt before=%0d after=%0d (expected +1)",
             cnt_before, cnt_after);
      fail_count++;
    end
 
    if (vif.local_vld) begin
      $error("[DROP_A] Test 3 FAIL: local_vld went high (packet should be dropped)");
      fail_count++;
    end else begin
      $display("[DROP_A] Test 3 PASS: local output stayed silent");
      pass_count++;
    end
 
    // final check — total drop_cnt should be 3 after all tests
    $display("[DROP_A] Final drop_cnt = %0d (expected 3)", vif.drop_cnt);
    if (vif.drop_cnt === 3)
      $display("[DROP_A] PASS: total drop_cnt correct");
    else
      $error("[DROP_A] FAIL: total drop_cnt wrong");
 
  endtask
 
endclass : bird_drop_test_a
 
`endif