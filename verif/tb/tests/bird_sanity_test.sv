//Step 1: Build a known packet
//        payload = AA BB CC DD
//        type    = LOCAL
//        seq_num = 1
//        frag_num = 1
//
//Step 2: Put it in the mailbox
//        ? driver picks it up
//        ? driver drives it into DUT byte by byte
//
//Step 3: Wait and watch local output
//        ? wait for local_vld to go high
//        ? capture every byte that comes out
//
//Step 4: Three checks
//        ? Did we get the right bytes?
//        ? Is drop_cnt still 0?
//        ? Did remote_vld stay 0?


`ifndef BIRD_SANITY_TEST_SV
`define BIRD_SANITY_TEST_SV

`include "bird_if.sv"
`include "bird_pkg.sv"

import bird_pkg::*;

class bird_sanity_test;

 virtual bird_if vif;
 mailbox #(bird_packet) mbx;
 
 function new(virtual bird_if vif,mailbox #(bird_packet) mbx);
  this.vif=vif;
  this.mbx=mbx;
 endfunction
 
  

//run task
 task run();
 
  bird_packet pkt = new();
 
    // set fields manually so we know exactly what to expect
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;          // must be 1 for local (DUT rule)
    pkt.frag_num    = 1;          // must be 1 for local (DUT rule)
    pkt.payload_len = 4;          // 4 bytes — easy to verify
    pkt.payload     = new[4];
    pkt.payload[0]  = 8'hAA;
    pkt.payload[1]  = 8'hBB;
    pkt.payload[2]  = 8'hCC;
    pkt.payload[3]  = 8'hDD;
 
    // build cfg word and compute CRC
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);
 
    // print what we are sending
    $display("[SANITY] Sending local packet:");
    $display("[SANITY]   payload = AA BB CC DD");
    $display("[SANITY]   crc16   = 0x%04h", pkt.crc16);
    $display("[SANITY]   cfg     = 0x%08h", pkt.cfg_word);
 
    // ---------- Step 2: put packet in mailbox ---------------
    // driver will pick it up and drive the signals
    mbx.put(pkt);
 
    // ---------- Step 3: wait and capture local output -------
    capture_and_check(pkt);
 
  endtask
 
  // --------------------------------------------------------
  // capture_and_check()
  // Waits for local_vld, captures all bytes, compares
  // --------------------------------------------------------
  task capture_and_check(bird_packet pkt);
 
    // bytes we capture from local output
    bit [7:0] captured [$];
    bit [7:0] b;
 
    // expected = payload bytes + CRC high + CRC low
    bit [7:0] expected [$];
    foreach (pkt.payload[i])
      expected.push_back(pkt.payload[i]);
    expected.push_back(pkt.crc16[15:8]);
    expected.push_back(pkt.crc16[7:0]);
 
    // --- wait for local_vld to go high (max 50 cycles) ---
    begin
      int timeout = 0;
      while (!vif.local_cb.local_vld) begin
        @(vif.local_cb);
        timeout++;
        if (timeout > 50) begin
          $error("[SANITY] FAIL: local_vld never went high (timeout)");
          return;
        end
      end
    end
 
    // --- capture bytes while local_vld is high ---
    while (vif.local_cb.local_vld) begin
      // transfer happens when vld=1 AND rdy=1
      if (vif.local_cb.local_rdy) begin
        captured.push_back(vif.local_cb.data_local);
      end
      @(vif.local_cb);
    end
 
    // --- compare captured vs expected ---
    $display("[SANITY] Captured %0d bytes, expected %0d bytes",
             captured.size(), expected.size());
 
    // check size
    if (captured.size() !== expected.size()) begin
      $error("[SANITY] FAIL: size mismatch — got %0d expected %0d",
             captured.size(), expected.size());
      return;
    end
 
    // check each byte
    begin
      bit all_match = 1;
      foreach (captured[i]) begin
        if (captured[i] !== expected[i]) begin
          $error("[SANITY] FAIL: byte[%0d] got 0x%02h expected 0x%02h",
                 i, captured[i], expected[i]);
          all_match = 0;
        end
      end
      if (all_match)
        $display("[SANITY] PASS: all %0d bytes match", captured.size());
    end
 
    // check drop_cnt stayed at 0
    if (vif.driver_cb.drop_cnt !== 0)
      $error("[SANITY] FAIL: drop_cnt = %0d (expected 0)", vif.driver_cb.drop_cnt);
    else
      $display("[SANITY] PASS: drop_cnt = 0");
 
    // check remote_vld never went high
    if (vif.remote_cb.remote_vld)
      $error("[SANITY] FAIL: remote_vld went high for a local packet");
    else
      $display("[SANITY] PASS: remote_vld stayed 0");
 
  endtask
 
endclass : bird_sanity_test
 
`endif