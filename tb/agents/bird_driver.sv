`ifndef BIRD_SEQ_ITEM_SV
`define BIRD_SEQ_ITEM_SV

class bird_seq_item;

  bit traffic_type;

  bit [6:0] rsvd_7_1;
  byte unsigned payload_len;

  bit [4:0] frag_num;
  bit [2:0] rsvd_23_21;

  bit [4:0] seq_num;
  bit [2:0] rsvd_31_29;

  byte unsigned data[$];

  function new();
    traffic_type = 1'b0;
    rsvd_7_1     = 7'd0;
    payload_len  = 8'd0;
    frag_num     = 5'd1;
    rsvd_23_21   = 3'd0;
    seq_num      = 5'd1;
    rsvd_31_29   = 3'd0;
    data.delete();
  endfunction

  function bit [31:0] get_cfg();
    get_cfg = {
      rsvd_31_29,
      seq_num,
      rsvd_23_21,
      frag_num,
      payload_len,
      rsvd_7_1,
      traffic_type
    };
  endfunction

  function automatic bit [15:0] calc_crc16(input byte unsigned payload_q[$]);
    bit [15:0] crc;
    int i;
    int j;

    crc = 16'hFFFF;

    foreach (payload_q[i]) begin
      crc ^= {8'h00, payload_q[i]};

      for (j = 0; j < 8; j++) begin
        if (crc[0])
          crc = (crc >> 1) ^ 16'hA001;
        else
          crc = crc >> 1;
      end
    end

    return crc;
  endfunction

  function void get_input_stream(ref byte unsigned stream[$]);
    bit [15:0] crc_value;

    stream.delete();

    foreach (data[i]) begin
      stream.push_back(data[i]);
    end

    crc_value = calc_crc16(data);

    stream.push_back(crc_value[15:8]);
    stream.push_back(crc_value[7:0]);
  endfunction

  function string convert2string();
    return $sformatf(
      "traffic_type=%0b payload_len=%0d frag_num=%0d seq_num=%0d cfg=0x%08h data_size=%0d",
      traffic_type,
      payload_len,
      frag_num,
      seq_num,
      get_cfg(),
      data.size()
    );
  endfunction

endclass : bird_seq_item
`endif // BIRD_SEQ_ITEM_SV
