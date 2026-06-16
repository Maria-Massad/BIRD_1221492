`ifndef BIRD_LOCAL_BASIC_SEQ_SV
`define BIRD_LOCAL_BASIC_SEQ_SV

class bird_local_basic_seq;

  string name;

  function new(string name = "bird_local_basic_seq");
    this.name = name;
  endfunction

  task body(output bird_seq_item req);

    req = new("local_basic_item");

    if (!req.randomize() with {
      traffic_type == bird_seq_item::LOCAL;
      rsvd_7_1     == 7'd0;
      payload_len  == 8'd4;
      frag_num     == 5'd1;
      rsvd_23_21   == 3'd0;
      seq_num      == 5'd1;
      rsvd_31_29   == 3'd0;

      data.size()  == 4;
      data[0]      == 8'hAA;
      data[1]      == 8'hBB;
      data[2]      == 8'hCC;
      data[3]      == 8'hDD;
    }) begin
      $error("BIRD_LOCAL_BASIC_SEQ randomization failed");
    end

    req.update_crc();

  endtask

endclass

`endif
