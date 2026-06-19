`ifndef BIRD_PKG_SV
`define BIRD_PKG_SV

package bird_pkg;

  typedef enum logic {
    LOCAL_PKT  = 1'b0,
    REMOTE_PKT = 1'b1
  } pkt_type_e;

  class bird_packet;

    rand pkt_type_e pkt_type;
    rand bit [4:0]  seq_num;
    rand bit [4:0]  frag_num;
    rand bit [7:0]  payload_len;

    bit [6:0] reserved_7_1   = 7'h0;
    bit [2:0] reserved_23_21 = 3'h0;
    bit [2:0] reserved_31_29 = 3'h0;

    rand bit [7:0] payload [];
    bit [15:0]     crc16;
    bit [31:0]     cfg_word;

    constraint c_len   { payload_len inside {[1:255]}; }
    constraint c_size  { payload.size() == payload_len; }

    constraint c_local {
      (pkt_type == LOCAL_PKT) -> (frag_num == 1 && seq_num inside {[1:31]});
    }

    constraint c_remote {
      (pkt_type == REMOTE_PKT) -> (seq_num inside {[1:31]} && frag_num inside {[1:31]});
    }

    function void build_cfg();
      cfg_word        = 32'h0;
      cfg_word[0]     = pkt_type;
      cfg_word[7:1]   = reserved_7_1;
      cfg_word[15:8]  = payload_len;
      cfg_word[20:16] = frag_num;
      cfg_word[23:21] = reserved_23_21;
      cfg_word[28:24] = seq_num;
      cfg_word[31:29] = reserved_31_29;
    endfunction

    function void parse_cfg(input bit [31:0] raw);
      cfg_word         = raw;
      pkt_type         = pkt_type_e'(raw[0]);
      reserved_7_1     = raw[7:1];
      payload_len      = raw[15:8];
      frag_num         = raw[20:16];
      reserved_23_21   = raw[23:21];
      seq_num          = raw[28:24];
      reserved_31_29   = raw[31:29];
    endfunction

    static function bit [15:0] compute_crc16(input bit [7:0] data []);
      bit [15:0] crc;
      crc = 16'hFFFF;
      foreach (data[i]) begin
        crc ^= ({data[i], 8'h00});
        repeat (8) begin
          if (crc[15]) crc = (crc << 1) ^ 16'h1021;
          else         crc = (crc << 1);
        end
      end
      return crc;
    endfunction

    static function bit [15:0] compute_crc16_q(input bit [7:0] data_q [$]);
      bit [15:0] crc;
      crc = 16'hFFFF;
      foreach (data_q[i]) begin
        crc ^= ({data_q[i], 8'h00});
        repeat (8) begin
          if (crc[15]) crc = (crc << 1) ^ 16'h1021;
          else         crc = (crc << 1);
        end
      end
      return crc;
    endfunction

    function void post_randomize();
      build_cfg();
      crc16 = compute_crc16(payload);
    endfunction

    function void get_input_stream(ref bit [7:0] stream [$]);
      stream.delete();
      foreach (payload[i])
        stream.push_back(payload[i]);
      stream.push_back(crc16[15:8]);
      stream.push_back(crc16[7:0]);
    endfunction

    function bit is_local();
      return (pkt_type == LOCAL_PKT);
    endfunction

    function bit is_remote();
      return (pkt_type == REMOTE_PKT);
    endfunction

    function bit reserved_bits_zero();
      return (reserved_7_1   == 7'h0) &&
             (reserved_23_21 == 3'h0) &&
             (reserved_31_29 == 3'h0);
    endfunction

    function bit is_valid();
      return reserved_bits_zero()           &&
             (payload_len inside {[1:255]}) &&
             (frag_num     inside {[1:31]}) &&
             (seq_num      inside {[1:31]});
    endfunction

    function void print(string tag = "PKT");
      $display("[%s] type=%-6s seq=%0d frag=%0d len=%0d crc=0x%04h cfg=0x%08h",
               tag,
               (pkt_type == LOCAL_PKT) ? "LOCAL" : "REMOTE",
               seq_num, frag_num, payload_len, crc16, cfg_word);
    endfunction

    function bird_packet copy();
      bird_packet p    = new();
      p.pkt_type       = this.pkt_type;
      p.seq_num        = this.seq_num;
      p.frag_num       = this.frag_num;
      p.payload_len    = this.payload_len;
      p.payload        = new[this.payload.size()](this.payload);
      p.crc16          = this.crc16;
      p.cfg_word       = this.cfg_word;
      p.reserved_7_1   = this.reserved_7_1;
      p.reserved_23_21 = this.reserved_23_21;
      p.reserved_31_29 = this.reserved_31_29;
      return p;
    endfunction

  endclass : bird_packet

endpackage : bird_pkg

`endif
