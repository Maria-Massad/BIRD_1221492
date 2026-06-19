`ifndef BIRD_DRIVE_SV
`define BIRD_DRIVE_SV

`include "bird_if.sv"
`include "bird_pkg.sv"

import bird_pkg::* ;




class bird_driver;

 virtual bird_if vif;
 mailbox #(bird_packet) mbx;
 
 
  function new(virtual bird_if vif, mailbox #(bird_packet) mbx);
    this.vif = vif;
    this.mbx = mbx;
  endfunction
  
  task reset(int unsigned cycles = 5);
    
    vif.driver_cb.rst_n      <= 0;
    vif.driver_cb.in_vld     <= 0;
    vif.driver_cb.data_in    <= 0;
    vif.driver_cb.cfg        <= 0;
    vif.driver_cb.local_rdy  <= 1;  // consumer always ready by default
    vif.driver_cb.remote_rdy <= 1;  // consumer always ready by default
 
    // hold reset for N clock cycles
    repeat (cycles) @(vif.driver_cb);
 
    // release reset
    vif.driver_cb.rst_n <= 1;
 
    // wait 2 more cycles for DUT to stabilize
    repeat (2) @(vif.driver_cb);
 
    $display("[DRIVER] Reset done");
  endtask
  
  
  task run();
    bird_packet pkt;
    forever begin
      // wait for a packet from the sequence
      mbx.get(pkt); //block here until the pkt available
      send_fragment(pkt);  // send it to the DUT
    end
  endtask
  
  
  // send_fragment()
 
  // A fragment = payload bytes + 2 CRC bytes
  // cfg is driven before the first byte and held stable
 
  task send_fragment(bird_packet pkt);
 
    //1. put cfg on the wire
    // cfg must be valid on the same cycle as the first payload byte
    vif.driver_cb.cfg <= pkt.cfg_word;
 
    // 2.send each payload byte 
    foreach (pkt.payload[i]) begin
      vif.driver_cb.in_vld  <= 1;
      vif.driver_cb.data_in <= pkt.payload[i];
      @(vif.driver_cb);
      // in_rdy is always 1 in this DUT so no need to wait
      // but we check anyway for correctness
      while (!vif.driver_cb.in_rdy) @(vif.driver_cb);
    end
 
    // 3. Step 3: send CRC high byte 
    vif.driver_cb.in_vld  <= 1;
    vif.driver_cb.data_in <= pkt.crc16[15:8];
    @(vif.driver_cb);
    while (!vif.driver_cb.in_rdy) @(vif.driver_cb);
 
    // 4. send CRC low byte
    vif.driver_cb.in_vld  <= 1;
    vif.driver_cb.data_in <= pkt.crc16[7:0];
    @(vif.driver_cb);
    while (!vif.driver_cb.in_rdy) @(vif.driver_cb);
 
    // 5. deassert valid 
    vif.driver_cb.in_vld  <= 0;
    vif.driver_cb.data_in <= 0;
    @(vif.driver_cb);
 
    `ifdef DEBUG
      pkt.print("DRIVER");
    `endif
 
  endtask

  // set_local_rdy() — control local consumer backpressure
 
  task set_local_rdy(input bit val);
    vif.driver_cb.local_rdy <= val;
    @(vif.driver_cb);
  endtask
 
  // set_remote_rdy() — control remote consumer backpressure

  task set_remote_rdy(input bit val);
    vif.driver_cb.remote_rdy <= val;
    @(vif.driver_cb);
  endtask
 
  
  // wait_cycles() — helper to idle for N cycles

  task wait_cycles(int unsigned n);
    repeat (n) @(vif.driver_cb);
  endtask
 
endclass : bird_driver
 
`endif
