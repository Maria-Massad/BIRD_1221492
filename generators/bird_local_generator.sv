
`ifndef BIRD_LOCAL_GENERATOR_SV
`define BIRD_LOCAL_GENERATOR_SV

class bird_local_generator;

  function new();
  endfunction

  
  // create_basic_local_packet()
  // Valid local packet — payload: AA BB CC DD
  // seq_num=1, frag_num=1 ? correct, no change needed
  
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
  // Custom local packet with user-defined sequence number and payload
  //
  // Added assertion to warn if sequence_number != 1
  // DUT only accepts local packets with seq_num==1
  //         Passing any other value will cause a silent drop
  
  function bird_packet create_local_packet(
    input bit [4:0]      sequence_number,
    input byte unsigned  data[]
  );
    bird_packet pkt;
    // warn if seq_num != 1 — DUT will drop local packets with seq?1
    if (sequence_number != 5'd1)
      $display("[LOCAL_GEN] WARNING: sequence_number=%0d for local packet — DUT requires seq=1, packet may be dropped",
               sequence_number);
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
    pkt.make_local(5'd1, data);   // FIX: was 5'd3, now 5'd1
    return pkt;
  endfunction

endclass

`endif