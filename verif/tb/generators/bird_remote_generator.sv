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

    data = new[2];
    data[0] = 8'hAA;
    data[1] = 8'hBB;

    pkt.make_remote_fragment(5'd5, 5'd1, data);

    return pkt;
  endfunction

  //gen remote frag 2 for a 2 frag packet
  function bird_packet create_two_fragment_packet_frag2();
    bird_packet pkt;
    byte unsigned data[];

    pkt = new();

    data = new[2];
    data[0] = 8'hCC;
    data[1] = 8'hDD;

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

  //build merged payload for the standard 2 frag remote pkt
  function void build_standard_merged_payload(
    output byte unsigned merged_payload[$]
  );
    merged_payload.delete();

    merged_payload.push_back(8'hAA);
    merged_payload.push_back(8'hBB);
    merged_payload.push_back(8'hCC);
    merged_payload.push_back(8'hDD);
  endfunction

  //calc crc16 for any byte queue
  function bit [15:0] calculate_crc16_for_queue(
    input byte unsigned data_queue[$]
  );
    bit [15:0] crc;
    int i;
    int b;

    crc = 16'hFFFF;

    foreach (data_queue[i]) begin
      crc ^= {data_queue[i], 8'h00};

      for (b = 0; b < 8; b++) begin
        if (crc[15]) begin
          crc = (crc << 1) ^ 16'h1021;
        end
        else begin
          crc = crc << 1;
        end
      end
    end

    return crc;
  endfunction

endclass

`endif
