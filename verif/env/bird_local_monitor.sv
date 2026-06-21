import bird_pkg::*;
`ifndef BIRD_LOCAL_MONITOR_SV
`define BIRD_LOCAL_MONITOR_SV

class bird_local_monitor;

  // Virtual interface handle
  
  virtual bird_if.MONITOR vif;

  
  // Mailbox handle: sends observed local output bytes to scoreboard
 
  mailbox #(byte unsigned) local_mbx;

  
  // Constructor
  
  function new(virtual bird_if.MONITOR vif, mailbox #(byte unsigned) local_mbx);
    this.vif       = vif;
    this.local_mbx = local_mbx;
  endfunction

  // Monitor local output transfers
  // A transfer is accepted when local_vld = 1 and local_rdy = 1.
  
  task run();
    $display("[%0t] LOCAL_MONITOR: Started", $time);

    forever begin
      @(vif.mon_cb);

      if (vif.mon_cb.rst_n == 1'b0) begin
        // Nothing to do on reset: scoreboard handles its own reset flush
      end
      else begin
        if (vif.mon_cb.local_vld && vif.mon_cb.local_rdy) begin
          local_mbx.put(vif.mon_cb.data_local);

          $display(
            "[%0t] LOCAL_MONITOR: data_local=0x%02h",
            $time,
            vif.mon_cb.data_local
          );
        end
      end
    end
  endtask

endclass

`endif

