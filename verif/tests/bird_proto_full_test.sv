import bird_pkg::*;

`ifndef BIRD_PROTO_FULL_TEST_SV
`define BIRD_PROTO_FULL_TEST_SV

class bird_proto_full_test;

  bird_env env;

  function new(bird_env env);
    this.env = env;
  endfunction

  task run();
    bird_packet pkt;
    byte unsigned d[];

    $display("============================================================");
    $display("TEST START: bird_proto_full_test");
    $display("============================================================");

    // PRO_001: handshake-gated transfer
    $display("[PROTO_FULL] PRO_001: handshake-gated transfer");
    env.prepare_for_test();
    begin
      bit [15:0] drop_before;

      drop_before = env.vif.drop_cnt;

      d = new[3];
      d[0] = 8'h61;
      d[1] = 8'h62;
      d[2] = 8'h63;

      pkt = new();
      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(20);

      if (env.vif.drop_cnt === drop_before)
        $display("[PROTO_FULL] PASS PRO_001: packet fully and correctly handshaken");
      else
        $error("[PROTO_FULL] FAIL PRO_001: unexpected drop during handshake transfer");
    end

    // PRO_003: cfg sampled on first byte only
    $display("[PROTO_FULL] PRO_003: cfg sampled on first byte only");
    env.prepare_for_test();
    begin
      bit [15:0] drop_before;
      bit [31:0] good_cfg;
      bit [31:0] corrupted_cfg;

      drop_before = env.vif.drop_cnt;

      pkt = new();

      d = new[2];
      d[0] = 8'h71;
      d[1] = 8'h72;

      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);

      good_cfg      = pkt.cfg;
      corrupted_cfg = pkt.cfg | 32'h0000_0002;

      env.driver.drive_input_byte(pkt.payload[0], good_cfg);
      env.driver.drive_input_byte(pkt.payload[1],  corrupted_cfg);
      env.driver.drive_input_byte(pkt.crc16[15:8], corrupted_cfg);
      env.driver.drive_input_byte(pkt.crc16[7:0],  corrupted_cfg);
      env.driver.idle(5);
      env.wait_cycles(20);

      if (env.vif.drop_cnt === drop_before)
        $display("[PROTO_FULL] PASS PRO_003: packet processed using first-byte cfg");
      else
        $error("[PROTO_FULL] FAIL PRO_003: drop_cnt changed after cfg corruption");
    end

    // PRO_013: cfg stable during fragment
    $display("[PROTO_FULL] PRO_013: cfg stability during entire fragment");
    env.prepare_for_test();
    begin
      bit [15:0] drop_before;

      drop_before = env.vif.drop_cnt;

      d = new[4];
      d[0] = 8'h81;
      d[1] = 8'h82;
      d[2] = 8'h83;
      d[3] = 8'h84;

      pkt = new();
      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(20);

      if (env.vif.drop_cnt === drop_before)
        $display("[PROTO_FULL] PASS PRO_013: packet processed correctly with stable cfg");
      else
        $error("[PROTO_FULL] FAIL PRO_013: unexpected drop with stable cfg");
    end

    // PRO_009: reset during local output
    $display("[PROTO_FULL] PRO_009: reset during local output");
    env.prepare_for_test();
    begin
      int timeout;

      env.driver.set_local_ready(1'b0);

      d = new[6];
      foreach (d[i])
        d[i] = byte'(8'h90 + i);

      pkt = new();
      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);

      timeout = 0;
      while (!env.vif.local_vld && (timeout < 60)) begin
        env.wait_cycles(1);
        timeout++;
      end

      if (!env.vif.local_vld) begin
        $error("[PROTO_FULL] FAIL PRO_009: local_vld never asserted");
      end
      else begin
        env.vif.rst_n = 1'b0;
        env.wait_cycles(3);

        if (!env.vif.local_vld)
          $display("[PROTO_FULL] PASS PRO_009: local_vld deasserted after reset");
        else
          $error("[PROTO_FULL] FAIL PRO_009: local_vld still high after reset");
      end

      env.vif.rst_n = 1'b1;
      env.driver.set_local_ready(1'b1);
      env.wait_cycles(5);
      env.prepare_for_test();
    end

    // PRO_010: reset during remote output
    $display("[PROTO_FULL] PRO_010: reset during remote output");
    env.prepare_for_test();
    begin
      int timeout;
      bird_packet frag1;
      bird_packet frag2;
      bird_remote_generator rg;

      rg = new();

      env.driver.set_remote_ready(1'b0);

      frag1 = rg.create_two_fragment_packet_frag1();
      frag2 = rg.create_two_fragment_packet_frag2();

      env.coverage.sample_packet(frag1);
      env.coverage.sample_packet(frag2);

      env.driver.drive_packet(frag1);
      env.driver.drive_packet(frag2);

      timeout = 0;
      while (!env.vif.remote_vld && (timeout < 80)) begin
        env.wait_cycles(1);
        timeout++;
      end

      if (!env.vif.remote_vld) begin
        $error("[PROTO_FULL] FAIL PRO_010: remote_vld never asserted");
      end
      else begin
        env.vif.rst_n = 1'b0;
        env.wait_cycles(3);

        if (!env.vif.remote_vld)
          $display("[PROTO_FULL] PASS PRO_010: remote_vld deasserted after reset");
        else
          $error("[PROTO_FULL] FAIL PRO_010: remote_vld still high after reset");
      end

      env.vif.rst_n = 1'b1;
      env.driver.set_remote_ready(1'b1);
      env.wait_cycles(5);
      env.prepare_for_test();
    end

    // PRO_011: multiple resets in a row
    $display("[PROTO_FULL] PRO_011: multiple resets in a row");
    for (int r = 0; r < 4; r++) begin
      env.vif.rst_n = 1'b0;
      env.wait_cycles(3);

      if (!env.vif.local_vld && !env.vif.remote_vld && (env.vif.drop_cnt == 16'd0))
        $display("[PROTO_FULL] PASS PRO_011[%0d]: reset cleared visible state", r);
      else
        $error("[PROTO_FULL] FAIL PRO_011[%0d]: reset did not clear state", r);

      env.vif.rst_n = 1'b1;
      env.wait_cycles(5);
      env.prepare_for_test();

      d = new[2];
      d[0] = byte'(8'hB0 + r);
      d[1] = byte'(8'hC0 + r);

      pkt = new();
      pkt.make_local(5'd1, d);
      env.coverage.sample_packet(pkt);
      env.driver.drive_packet(pkt);
      env.wait_cycles(20);

      if (env.vif.drop_cnt === 16'd0)
        $display("[PROTO_FULL] PASS PRO_011[%0d]: normal operation resumed after reset", r);
      else
        $error("[PROTO_FULL] FAIL PRO_011[%0d]: unexpected drop after reset recovery", r);
    end

    $display("============================================================");
    $display("TEST END: bird_proto_full_test");
    $display("============================================================");
  endtask

endclass

`endif