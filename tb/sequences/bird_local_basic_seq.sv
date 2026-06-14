//=============================================================================
// Generates one simple valid local packet for bring-up.
// Payload: AA BB CC DD
//=============================================================================

`ifndef BIRD_LOCAL_BASIC_SEQ_SV
`define BIRD_LOCAL_BASIC_SEQ_SV

class bird_local_basic_seq extends uvm_sequence #(bird_seq_item);

  `uvm_object_utils(bird_local_basic_seq)

  function new(string name = "bird_local_basic_seq");
    super.new(name);
  endfunction

  task body();
    bird_seq_item req;

    req = bird_seq_item::type_id::create("req");

    start_item(req);

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
      `uvm_error("BIRD_LOCAL_BASIC_SEQ", "Randomization failed")
    end

    req.update_crc();

    finish_item(req);
  endtask

endclass : bird_local_basic_seq

`endif // BIRD_LOCAL_BASIC_SEQ_SV
RD_LOCAL_BASIC_SEQ_SV
`define BIRD_LOCAL_BASIC_SEQ_SV

class bird_local_basic_seq extends uvm_sequence #(bird_seq_item);

  `uvm_object_utils(bird_local_basic_seq)

  function new(string name = "bird_local_basic_seq");
    super.new(name);
  endfunction

  task body();
    bird_seq_item req;

    req = bird_seq_item::type_id::create("req");

    start_item(req);

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
      `uvm_error("BIRD_LOCAL_BASIC_SEQ", "Randomization failed")
    end

    req.update_crc();

    finish_item(req);
  endtask

endclass : bird_local_basic_seq

`endif // BIRD_LOCAL_BASIC_SEQ_SV

