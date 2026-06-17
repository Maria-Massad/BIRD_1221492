RD_RAND_SEQ_SV
`define BIRD_RAND_SEQ_SV

`include "bird_pkg.sv"
import bird_pkg::*;

class bird_rand_seq;

  mailbox #(bird_packet) mbx;
  int unsigned num_packets;
  int unsigned seed;

  function new(mailbox #(bird_packet) mbx, int unsigned num_packets = 20, int unsigned seed = 42);
    this.mbx         = mbx;
    this.num_packets = num_packets;
    this.seed        = seed;
  endfunction

  task run();
    bird_packet pkt;
    $display("[RAND_SEQ] Starting randomized sequence: %0d packets, seed=%0d",
             num_packets, seed);

    for (int i = 0; i < num_packets; i++) begin
      pkt = new();

      // use seed for reproducibility
      if (!pkt.randomize() with { }) begin
        $error("[RAND_SEQ] Randomization failed for packet %0d", i);
        continue;
      end

      $display("[RAND_SEQ] Packet %0d:", i);
      pkt.print("RAND_SEQ");

      mbx.put(pkt);
    end

    $display("[RAND_SEQ] Done sending %0d packets", num_packets);
  endtask

  task run_local_only();
    bird_packet pkt;
    $display("[RAND_SEQ] Starting LOCAL only sequence: %0d packets", num_packets);

    for (int i = 0; i < num_packets; i++) begin
      pkt = new();

      if (!pkt.randomize() with { pkt_type == LOCAL_PKT; }) begin
        $error("[RAND_SEQ] Randomization failed for local packet %0d", i);
        continue;
      end

      pkt.print("RAND_SEQ_LOCAL");
      mbx.put(pkt);
    end

    $display("[RAND_SEQ] Done sending %0d local packets", num_packets);
  endtask

  task run_remote_only();
    bird_packet pkt;
    $display("[RAND_SEQ] Starting REMOTE only sequence: %0d packets", num_packets);

    for (int i = 0; i < num_packets; i++) begin
      pkt = new();

      if (!pkt.randomize() with { pkt_type == REMOTE_PKT; }) begin
        $error("[RAND_SEQ] Randomization failed for remote packet %0d", i);
        continue;
      end

      pkt.print("RAND_SEQ_REMOTE");
      mbx.put(pkt);
    end

    $display("[RAND_SEQ] Done sending %0d remote packets", num_packets);
  endtask

  task run_max_payload();
    bird_packet pkt;
    $display("[RAND_SEQ] Starting MAX payload sequence: %0d packets", num_packets);

    for (int i = 0; i < num_packets; i++) begin
      pkt = new();

      if (!pkt.randomize() with { payload_len == 255; }) begin
        $error("[RAND_SEQ] Randomization failed for max payload packet %0d", i);
        continue;
      end

      pkt.print("RAND_SEQ_MAX");
      mbx.put(pkt);
    end

    $display("[RAND_SEQ] Done sending %0d max payload packets", num_packets);
  endtask

  task run_min_payload();
    bird_packet pkt;
    $display("[RAND_SEQ] Starting MIN payload sequence: %0d packets", num_packets);

    for (int i = 0; i < num_packets; i++) begin
      pkt = new();

      if (!pkt.randomize() with { payload_len == 1; }) begin
        $error("[RAND_SEQ] Randomization failed for min payload packet %0d", i);
        continue;
      end

      pkt.print("RAND_SEQ_MIN");
      mbx.put(pkt);
    end

    $display("[RAND_SEQ] Done sending %0d min payload packets", num_packets);
  endtask

endclass : bird_rand_seq

`endif
