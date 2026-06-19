`ifndef BIRD_DRIVER_SV
`define BIRD_DRIVER_SV

class bird_driver;

  virtual bird_if.DRIVER vif;

  function new(virtual bird_if.DRIVER vif);
    this.vif = vif;
  endfunction

  //reset all driven signals through drv_cb
  task reset_driver_signals();
    vif.drv_cb.in_vld     <= 1'b0;
    vif.drv_cb.data_in    <= 8'h00;
    vif.drv_cb.cfg        <= 32'h0000_0000;
    vif.drv_cb.local_rdy  <= 1'b1;
    vif.drv_cb.remote_rdy <= 1'b1;
  endtask

  task wait_for_reset_release();
    wait (vif.rst_n == 1'b1);
    @(vif.drv_cb);
  endtask

  //drive one input byte + cfg through drv_cb, waits for in_rdy
  task drive_input_byte(
    input byte unsigned data_byte,
    input bit [31:0]    cfg_value
  );
    vif.drv_cb.in_vld  <= 1'b1;
    vif.drv_cb.data_in <= data_byte;
    vif.drv_cb.cfg     <= cfg_value;

    @(vif.drv_cb);
    while (vif.drv_cb.in_rdy !== 1'b1) begin
      @(vif.drv_cb);
    end

    vif.drv_cb.in_vld  <= 1'b0;
    vif.drv_cb.data_in <= 8'h00;
  endtask

  //drive a full packet, payload then crc high then crc low
  task drive_packet(bird_packet pkt);
    pkt.finalize_packet();

    $display("[%0t] DRIVER: Sending packet", $time);
    pkt.print("DRIVER_PACKET");

    if (pkt.payload_len == 8'd0) begin
      drive_input_byte(8'h00, pkt.cfg);
      drive_input_byte(8'h00, pkt.cfg);
    end
    else begin
      foreach (pkt.payload[i]) begin
        drive_input_byte(pkt.payload[i], pkt.cfg);
      end

      drive_input_byte(pkt.crc16[15:8], pkt.cfg);
      drive_input_byte(pkt.crc16[7:0],  pkt.cfg);
    end

    @(vif.drv_cb);
  endtask

  task set_local_ready(input bit ready_value);
    vif.drv_cb.local_rdy <= ready_value;
    @(vif.drv_cb);
  endtask

  task set_remote_ready(input bit ready_value);
    vif.drv_cb.remote_rdy <= ready_value;
    @(vif.drv_cb);
  endtask

  task idle(input int cycles);
    vif.drv_cb.in_vld  <= 1'b0;
    vif.drv_cb.data_in <= 8'h00;

    repeat (cycles) begin
      @(vif.drv_cb);
    end
  endtask

endclass

`endif
