import bird_pkg::*;

`ifndef BIRD_COVERAGE_SV
`define BIRD_COVERAGE_SV

class bird_coverage;

  bit        sampled_traffic_type;
  bit [7:0]  sampled_payload_len;
  bit [4:0]  sampled_frag_num;
  bit [4:0]  sampled_seq_num;
  bit [6:0]  sampled_rsvd_7_1;
  bit [2:0]  sampled_rsvd_23_21;
  bit [2:0]  sampled_rsvd_31_29;

  bit sampled_seq_zero;
  bit sampled_frag_zero;
  bit sampled_payload_len_zero;
  bit sampled_reserved_nonzero;
  bit sampled_local_invalid_frag;
  bit sampled_remote_valid;

  bit sampled_frag_out_of_order;
  bit sampled_local_backpressure;
  bit sampled_remote_backpressure;
  bit sampled_seq_mismatch;
  bit sampled_missing_fragment;

  covergroup cg_packet_cfg;

    option.per_instance = 1;

    cp_traffic_type: coverpoint sampled_traffic_type {
      bins local_traffic  = {1'b0};
      bins remote_traffic = {1'b1};
    }

    cp_payload_len: coverpoint sampled_payload_len {
      bins len_zero   = {8'd0};
      bins len_min    = {8'd1};
      bins len_small  = {[8'd2:8'd15]};
      bins len_medium = {[8'd16:8'd127]};
      bins len_large  = {[8'd128:8'd254]};
      bins len_max    = {8'd255};
    }

    cp_frag_num: coverpoint sampled_frag_num {
      bins frag_zero = {5'd0};
      bins frag_one  = {5'd1};
      bins frag_mid  = {[5'd2:5'd30]};
      bins frag_max  = {5'd31};
    }

    cp_seq_num: coverpoint sampled_seq_num {
      bins seq_zero = {5'd0};
      bins seq_one  = {5'd1};
      bins seq_mid  = {[5'd2:5'd30]};
      bins seq_max  = {5'd31};
    }

    cp_rsvd_7_1: coverpoint sampled_rsvd_7_1 {
      bins reserved_zero    = {7'd0};
      bins reserved_nonzero = {[7'd1:7'd127]};
    }

    cp_rsvd_23_21: coverpoint sampled_rsvd_23_21 {
      bins reserved_zero    = {3'd0};
      bins reserved_nonzero = {[3'd1:3'd7]};
    }

    cp_rsvd_31_29: coverpoint sampled_rsvd_31_29 {
      bins reserved_zero    = {3'd0};
      bins reserved_nonzero = {[3'd1:3'd7]};
    }

    cp_seq_zero: coverpoint sampled_seq_zero {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_frag_zero: coverpoint sampled_frag_zero {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_payload_len_zero: coverpoint sampled_payload_len_zero {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_reserved_nonzero: coverpoint sampled_reserved_nonzero {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_local_invalid_frag: coverpoint sampled_local_invalid_frag {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_remote_valid: coverpoint sampled_remote_valid {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cross_traffic_payload: cross cp_traffic_type, cp_payload_len;
    cross_traffic_frag:    cross cp_traffic_type, cp_frag_num;
    cross_traffic_seq:     cross cp_traffic_type, cp_seq_num;

  endgroup

  covergroup cg_behavior;

    option.per_instance = 1;

    cp_frag_out_of_order: coverpoint sampled_frag_out_of_order {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_local_backpressure: coverpoint sampled_local_backpressure {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_remote_backpressure: coverpoint sampled_remote_backpressure {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_seq_mismatch: coverpoint sampled_seq_mismatch {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

    cp_missing_fragment: coverpoint sampled_missing_fragment {
      bins not_seen = {1'b0};
      bins seen     = {1'b1};
    }

  endgroup

  function new();
    cg_packet_cfg = new();
    cg_behavior   = new();

    sampled_traffic_type       = 1'b0;
    sampled_payload_len        = 8'd0;
    sampled_frag_num           = 5'd0;
    sampled_seq_num            = 5'd0;
    sampled_rsvd_7_1           = 7'd0;
    sampled_rsvd_23_21         = 3'd0;
    sampled_rsvd_31_29         = 3'd0;
    sampled_seq_zero           = 1'b0;
    sampled_frag_zero          = 1'b0;
    sampled_payload_len_zero   = 1'b0;
    sampled_reserved_nonzero   = 1'b0;
    sampled_local_invalid_frag = 1'b0;
    sampled_remote_valid       = 1'b0;

    sampled_frag_out_of_order  = 1'b0;
    sampled_local_backpressure = 1'b0;
    sampled_remote_backpressure= 1'b0;
    sampled_seq_mismatch       = 1'b0;
    sampled_missing_fragment   = 1'b0;
  endfunction

  function void sample_packet(bird_packet pkt);

    sampled_traffic_type = pkt.traffic_type;
    sampled_payload_len  = pkt.payload_len;
    sampled_frag_num     = pkt.frag_num;
    sampled_seq_num      = pkt.seq_num;
    sampled_rsvd_7_1     = pkt.rsvd_7_1;
    sampled_rsvd_23_21   = pkt.rsvd_23_21;
    sampled_rsvd_31_29   = pkt.rsvd_31_29;

    sampled_seq_zero         = (pkt.seq_num     == 5'd0);
    sampled_frag_zero        = (pkt.frag_num    == 5'd0);
    sampled_payload_len_zero = (pkt.payload_len == 8'd0);

    sampled_reserved_nonzero =
      (pkt.rsvd_7_1   != 7'd0) ||
      (pkt.rsvd_23_21 != 3'd0) ||
      (pkt.rsvd_31_29 != 3'd0);

    sampled_local_invalid_frag =
      (pkt.traffic_type == bird_packet::LOCAL_TRAFFIC) &&
      (pkt.frag_num != 5'd1);

    sampled_remote_valid =
      (pkt.traffic_type == bird_packet::REMOTE_TRAFFIC) &&
      (pkt.payload_len inside {[8'd1:8'd255]}) &&
      (pkt.frag_num    inside {[5'd1:5'd31]})  &&
      (pkt.seq_num     inside {[5'd1:5'd31]})  &&
      (pkt.rsvd_7_1   == 7'd0) &&
      (pkt.rsvd_23_21 == 3'd0) &&
      (pkt.rsvd_31_29 == 3'd0);

    cg_packet_cfg.sample();

    $display("[%0t] COVERAGE: Sampled packet cfg=0x%08h", $time, pkt.cfg);

  endfunction

  function void sample_reorder(input bit out_of_order);
    sampled_frag_out_of_order = out_of_order;
    cg_behavior.sample();
  endfunction

  function void sample_backpressure(
    input bit local_vld,
    input bit local_rdy,
    input bit remote_vld,
    input bit remote_rdy
  );
    sampled_local_backpressure  = (local_vld  && !local_rdy);
    sampled_remote_backpressure = (remote_vld && !remote_rdy);
    cg_behavior.sample();
  endfunction

  function void sample_seq_mismatch(input bit mismatch);
    sampled_seq_mismatch = mismatch;
    cg_behavior.sample();
  endfunction

  function void sample_missing_fragment(input bit missing);
    sampled_missing_fragment = missing;
    cg_behavior.sample();
  endfunction

  function void report();
    $display("============================================================");
    $display("BIRD FUNCTIONAL COVERAGE SUMMARY");
    $display("Packet cfg coverage  = %0.2f%%", cg_packet_cfg.get_coverage());
    $display("Behavioral coverage  = %0.2f%%", cg_behavior.get_coverage());
    $display("============================================================");
  endfunction

endclass

`endif
