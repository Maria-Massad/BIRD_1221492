// ============================================================
// bird_in_monitor.sv   (M3)   -- NON-UVM, bird_packet based
//
// Watches the INPUT interface and reconstructs each observed
// fragment into a bird_packet, then BROADCASTS a copy to every
// registered subscriber mailbox (e.g. a scoreboard and the
// functional coverage collector).
//
// One observed fragment = one bird_packet:
//   - cfg sampled on the SAME cycle as the first payload byte (spec 2.3)
//   - PAYLOAD_LEN payload bytes on data_in
//   - 2 trailing CRC bytes on data_in (MSB then LSB)
//
// Subscribers register via add_subscriber(mbx). The monitor
// puts a .copy() of each observed packet into every subscriber
// so consumers never share/clobber the same handle.
//
// Input side is sampled directly at posedge clk because the
// interface has no input-side monitor clocking block.
// ============================================================
`ifndef BIRD_IN_MONITOR_SV
`define BIRD_IN_MONITOR_SV

`include "bird_if.sv"
`include "bird_pkg.sv"

import bird_pkg::*;

class bird_in_monitor;

  // Virtual interface handle (set by the agent/env at construction)
  virtual bird_if vif;

  // List of subscriber mailboxes; one copy of each packet goes to each
  mailbox #(bird_packet) subscribers[$];

  // simple counter for debug / end-of-test reporting
  int unsigned num_observed = 0;

  function new(virtual bird_if vif);
    this.vif = vif;
  endfunction

  // ----------------------------------------------------------
  // add_subscriber() - register a mailbox to receive observed
  // input fragments. Called by the env/agent during build.
  // ----------------------------------------------------------
  function void add_subscriber(mailbox #(bird_packet) mbx);
    subscribers.push_back(mbx);
  endfunction

  // ----------------------------------------------------------
  // broadcast() - send a copy of the observed packet to every
  // registered subscriber.
  // ----------------------------------------------------------
  function void broadcast(bird_packet pkt);
    foreach (subscribers[i]) begin
      subscribers[i].put(pkt.copy());
    end
  endfunction

  // ----------------------------------------------------------
  // run() - main collection loop. Call this in a fork/join_none
  // from the testbench (like the driver's run()).
  // ----------------------------------------------------------
  task run();
    // Wait until we are out of reset before collecting.
    @(posedge vif.clk);
    forever begin
      // Honour reset: drop partial state and wait for deassertion.
      if (vif.rst_n === 1'b0) begin
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
      end
      collect_fragment();
    end
  endtask

  // ----------------------------------------------------------
  // collect_fragment() - observe one input fragment and build
  // a bird_packet, then broadcast it.
  // ----------------------------------------------------------
  task collect_fragment();
    bird_packet      tr;
    bit [31:0]       cfg_sampled;
    int unsigned     plen;
    bit [7:0]        payload_q[$];
    bit [7:0]        crc_msb, crc_lsb;

    // 1) First payload byte + cfg ------------------------------
    // Wait for the first valid transfer of this fragment.
    do begin
      @(posedge vif.clk);
      if (vif.rst_n === 1'b0) return;   // reset aborts cleanly
    end while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1));

    // cfg sampled on the same cycle as the first payload byte (spec 2.3)
    cfg_sampled = vif.cfg;
    plen        = vif.cfg[15:8];        // PAYLOAD_LEN field
    payload_q.delete();
    payload_q.push_back(vif.data_in);   // first payload byte

    // 2) Remaining payload bytes -------------------------------
    // Already captured 1 byte; collect (plen - 1) more.
    if (plen >= 1) begin
      for (int i = 1; i < plen; i++) begin
        @(posedge vif.clk);
        if (vif.rst_n === 1'b0) return;
        while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1)) begin
          @(posedge vif.clk);
          if (vif.rst_n === 1'b0) return;
        end
        payload_q.push_back(vif.data_in);
      end
    end

    // 3) Two CRC bytes (MSB then LSB) --------------------------
    collect_one_byte(crc_msb);
    if (vif.rst_n === 1'b0) return;
    collect_one_byte(crc_lsb);
    if (vif.rst_n === 1'b0) return;

    // 4) Build the transaction ---------------------------------
    tr = new();
    tr.parse_cfg(cfg_sampled);          // unpacks all cfg fields (pkg helper)
    tr.payload = new[payload_q.size()];
    foreach (payload_q[i]) tr.payload[i] = payload_q[i];
    tr.crc16 = {crc_msb, crc_lsb};      // observed CRC as carried on the bus

    num_observed++;

    `ifdef DEBUG
      tr.print("IN_MON");
    `endif

    // 5) Broadcast to all subscribers --------------------------
    broadcast(tr);
  endtask

  // ----------------------------------------------------------
  // collect_one_byte() - wait for the next valid input transfer
  // and return the byte on data_in. Returns early (rst_n low) if
  // reset drops while waiting, so the caller aborts.
  // ----------------------------------------------------------
  task automatic collect_one_byte(output bit [7:0] b);
    b = 8'h00;
    do begin
      @(posedge vif.clk);
      if (vif.rst_n === 1'b0) return;
    end while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1));
    b = vif.data_in;
  endtask

endclass : bird_in_monitor

`endif // BIRD_IN_MONITOR_SV
