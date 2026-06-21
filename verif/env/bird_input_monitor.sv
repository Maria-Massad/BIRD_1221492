import bird_pkg::*;
`ifndef BIRD_INPUT_MONITOR_SV
`define BIRD_INPUT_MONITOR_SV

class bird_input_monitor;

  
  // Virtual interface handle
  
  virtual bird_if.MONITOR vif;

  
  // Mailbox handle: sends reconstructed input packets to scoreboard
  
  mailbox #(bird_packet) input_mbx;

  
  // Constructor
  
  function new(virtual bird_if.MONITOR vif, mailbox #(bird_packet) input_mbx);
    this.vif       = vif;
    this.input_mbx = input_mbx;
  endfunction


  task run();
    bird_packet pkt;
    bit [31:0]  current_cfg;
    int         byte_count;
    int         payload_len;
    bit         collecting;

    $display("[%0t] INPUT_MONITOR: Started", $time);

    collecting  = 1'b0;
    byte_count  = 0;
    payload_len = 0;

    forever begin
      @(vif.mon_cb);

      if (vif.mon_cb.rst_n == 1'b0) begin
        collecting  = 1'b0;
        byte_count  = 0;
        payload_len = 0;
      end
      else begin
        if (vif.mon_cb.in_vld && vif.mon_cb.in_rdy) begin

          $display(
            "[%0t] INPUT_MONITOR: data_in=0x%02h cfg=0x%08h",
            $time,
            vif.mon_cb.data_in,
            vif.mon_cb.cfg
          );

          if (!collecting) begin
            // First byte: latch cfg, create new packet object
            current_cfg = vif.mon_cb.cfg;
            payload_len = int'(current_cfg[15:8]);

            pkt             = new();
            pkt.traffic_type = current_cfg[0];
            pkt.payload_len  = current_cfg[15:8];
            pkt.frag_num     = current_cfg[20:16];
            pkt.seq_num      = current_cfg[28:24];
            pkt.rsvd_7_1     = current_cfg[7:1];
            pkt.rsvd_23_21   = current_cfg[23:21];
            pkt.rsvd_31_29   = current_cfg[31:29];
            pkt.cfg          = current_cfg;

            if (payload_len > 0) begin
              pkt.payload    = new[payload_len];
              pkt.payload[0] = vif.mon_cb.data_in;
            end
            else begin
              pkt.payload = new[0];
            end

            byte_count = 1;
            collecting = 1'b1;
          end
          else begin
            if (byte_count < payload_len) begin
              pkt.payload[byte_count] = vif.mon_cb.data_in;
            end
            else if (byte_count == payload_len) begin
              pkt.crc16[15:8] = vif.mon_cb.data_in;
            end
            else if (byte_count == payload_len + 1) begin
              pkt.crc16[7:0] = vif.mon_cb.data_in;

              // Packet complete — send to scoreboard
              $display(
                "[%0t] INPUT_MONITOR: Packet complete cfg=0x%08h payload_len=%0d",
                $time, pkt.cfg, pkt.payload_len
              );

              input_mbx.put(pkt);

              collecting = 1'b0;
              byte_count = 0;
            end

            byte_count++;
          end

        end // in_vld && in_rdy
      end // not reset
    end // forever
  endtask

endclass

`endif

