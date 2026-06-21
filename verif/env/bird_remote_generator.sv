import bird_pkg::*;
`ifndef BIRD_REMOTE_GENERATOR_SV
`define BIRD_REMOTE_GENERATOR_SV

class bird_remote_generator;

  function new();
  endfunction

  //gen a valid remote pkt that has 1 frag only
  function bird_packet create_single_fragment_remote_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();

    data = new[4];
    data[0] = 8'h11;
    data[1] = 8'h22;
    data[2] = 8'h33;
    data[3] = 8'h44;

    pkt.make_remote_fragment(5'd4, 5'd1, data);

    return pkt;
  endfunction

  //gen remote frag 1 for a 2 frag packet
  function bird_packet create_two_fragment_packet_frag1();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();

    data = new[4];
    data[0] = 8'hAA;
    data[1] = 8'hBB;
    data[2] = 8'hCC;
    data[3] = 8'hDD;

    pkt.make_remote_fragment(5'd5, 5'd1, data);

    return pkt;
  endfunction

  //gen remote frag 2 for a 2 frag packet
  function bird_packet create_two_fragment_packet_frag2();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();

    data = new[4];
    data[0] = 8'hEE;
    data[1] = 8'hFF;
    data[2] = 8'h11;
    data[3] = 8'h22;

    pkt.make_remote_fragment(5'd5, 5'd2, data);

    return pkt;
  endfunction

  //create a userdef valid remote fragment
  function bird_packet create_remote_fragment(
    input bit [4:0] sequence_number,
    input bit [4:0] fragment_number,
    input byte unsigned data[]
  );
    bird_packet pkt;

    pkt = new();
    pkt.make_remote_fragment(sequence_number, fragment_number, data);

    return pkt;
  endfunction

endclass

`endif
