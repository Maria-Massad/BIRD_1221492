
`ifndef BIRD_PACKET_SV
`define BIRD_PACKET_SV

class bird_packet;

  localparam bit LOCAL_TRAFFIC  = 1'b0;
  localparam bit REMOTE_TRAFFIC = 1'b1;

  // Configuration fields
  rand bit        traffic_type;
  rand bit [7:0]  payload_len;
  rand bit [4:0]  frag_num;
  rand bit [4:0]  seq_num;
  rand bit [6:0]  rsvd_7_1;
  rand bit [2:0]  rsvd_23_21;
  rand bit [2:0]  rsvd_31_29;

  // Data fields
  rand byte unsigned payload[];
  bit [15:0] crc16;
  bit [31:0] cfg;


  function new();
    traffic_type = LOCAL_TRAFFIC;
    payload_len  = 8'd1;
    frag_num     = 5'd1;
    seq_num      = 5'd1;
    rsvd_7_1     = 7'd0;
    rsvd_23_21   = 3'd0;
    rsvd_31_29   = 3'd0;
    payload      = new[1];
    payload[0]   = 8'h00;
    crc16        = 16'h0000;
    cfg          = 32'h0000_0000;
  endfunction


  // Basic valid packet fields — spec Section 5
  constraint c_valid_basic {
    payload_len inside {[8'd1:8'd255]};
    frag_num    inside {[5'd1:5'd31]};
    seq_num     inside {[5'd1:5'd31]};
    rsvd_7_1   == 7'd0;
    rsvd_23_21 == 3'd0;
    rsvd_31_29 == 3'd0;
    payload.size() == payload_len;
  }


  // Spec Section 6 — Local Traffic Processing:
  //   "FRAG_NUM shall be equal to 1."
  //   "SEQ_NUM identifies the packet but has no functional impact
  //    on local routing."
  // Only FRAG_NUM is constrained for local traffic. SEQ_NUM is left
  // free to randomize across its full valid range (1-31) so that
  // tests can verify it has no functional impact, as required by
  // spec Section 10: "Verify correct use of FRAG_NUM and SEQ_NUM."
  constraint c_local_rules {
    if (traffic_type == LOCAL_TRAFFIC) {
      frag_num == 5'd1;
    }
  }


  // build_cfg() — pack fields into 32-bit cfg word
  // Bit layout from spec Section 5:
  //   [0]     traffic_type
  //   [7:1]   rsvd_7_1
  //   [15:8]  payload_len
  //   [20:16] frag_num
  //   [23:21] rsvd_23_21
  //   [28:24] seq_num
  //   [31:29] rsvd_31_29

  function void build_cfg();
    cfg = {
      rsvd_31_29,    // bits 31:29
      seq_num,       // bits 28:24
      rsvd_23_21,    // bits 23:21
      frag_num,      // bits 20:16
      payload_len,   // bits 15:8
      rsvd_7_1,      // bits 7:1
      traffic_type   // bit 0
    };
  endfunction

  //-------------------------------------------------------------------------
  // calculate_crc16() — CRC16-CCITT
  // Polynomial: 0x1021, Init: 0xFFFF
  // MSB of each byte processed first (byte XORed into top 8 bits of CRC)
  //-------------------------------------------------------------------------
  function bit [15:0] calculate_crc16();
    bit [15:0] crc;
    crc = 16'hFFFF;
    foreach (payload[i]) begin
      crc ^= {payload[i], 8'h00};   // byte -> top 8 bits (MSB first)
      for (int b = 0; b < 8; b++) begin
        if (crc[15])
          crc = (crc << 1) ^ 16'h1021;
        else
          crc = crc << 1;
      end
    end
    return crc;
  endfunction

  //-------------------------------------------------------------------------
  // finalize_packet() — call after setting all fields manually
  // Builds cfg word and computes CRC16
  //-------------------------------------------------------------------------
  function void finalize_packet();
    build_cfg();
    crc16 = calculate_crc16();
  endfunction


  // Called automatically after pkt.randomize()
  // Ensures cfg and crc16 are always correct after randomization
  function void post_randomize();
    finalize_packet();
  endfunction


  // make_local() — directed local packet.
  // sequence_number is accepted as given, with no enforced value,
  // per spec Section 6 ("SEQ_NUM... has no functional impact on
  // local routing"). frag_num is always forced to 1 per spec.
  function void make_local(
    input bit [4:0]      sequence_number,
    input byte unsigned  data[]
  );
    traffic_type = LOCAL_TRAFFIC;
    payload_len  = data.size();
    frag_num     = 5'd1;
    seq_num      = sequence_number;
    rsvd_7_1     = 7'd0;
    rsvd_23_21   = 3'd0;
    rsvd_31_29   = 3'd0;
    payload      = new[data.size()];
    foreach (data[i]) payload[i] = data[i];
    finalize_packet();
  endfunction


  // make_remote_fragment() — directed remote fragment

  function void make_remote_fragment(
    input bit [4:0]      sequence_number,
    input bit [4:0]      fragment_number,
    input byte unsigned  data[]
  );
    traffic_type = REMOTE_TRAFFIC;
    payload_len  = data.size();
    frag_num     = fragment_number;
    seq_num      = sequence_number;
    rsvd_7_1     = 7'd0;
    rsvd_23_21   = 3'd0;
    rsvd_31_29   = 3'd0;
    payload      = new[data.size()];
    foreach (data[i]) payload[i] = data[i];
    finalize_packet();
  endfunction


  // Invalid packet helpers — for drop tests, per spec Section 8.1

  function void make_invalid_seq_zero(input byte unsigned data[]);
    make_local(5'd1, data);
    seq_num = 5'd0;      // override to invalid value
    finalize_packet();   // rebuild cfg with invalid seq_num
  endfunction

  function void make_invalid_frag_zero(input byte unsigned data[]);
    make_remote_fragment(5'd1, 5'd1, data);
    frag_num = 5'd0;     // override to invalid value
    finalize_packet();   // rebuild cfg with invalid frag_num
  endfunction

  function void make_invalid_payload_len_zero();
    traffic_type = LOCAL_TRAFFIC;
    payload_len  = 8'd0;   // invalid
    frag_num     = 5'd1;
    seq_num      = 5'd1;
    rsvd_7_1     = 7'd0;
    rsvd_23_21   = 3'd0;
    rsvd_31_29   = 3'd0;
    payload      = new[0]; // empty — driver sends 0 bytes
    finalize_packet();
  endfunction

  function void make_invalid_reserved_bits(input byte unsigned data[]);
    make_local(5'd1, data);
    rsvd_7_1 = 7'b000_0001;  // set one reserved bit
    finalize_packet();
  endfunction


  // print() — debug display

  function void print(string tag = "BIRD_PACKET");
    $display("[%0t] %s", $time, tag);
    $display("  traffic_type = %0d (%s)",
             traffic_type,
             traffic_type ? "REMOTE" : "LOCAL");
    $display("  payload_len  = %0d", payload_len);
    $display("  frag_num     = %0d", frag_num);
    $display("  seq_num      = %0d", seq_num);
    $display("  rsvd_7_1     = 0x%02h", rsvd_7_1);
    $display("  rsvd_23_21   = 0x%01h", rsvd_23_21);
    $display("  rsvd_31_29   = 0x%01h", rsvd_31_29);
    $display("  cfg          = 0x%08h", cfg);
    $display("  crc16        = 0x%04h", crc16);
    $write  ("  payload      = ");
    foreach (payload[i]) $write("%02h ", payload[i]);
    $write("\n");
  endfunction
  
  
  
  // compute_crc16_q — called by scoreboard
  // takes a queue instead of array
  static function bit [15:0] compute_crc16_q(
    input byte unsigned payload_q[$]
  );
    bit [15:0] crc;
    crc = 16'hFFFF;
    foreach (payload_q[i]) begin
      crc ^= {payload_q[i], 8'h00};
      for (int b = 0; b < 8; b++) begin
        if (crc[15])
          crc = (crc << 1) ^ 16'h1021;
        else
          crc = crc << 1;
      end
    end
    return crc;
  endfunction

endclass

`endif
