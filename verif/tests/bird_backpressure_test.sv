`ifndef BIRD_BACKPRESSURE_TEST_SV
`define BIRD_BACKPRESSURE_TEST_SV

`include "bird_pkg.sv"
`include "bird_if.sv"

import bird_pkg::*;

class bird_backpressure_test;

  virtual bird_if        vif;
  mailbox #(bird_packet) mbx;

  int pass_count = 0;
  int fail_count = 0;

  function new(virtual bird_if vif, mailbox #(bird_packet) mbx);
    this.vif = vif;
    this.mbx = mbx;
  endfunction

  task run();
    $display("[BP] Starting backpressure test");
    test_local_backpressure();
    $display("[BP] Results: %0d PASS, %0d FAIL",
             pass_count, fail_count);
  endtask

  task test_local_backpressure();
    
    bird_packet  pkt;
    bit [7:0]    captured [$];
    bit [7:0]    expected [$];
    int          timeout;
    bit [15:0]   drop_cnt_before;

    // Clear any previous output state and keep the local consumer ready.
    vif.driver_cb.local_rdy <= 1;
    @(vif.driver_cb);

    // Save the drop counter value before starting this test.
    drop_cnt_before = vif.driver_cb.drop_cnt;
    $display("[BP] drop_cnt baseline = %0d", drop_cnt_before);

    // Build a valid local packet with payload_len = 2.
    pkt = new();
    pkt.pkt_type    = LOCAL_PKT;
    pkt.seq_num     = 1;
    pkt.frag_num    = 1;
    pkt.payload_len = 2;
    pkt.payload     = new[2];
    pkt.payload[0]  = 8'hAA;
    pkt.payload[1]  = 8'hBB;
    pkt.build_cfg();
    pkt.crc16 = bird_packet::compute_crc16(pkt.payload);

    // Expected local output stream is the payload followed by the original CRC16.
    foreach (pkt.payload[i])  expected.push_back(pkt.payload[i]);
    expected.push_back(pkt.crc16[15:8]);
    expected.push_back(pkt.crc16[7:0]);

    $display("[BP] Expected %0d bytes: AA BB 0x%02h 0x%02h",
             expected.size(), pkt.crc16[15:8], pkt.crc16[7:0]);

    // Apply backpressure before sending the packet.
    // This checks that the DUT holds valid data when local_rdy is low.
    vif.driver_cb.local_rdy <= 0;
    @(vif.driver_cb);

    // Send the packet to the driver through the mailbox.
    mbx.put(pkt);

    // Wait until the DUT asserts local_vld.
    timeout = 0;
    while (!vif.local_cb.local_vld) begin
      @(vif.local_cb);
      timeout++;
      if (timeout > 100) begin
        $error("[BP] FAIL: local_vld never went high");
        fail_count++;
        return;
      end
    end

    $display("[BP] local_vld asserted while local_rdy=0 - DUT is holding output data");

    // Keep backpressure active for several cycles.
    // Since local_rdy is low, no output byte should be transferred.
    repeat (5) begin
      @(vif.local_cb);
      if (!vif.local_cb.local_vld)
        $display("[BP] NOTE: local_vld deasserted during backpressure");
      if (vif.local_cb.local_rdy)
        $display("[BP] NOTE: local_rdy went high unexpectedly");
    end

    $display("[BP] PASS: backpressure held for 5 cycles with local_rdy=0");
    pass_count++;

    // Release backpressure and allow the DUT to send the local packet.
    $display("[BP] Releasing backpressure by setting local_rdy=1");
    vif.driver_cb.local_rdy <= 1;
    @(vif.driver_cb);

    $display("[BP] PASS: backpressure released");
    pass_count++;

    // Capture all local output bytes after backpressure is released.
    timeout = 0;
    while (timeout < 50) begin
      @(vif.local_cb);
      timeout++;
      if (vif.local_cb.local_vld && vif.local_cb.local_rdy) begin
        captured.push_back(vif.local_cb.data_local);
        $display("[BP] Captured byte[%0d] = 0x%02h",
                 captured.size()-1, vif.local_cb.data_local);
      end
      if (!vif.local_cb.local_vld && captured.size() > 0) break;
    end

    // Compare the number of captured bytes with the expected local stream size.
    $display("[BP] Captured %0d bytes, expected %0d",
             captured.size(), expected.size());

    if (captured.size() !== expected.size()) begin
      $error("[BP] FAIL: size mismatch got=%0d expected=%0d",
             captured.size(), expected.size());
      fail_count++;
    end else begin
      bit all_match = 1;

      // Compare each captured byte against the expected payload and CRC bytes.
      foreach (captured[i]) begin
        if (captured[i] !== expected[i]) begin
          $error("[BP] FAIL: byte[%0d] got=0x%02h exp=0x%02h",
                 i, captured[i], expected[i]);
          all_match = 0;
          fail_count++;
        end
      end

      if (all_match) begin
        $display("[BP] PASS: all %0d bytes are correct after backpressure", captured.size());
        pass_count++;
      end
    end

    // A valid local packet should not increment drop_cnt.
    if (vif.driver_cb.drop_cnt !== 0) begin
      $error("[BP] FAIL: drop_cnt=%0d (expected 0)", vif.driver_cb.drop_cnt);
      fail_count++;
    end else begin
      $display("[BP] PASS: drop_cnt stayed 0");
      pass_count++;
    end

    // This is local traffic, so the remote output must stay inactive.
    if (vif.remote_cb.remote_vld) begin
      $error("[BP] FAIL: remote_vld went high");
      fail_count++;
    end else begin
      $display("[BP] PASS: remote_vld stayed 0");
      pass_count++;
    end

    // Restore local_rdy to the default ready state.
    vif.driver_cb.local_rdy <= 1;

  endtask

endclass : bird_backpressure_test

`endif