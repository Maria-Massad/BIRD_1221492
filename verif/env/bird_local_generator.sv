
`ifndef BIRD_LOCAL_GENERATOR_SV
`define BIRD_LOCAL_GENERATOR_SV

class bird_local_generator;

  function new();
  endfunction


  // create_basic_local_packet()
  // Valid local packet — payload: AA BB CC DD
  // seq_num=1, frag_num=1 — correct, no change needed

  function bird_packet create_basic_local_packet();
    bird_packet pkt;
    byte unsigned data[];
    pkt  = new();
    data = new[4];
    data[0] = 8'hAA;
    data[1] = 8'hBB;
    data[2] = 8'hCC;
    data[3] = 8'hDD;
    pkt.make_local(5'd1, data);   // seq=1
    return pkt;
  endfunction


  // create_min_payload_local_packet()
  // Valid local packet — minimum payload boundary (1 byte)

  function bird_packet create_min_payload_local_packet();
    bird_packet pkt;
    byte unsigned data[];
    pkt  = new();
    data = new[1];
    data[0] = 8'h5A;
    pkt.make_local(5'd1, data);
    return pkt;
  endfunction


  // create_local_packet()
  // Custom local packet with user-defined sequence number and payload.
  //
  // Per spec Section 6, SEQ_NUM has no functional impact on local
  // routing — any valid value (1-31) is accepted. No warning needed
  // since any sequence_number value is spec-valid for local traffic.

  function bird_packet create_local_packet(
    input bit [4:0]      sequence_number,
    input byte unsigned  data[]
  );
    bird_packet pkt;
    pkt = new();
    pkt.make_local(sequence_number, data);
    return pkt;
  endfunction


  // create_max_payload_local_packet()
  // Valid local packet — payload: 255 bytes (0x00 to 0xFE)

  function bird_packet create_max_payload_local_packet();
    bird_packet pkt;
    byte unsigned data[];
    pkt  = new();
    data = new[255];
    foreach (data[i]) data[i] = byte'(i);
    pkt.make_local(5'd1, data);
    return pkt;
  endfunction


  // create_local_packet_varied_seq()
  // Generates a valid local packet with a specific SEQ_NUM, used to
  // build a suite of tests that send different SEQ_NUM values and
  // confirm they all forward identically — directly verifying spec
  // Section 6's claim that SEQ_NUM has no functional impact on local
  // routing, and spec Section 10's verification note: "Verify correct
  // use of FRAG_NUM and SEQ_NUM."

  function bird_packet create_local_packet_varied_seq(
    input bit [4:0] sequence_number
  );
    bird_packet pkt;
    byte unsigned data[];
    pkt  = new();
    data = new[3];
    data[0] = 8'h01;
    data[1] = 8'h02;
    data[2] = 8'h03;
    pkt.make_local(sequence_number, data);
    return pkt;
  endfunction

endclass

`endif
