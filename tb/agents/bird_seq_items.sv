RD_SEQ_ITEM_SV
`define BIRD_SEQ_ITEM_SV

class bird_seq_item;

  typedef enum bit {
    LOCAL  = 1'b0,
    REMOTE = 1'b1
  } traffic_type_e;

  string name;

  rand bit       traffic_type;
  rand bit [6:0] rsvd_7_1;
  rand bit [7:0] payload_len;
  rand bit [4:0] frag_num;
  rand bit [2:0] rsvd_23_21;
  rand bit [4:0] seq_num;
  rand bit [2:0] rsvd_31_29;

  rand byte unsigned data[];

  bit [15:0] crc16;

  function new(string name = "bird_seq_item");
    this.name = name;
  endfunction

  function string get_name();
    return name;
  endfunction

  constraint c_data_size {
    data.size() == int'(payload_len);
  }

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

  function bit is_local();
    return traffic_type == LOCAL;
  endfunction

  function bit is_remote();
    return traffic_type == REMOTE;
  endfunction

  function bit reserved_bits_are_zero();
    return (rsvd_7_1 == 7'b0) &&
           (rsvd_23_21 == 3'b0) &&
           (rsvd_31_29 == 3'b0);
  endfunction

  function bit has_valid_basic_fields();
    return reserved_bits_are_zero() &&
           (payload_len inside {[1:255]}) &&
           (frag_num inside {[1:31]}) &&
           (seq_num inside {[1:31]});
  endfunction

  function bit has_valid_local_fields_for_dut();
    return reserved_bits_are_zero() &&
           (traffic_type == LOCAL) &&
           (payload_len inside {[1:255]}) &&
           (frag_num == 5'd1) &&
           (seq_num == 5'd1);
  endfunction

  function bit has_valid_remote_fields();
    return reserved_bits_are_zero() &&
           (traffic_type == REMOTE) &&
           (payload_len inside {[1:255]}) &&
           (frag_num inside {[1:31]}) &&
           (seq_num inside {[1:31]});
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
          crc = crc << 1;
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
          crc = crc << 1;
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

endclass

`endif
