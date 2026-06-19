`ifndef BIRD_DROP_GENERATOR_SV
`define BIRD_DROP_GENERATOR_SV

class bird_drop_generator;

  function new();
  endfunction

  //small payload used by invalid pkts
  function void build_small_payload(output byte unsigned data[]);
    data = new[2];
    data[0] = 8'hDE;
    data[1] = 8'hAD;
  endfunction

  //invalid pkt seq_num=0
  function bird_packet create_seq_zero_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();
    build_small_payload(data);

    pkt.make_invalid_seq_zero(data);

    return pkt;
  endfunction

  //invalid pkt frag_num=0
  function bird_packet create_frag_zero_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();
    build_small_payload(data);

    pkt.make_invalid_frag_zero(data);

    return pkt;
  endfunction

  //invalid pkt payload_len=0
  function bird_packet create_payload_len_zero_packet();
    bird_packet pkt;

    pkt = new();
    pkt.make_invalid_payload_len_zero();

    return pkt;
  endfunction

  //invalid pkt reserved bits non zero
  function bird_packet create_reserved_bits_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();
    build_small_payload(data);

    pkt.make_invalid_reserved_bits(data);

    return pkt;
  endfunction

  //invalid local pkt, frag_num forced to 2 instead of 1
  function bird_packet create_local_invalid_frag_packet();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();

    data = new[2];
    data[0] = 8'h12;
    data[1] = 8'h34;

    pkt.make_local(5'd6, data);

    pkt.frag_num = 5'd2;
    pkt.finalize_packet();

    return pkt;
  endfunction

  //invalid remote seq mismatch, frag1 seq=7 then frag2 seq=8
  function void create_remote_seq_mismatch_pair(
    output bird_packet frag1,
    output bird_packet frag2
  );
    byte unsigned data1[];
    byte unsigned data2[];

    frag1 = new();
    frag2 = new();

    data1 = new[2];
    data1[0] = 8'hA1;
    data1[1] = 8'hA2;

    data2 = new[2];
    data2[0] = 8'hB1;
    data2[1] = 8'hB2;

    frag1.make_remote_fragment(5'd7, 5'd1, data1);
    frag2.make_remote_fragment(5'd8, 5'd2, data2);
  endfunction

  //invalid remote missing fragment, frag1 and frag3 sent, frag2 never sent
  function void create_remote_missing_fragment_pair(
    output bird_packet frag1,
    output bird_packet frag3
  );
    byte unsigned data1[];
    byte unsigned data3[];

    frag1 = new();
    frag3 = new();

    data1 = new[2];
    data1[0] = 8'hC1;
    data1[1] = 8'hC2;

    data3 = new[2];
    data3[0] = 8'hC3;
    data3[1] = 8'hC4;

    frag1.make_remote_fragment(5'd9, 5'd1, data1);
    frag3.make_remote_fragment(5'd9, 5'd3, data3);
  endfunction

  //invalid remote, new frag1 arrives while old seq still incomplete
  function void create_remote_frag1_while_incomplete_pair(
    output bird_packet old_frag1,
    output bird_packet new_frag1
  );
    byte unsigned data_old[];
    byte unsigned data_new[];

    old_frag1 = new();
    new_frag1 = new();

    data_old = new[2];
    data_old[0] = 8'hD1;
    data_old[1] = 8'hD2;

    data_new = new[2];
    data_new[0] = 8'hE1;
    data_new[1] = 8'hE2;

    old_frag1.make_remote_fragment(5'd10, 5'd1, data_old);
    new_frag1.make_remote_fragment(5'd11, 5'd1, data_new);
  endfunction

endclass

`endif
