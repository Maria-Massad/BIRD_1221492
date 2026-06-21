import bird_pkg::*;

`ifndef BIRD_LOCAL_GENERATOR_SV
`define BIRD_LOCAL_GENERATOR_SV
import bird_pkg::*;

class bird_local_generator;

  function new();
  endfunction

  // Create a simple valid local packet with a fixed payload.
  function bird_packet create_basic_local_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt  = new();
    data = new[4];

    data[0] = 8'hAA;
    data[1] = 8'hBB;
    data[2] = 8'hCC;
    data[3] = 8'hDD;

    pkt.make_local(5'd1, data);
    return pkt;
  endfunction

  // Create a valid local packet with the minimum payload size.
  function bird_packet create_min_payload_local_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt  = new();
    data = new[1];

    data[0] = 8'h5A;

    pkt.make_local(5'd1, data);
    return pkt;
  endfunction

  // Create a local packet using a selected sequence number and payload.
  function bird_packet create_local_packet(
    input bit [4:0]      sequence_number,
    input byte unsigned  data[]
  );
    bird_packet pkt;

    pkt = new();
    pkt.make_local(sequence_number, data);

    return pkt;
  endfunction

  // Create a valid local packet with the maximum payload size.
  function bird_packet create_max_payload_local_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt  = new();
    data = new[255];

    foreach (data[i]) begin
      data[i] = byte'(i);
    end

    pkt.make_local(5'd1, data);
    return pkt;
  endfunction

  // Create a valid local packet with a specific SEQ_NUM value.
  // This is used to check that different valid sequence numbers still behave
  // the same for local traffic.
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
