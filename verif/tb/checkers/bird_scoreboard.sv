`ifndef BIRD_SCOREBOARD_SV
`define BIRD_SCOREBOARD_SV

class bird_scoreboard;

  mailbox #(bird_packet)   input_mbx;
  mailbox #(byte unsigned) local_mbx;
  mailbox #(bit [31:0])    remote_mbx;

  byte unsigned expected_local_q[$];
  bit [31:0]    expected_remote_q[$];

  byte unsigned actual_local_q[$];
  bit [31:0]    actual_remote_q[$];

  int unsigned pass_count;
  int unsigned fail_count;
  int unsigned predicted_drop_count;

  bit           remote_active;
  bit [4:0]     active_seq;
  bit [4:0]     active_max_frag;
  bit           frag_seen[1:31];
  byte unsigned frag_payload[1:31][$];

  function new(
    mailbox #(bird_packet) input_mbx,
    mailbox #(byte unsigned) local_mbx,
    mailbox #(bit [31:0]) remote_mbx
  );
    this.input_mbx  = input_mbx;
    this.local_mbx  = local_mbx;
    this.remote_mbx = remote_mbx;

    pass_count            = 0;
    fail_count            = 0;
    predicted_drop_count  = 0;
    clear_remote_state();
  endfunction

  function bit is_remote_packet(bird_packet pkt);
    return pkt.cfg[0];
  endfunction

  function void clear_remote_state();
    remote_active   = 1'b0;
    active_seq      = 5'd0;
    active_max_frag = 5'd0;

    for (int f = 1; f <= 31; f++) begin
      frag_seen[f] = 1'b0;
      frag_payload[f].delete();
    end
  endfunction

  function bit valid_cfg_for_scoreboard(bird_packet pkt);
    if (pkt.rsvd_7_1   != 7'd0) return 1'b0;
    if (pkt.rsvd_23_21 != 3'd0) return 1'b0;
    if (pkt.rsvd_31_29 != 3'd0) return 1'b0;

    if (pkt.payload_len == 8'd0) return 1'b0;
    if (pkt.seq_num     == 5'd0) return 1'b0;
    if (pkt.frag_num    == 5'd0) return 1'b0;

    if (!is_remote_packet(pkt) && (pkt.frag_num != 5'd1)) return 1'b0;

    return 1'b1;
  endfunction

  function void predict_packet_drop(string reason);
    predicted_drop_count++;
    $display("[%0t] SCOREBOARD: Predicted packet drop: %s", $time, reason);
  endfunction

  function bit all_remote_frags_ready();
    if (!remote_active) return 1'b0;
    if (active_max_frag == 5'd0) return 1'b0;

    for (int f = 1; f <= active_max_frag; f++) begin
      if (!frag_seen[f]) return 1'b0;
    end

    return 1'b1;
  endfunction

  function void compare_local_ready();
    byte unsigned actual;
    byte unsigned expected;

    while ((expected_local_q.size() != 0) && (actual_local_q.size() != 0)) begin
      expected = expected_local_q.pop_front();
      actual   = actual_local_q.pop_front();

      if (actual !== expected) begin
        $error("[%0t] SCOREBOARD FAIL: LOCAL_OUTPUT got=0x%02h expected=0x%02h",
               $time, actual, expected);
        fail_count++;
      end
      else begin
        $display("[%0t] SCOREBOARD PASS: LOCAL_OUTPUT byte=0x%02h", $time, actual);
        pass_count++;
      end
    end
  endfunction

  function void compare_remote_ready();
    bit [31:0] actual;
    bit [31:0] expected;

    while ((expected_remote_q.size() != 0) && (actual_remote_q.size() != 0)) begin
      expected = expected_remote_q.pop_front();
      actual   = actual_remote_q.pop_front();

      if (actual !== expected) begin
        $error("[%0t] SCOREBOARD FAIL: REMOTE_OUTPUT got=0x%08h expected=0x%08h",
               $time, actual, expected);
        fail_count++;
      end
      else begin
        $display("[%0t] SCOREBOARD PASS: REMOTE_OUTPUT word=0x%08h", $time, actual);
        pass_count++;
      end
    end
  endfunction

  function void pack_bytes_to_words(input byte unsigned bytes[$]);
    int i;
    i = 0;

    while (i < bytes.size()) begin
      bit [31:0] word;
      word = 32'h0000_0000;

      for (int k = 0; k < 4; k++) begin
        if (i < bytes.size()) begin
          word[24 - 8*k +: 8] = bytes[i];
          i++;
        end
      end

      expected_remote_q.push_back(word);
    end
  endfunction

  function void queue_remote_output();
    byte unsigned merged_stream[$];
    bit [15:0]    regenerated_crc;

    merged_stream.delete();

    for (int f = 1; f <= active_max_frag; f++) begin
      foreach (frag_payload[f][i]) begin
        merged_stream.push_back(frag_payload[f][i]);
      end
    end

    regenerated_crc = bird_packet::compute_crc16_q(merged_stream);

    merged_stream.push_back(regenerated_crc[15:8]);
    merged_stream.push_back(regenerated_crc[7:0]);

    pack_bytes_to_words(merged_stream);
    compare_remote_ready();

    $display("[%0t] SCOREBOARD: Remote packet merged in FRAG_NUM order 1..%0d, stream_bytes=%0d, crc=0x%04h",
             $time, active_max_frag, merged_stream.size(), regenerated_crc);
  endfunction

  function void predict_local_packet(bird_packet pkt);
    foreach (pkt.payload[i]) begin
      expected_local_q.push_back(pkt.payload[i]);
    end

    expected_local_q.push_back(pkt.crc16[15:8]);
    expected_local_q.push_back(pkt.crc16[7:0]);
    compare_local_ready();

    $display("[%0t] SCOREBOARD: Local expected bytes queued=%0d",
             $time, pkt.payload.size() + 2);
  endfunction

  function void start_remote_packet(bit [4:0] seq_num);
    clear_remote_state();
    remote_active   = 1'b1;
    active_seq      = seq_num;
    active_max_frag = 5'd0;

    $display("[%0t] SCOREBOARD: Started remote packet seq=%0d", $time, seq_num);
  endfunction

  function void store_remote_fragment(bird_packet pkt);
    if (frag_seen[pkt.frag_num]) begin
      $display("[%0t] SCOREBOARD WARNING: Duplicate remote fragment seq=%0d frag=%0d, replacing previous payload",
               $time, pkt.seq_num, pkt.frag_num);
    end

    frag_seen[pkt.frag_num] = 1'b1;
    frag_payload[pkt.frag_num].delete();

    foreach (pkt.payload[i]) begin
      frag_payload[pkt.frag_num].push_back(pkt.payload[i]);
    end

    if (pkt.frag_num > active_max_frag) begin
      active_max_frag = pkt.frag_num;
    end

    $display("[%0t] SCOREBOARD: Stored remote fragment seq=%0d frag=%0d payload_bytes=%0d max_frag=%0d",
             $time, pkt.seq_num, pkt.frag_num, pkt.payload.size(), active_max_frag);
  endfunction

  function void process_remote_packet(bird_packet pkt);
    if (!remote_active) begin
      start_remote_packet(pkt.seq_num);
    end
    else if (pkt.seq_num != active_seq) begin
      predict_packet_drop("mismatched SEQ_NUM while previous remote packet is incomplete");
      clear_remote_state();

      if (pkt.frag_num == 5'd1) begin
        start_remote_packet(pkt.seq_num);
      end
      else begin
        predict_packet_drop("new remote packet did not start at FRAG_NUM 1 after previous drop");
        return;
      end
    end

    store_remote_fragment(pkt);

    if (all_remote_frags_ready()) begin
      queue_remote_output();
      clear_remote_state();
    end
  endfunction

  function void process_input_packet(bird_packet pkt);
    if (!valid_cfg_for_scoreboard(pkt)) begin
      predict_packet_drop($sformatf("invalid cfg=0x%08h", pkt.cfg));
      if (is_remote_packet(pkt)) begin
        clear_remote_state();
      end
      return;
    end

    if (!is_remote_packet(pkt)) begin
      predict_local_packet(pkt);
    end
    else begin
      process_remote_packet(pkt);
    end
  endfunction

  task process_inputs();
    bird_packet pkt;

    forever begin
      input_mbx.get(pkt);
      process_input_packet(pkt);
    end
  endtask

  task check_local_outputs();
    byte unsigned actual;

    forever begin
      local_mbx.get(actual);
      actual_local_q.push_back(actual);
      compare_local_ready();
    end
  endtask

  task check_remote_outputs();
    bit [31:0] actual;

    forever begin
      remote_mbx.get(actual);
      actual_remote_q.push_back(actual);
      compare_remote_ready();
    end
  endtask

  task run();
    $display("[%0t] SCOREBOARD: Started", $time);

    fork
      process_inputs();
      check_local_outputs();
      check_remote_outputs();
    join_none
  endtask

  task report();
    if (remote_active) begin
      predict_packet_drop("simulation ended while remote packet was still incomplete");
      clear_remote_state();
    end

    compare_local_ready();
    compare_remote_ready();

    if (expected_local_q.size() != 0) begin
      $error("[%0t] SCOREBOARD FAIL: %0d expected local bytes were not produced",
             $time, expected_local_q.size());
      fail_count++;
    end

    if (actual_local_q.size() != 0) begin
      $error("[%0t] SCOREBOARD FAIL: %0d unexpected local bytes were produced",
             $time, actual_local_q.size());
      fail_count++;
    end

    if (expected_remote_q.size() != 0) begin
      $error("[%0t] SCOREBOARD FAIL: %0d expected remote words were not produced",
             $time, expected_remote_q.size());
      fail_count++;
    end

    if (actual_remote_q.size() != 0) begin
      $error("[%0t] SCOREBOARD FAIL: %0d unexpected remote words were produced",
             $time, actual_remote_q.size());
      fail_count++;
    end

    $display("==============================================");
    $display(" SCOREBOARD SUMMARY");
    $display(" PASS COUNT             = %0d", pass_count);
    $display(" FAIL COUNT             = %0d", fail_count);
    $display(" PREDICTED DROP COUNT   = %0d", predicted_drop_count);
    $display(" PENDING LOCAL BYTES    = %0d", expected_local_q.size());
    $display(" PENDING LOCAL ACTUAL   = %0d", actual_local_q.size());
    $display(" PENDING REMOTE WORDS   = %0d", expected_remote_q.size());
    $display(" PENDING REMOTE ACTUAL  = %0d", actual_remote_q.size());
    $display("==============================================");
  endtask

endclass : bird_scoreboard

`endif
