//============================================================================= 
// One bird_seq_item models one input FRAGMENT transfer:
//   - 32-bit sideband cfg word
//   - payload byte stream
//   - trailing CRC16 on data_in
//
// cfg bit layout:
//   [0]     TRAFFIC_TYPE   1 bit   0 = local, 1 = remote
//   [7:1]   RSVD_7_1       7 bits  must be 0
//   [15:8]  PAYLOAD_LEN    8 bits  valid range: 1..255
//   [20:16] FRAG_NUM       5 bits  valid range: 1..31
//   [23:21] RSVD_23_21     3 bits  must be 0
//   [28:24] SEQ_NUM        5 bits  valid range: 1..31, 0 is invalid
//   [31:29] RSVD_31_29     3 bits  must be 0
//
// DUT note:
//   In the provided DUT, LOCAL traffic is accepted only when:
//     traffic_type = 0
//     frag_num     = 1
//     seq_num      = 1
//   Therefore, the default valid local constraint uses seq_num == 1.
//=============================================================================

`ifndef BIRD_SEQ_ITEM_SV
`define BIRD_SEQ_ITEM_SV

class bird_seq_item extends uvm_sequence_item;

  typedef enum bit {
    LOCAL  = 1'b0,
    REMOTE = 1'b1
  } traffic_type_e;

  //---------------------------------------------------------------------------
  // cfg fields
  rand bit       traffic_type;   // cfg[0]      : 0 = local, 1 = remote
  rand bit [6:0] rsvd_7_1;       // cfg[7:1]    : must be 0
  rand bit [7:0] payload_len;    // cfg[15:8]   : 1..255
  rand bit [4:0] frag_num;       // cfg[20:16]  : 1..31
  rand bit [2:0] rsvd_23_21;     // cfg[23:21]  : must be 0
  rand bit [4:0] seq_num;        // cfg[28:24]  : 1..31, 0 invalid
  rand bit [2:0] rsvd_31_29;     // cfg[31:29]  : must be 0

  //---------------------------------------------------------------------------
  // Data stream
  rand byte unsigned data[];

  bit [15:0] crc16;

  //---------------------------------------------------------------------------
  // UVM factory registration
  `uvm_object_utils_begin(bird_seq_item)
    `uvm_field_int(traffic_type,  UVM_ALL_ON)
    `uvm_field_int(rsvd_7_1,      UVM_ALL_ON)
    `uvm_field_int(payload_len,   UVM_ALL_ON)
    `uvm_field_int(frag_num,      UVM_ALL_ON)
    `uvm_field_int(rsvd_23_21,    UVM_ALL_ON)
    `uvm_field_int(seq_num,       UVM_ALL_ON)
    `uvm_field_int(rsvd_31_29,    UVM_ALL_ON)
    `uvm_field_array_int(data,    UVM_ALL_ON)
    `uvm_field_int(crc16,         UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "bird_seq_item");
    super.new(name);
  endfunction

  //---------------------------------------------------------------------------
  // Constraints

  constraint c_data_size {
    data.size() == int'(payload_len);
  }

  // Default valid packet for Phase 1 bring-up.
  // This is LOCAL by default because sanity tests usually start with local.
  // Based on the provided DUT, valid LOCAL requires seq_num == 1 and frag_num == 1.
  constraint c_valid_local_pkt {
    traffic_type == LOCAL;
    rsvd_7_1     == 7'b0;
    rsvd_23_21   == 3'b0;
    rsvd_31_29   == 3'b0;
    payload_len  inside {[1:255]};
    frag_num     == 5'd1;
    seq_num      == 5'd1;
  }

  constraint c_default_small_payload {
    soft payload_len inside {[1:16]};
  }

  //---------------------------------------------------------------------------
  // cfg packing / unpacking

  function bit [31:0] get_cfg();
    return {
      rsvd_31_29,
      seq_num,
      rsvd_23_21,
      frag_num,
      payload_len,
      rsvd_7_1,
      traffic_type
    };
  endfunction

  function void set_cfg(bit [31:0] cfg);
    traffic_type = cfg[0];
    rsvd_7_1     = cfg[7:1];
    payload_len  = cfg[15:8];
    frag_num     = cfg[20:16];
    rsvd_23_21   = cfg[23:21];
    seq_num      = cfg[28:24];
    rsvd_31_29   = cfg[31:29];
  endfunction

  //---------------------------------------------------------------------------
  // functions
  function bit is_local();
    return (traffic_type == LOCAL);
  endfunction

  function bit is_remote();
    return (traffic_type == REMOTE);
  endfunction

  function bit reserved_bits_are_zero();
    return (rsvd_7_1 == 7'b0) &&
           (rsvd_23_21 == 3'b0) &&
           (rsvd_31_29 == 3'b0);
  endfunction

  function bit has_valid_basic_fields();
    return reserved_bits_are_zero() &&
           (payload_len inside {[1:255]}) &&
           (frag_num    inside {[1:31]})  &&
           (seq_num     inside {[1:31]});
  endfunction

  function bit has_valid_local_fields_for_dut();
    return reserved_bits_are_zero() &&
           (traffic_type == LOCAL) &&
           (payload_len inside {[1:255]}) &&
           (frag_num == 5'd1) &&
           (seq_num  == 5'd1);
  endfunction

  function bit has_valid_remote_fields();
    return reserved_bits_are_zero() &&
           (traffic_type == REMOTE) &&
           (payload_len inside {[1:255]}) &&
           (frag_num inside {[1:31]}) &&
           (seq_num  inside {[1:31]});
  endfunction

  function void resize_data_to_payload_len();
    data = new[int'(payload_len)];
  endfunction

  static function bit [15:0] compute_crc16(input byte unsigned payload[]);
    bit [15:0] crc;

    crc = 16'hFFFF;

    foreach (payload[i]) begin
      crc = crc ^ {payload[i], 8'h00};

      for (int b = 0; b < 8; b++) begin
        if (crc[15])
          crc = (crc << 1) ^ 16'h1021;
        else
          crc = (crc << 1);
      end
    end

    return crc;
  endfunction

  static function bit [15:0] compute_crc16_q(input byte unsigned payload_q[$]);
    bit [15:0] crc;

    crc = 16'hFFFF;

    foreach (payload_q[i]) begin
      crc = crc ^ {payload_q[i], 8'h00};

      for (int b = 0; b < 8; b++) begin
        if (crc[15])
          crc = (crc << 1) ^ 16'h1021;
        else
          crc = (crc << 1);
      end
    end

    return crc;
  endfunction

  function void update_crc();
    crc16 = compute_crc16(data);
  endfunction

  function byte unsigned crc_msb();
    return crc16[15:8];
  endfunction

  function byte unsigned crc_lsb();
    return crc16[7:0];
  endfunction

  function void get_input_stream(ref byte unsigned stream[$]);
    stream.delete();

    foreach (data[i]) begin
      stream.push_back(data[i]);
    end

    stream.push_back(crc_msb());
    stream.push_back(crc_lsb());
  endfunction

  function void post_randomize();
    update_crc();
  endfunction

  // Printing
 
  function string convert2string();
    return $sformatf(
      "%s : cfg=0x%08h type=%s payload_len=%0d frag_num=%0d seq_num=%0d rsvd_7_1=0x%0h rsvd_23_21=0x%0h rsvd_31_29=0x%0h data.size=%0d crc16=0x%04h",
      get_name(),
      get_cfg(),
      traffic_type ? "REMOTE" : "LOCAL",
      payload_len,
      frag_num,
      seq_num,
      rsvd_7_1,
      rsvd_23_21,
      rsvd_31_29,
      data.size(),
      crc16
    );
  endfunction

endclass : bird_seq_item

`endif // BIRD_SEQ_ITEM_SV
