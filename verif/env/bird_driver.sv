import bird_pkg::*;
//=============================================================================
// bird_driver.sv
// Plain SystemVerilog driver for BIRD verification
//
// FIX APPLIED:
//   drive_input_byte() used to clear cfg to 0x00000000 after each byte.
//   The DUT re-reads cfg in RX_PAYLOAD state so a stale cfg=0 caused
//   the DUT to misclassify subsequent bytes as invalid local packets.
//   Fix: keep cfg stable (hold last value) between bytes.
//   Also added idle_after_packet() to drain DUT pipeline between packets.
//=============================================================================
`ifndef BIRD_DRIVER_SV
`define BIRD_DRIVER_SV

class bird_driver;

  virtual bird_if.DRIVER vif;

  // last cfg driven — held stable between bytes
  bit [31:0] last_cfg;

  function new(virtual bird_if.DRIVER vif);
    this.vif   = vif;
    last_cfg   = 32'h0000_0000;
  endfunction

  //-------------------------------------------------------------------------
  // reset_driver_signals() — safe defaults
  //-------------------------------------------------------------------------
  task reset_driver_signals();
    vif.drv_cb.in_vld     <= 1'b0;
    vif.drv_cb.data_in    <= 8'h00;
    vif.drv_cb.cfg        <= 32'h0000_0000;
    vif.drv_cb.local_rdy  <= 1'b1;
    vif.drv_cb.remote_rdy <= 1'b1;
    last_cfg = 32'h0000_0000;
  endtask

  //-------------------------------------------------------------------------
  // wait_for_reset_release()
  //-------------------------------------------------------------------------
  task wait_for_reset_release();
    wait (vif.rst_n == 1'b1);
    @(vif.drv_cb);
  endtask

  //-------------------------------------------------------------------------
  // drive_input_byte() — drive one byte with cfg
  //
  // FIX: after handshake, keep cfg stable (last_cfg) instead of
  //      clearing to 0. DUT reads cfg in every FSM state so clearing
  //      it between bytes caused wrong routing decisions.
  //-------------------------------------------------------------------------
  task drive_input_byte(
    input byte unsigned data_byte,
    input bit [31:0]    cfg_value
  );
    last_cfg = cfg_value;

    vif.drv_cb.in_vld  <= 1'b1;
    vif.drv_cb.data_in <= data_byte;
    vif.drv_cb.cfg     <= cfg_value;
    @(vif.drv_cb);

    while (vif.drv_cb.in_rdy !== 1'b1) begin
      @(vif.drv_cb);
    end

    // FIX: deassert in_vld but KEEP cfg stable
    vif.drv_cb.in_vld  <= 1'b0;
    vif.drv_cb.data_in <= 8'h00;
    vif.drv_cb.cfg     <= cfg_value;  // ? keep cfg, don't clear to 0
  endtask

  //-------------------------------------------------------------------------
  // drive_packet() — drive full packet: payload then CRC high then CRC low
  // After packet, holds idle for 5 cycles to let DUT FSM complete
  //-------------------------------------------------------------------------
  task drive_packet(bird_packet pkt);
    pkt.finalize_packet();
    $display("[%0t] DRIVER: Sending packet", $time);
    pkt.print("DRIVER_PACKET");

    if (pkt.payload_len == 8'd0) begin
      // payload_len=0: send 1 dummy byte so DUT reads cfg
      drive_input_byte(8'hFF, pkt.cfg);
    end
    else begin
      foreach (pkt.payload[i]) begin
        drive_input_byte(pkt.payload[i], pkt.cfg);
      end
      drive_input_byte(pkt.crc16[15:8], pkt.cfg);
      drive_input_byte(pkt.crc16[7:0],  pkt.cfg);
    end

    // idle after packet — let DUT FSM finish before next packet
    idle(5);
  endtask

  //-------------------------------------------------------------------------
  // set_local_ready() / set_remote_ready()
  //-------------------------------------------------------------------------
  task set_local_ready(input bit ready_value);
    vif.drv_cb.local_rdy <= ready_value;
    @(vif.drv_cb);
  endtask

  task set_remote_ready(input bit ready_value);
    vif.drv_cb.remote_rdy <= ready_value;
    @(vif.drv_cb);
  endtask

  //-------------------------------------------------------------------------
  // idle() — drive N idle cycles with in_vld=0
  //-------------------------------------------------------------------------
  task idle(input int cycles);
    vif.drv_cb.in_vld  <= 1'b0;
    vif.drv_cb.data_in <= 8'h00;
    // keep cfg stable during idle
    vif.drv_cb.cfg     <= last_cfg;
    repeat (cycles) @(vif.drv_cb);
  endtask

endclass

`endif