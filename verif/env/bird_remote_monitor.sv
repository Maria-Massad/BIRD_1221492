import bird_pkg::*;


`ifndef BIRD_REMOTE_MONITOR_SV
`define BIRD_REMOTE_MONITOR_SV

class bird_remote_monitor;

 
  virtual bird_if.MONITOR vif;

  
  mailbox #(bit [31:0]) remote_mbx;

  //-------------------------------------------------------------------------
  // Constructor
  //-------------------------------------------------------------------------
  function new(virtual bird_if.MONITOR vif, mailbox #(bit [31:0]) remote_mbx);
    this.vif        = vif;
    this.remote_mbx = remote_mbx;
  endfunction

  //-------------------------------------------------------------------------
  // Monitor remote output transfers
  // A transfer is accepted when remote_vld = 1 and remote_rdy = 1.
  //-------------------------------------------------------------------------
  task run();
    $display("[%0t] REMOTE_MONITOR: Started", $time);

    forever begin
      @(vif.mon_cb);

      if (vif.mon_cb.rst_n == 1'b0) begin
        // Nothing to do on reset: scoreboard handles its own reset flush
      end
      else begin
        if (vif.mon_cb.remote_vld && vif.mon_cb.remote_rdy) begin
          remote_mbx.put(vif.mon_cb.data_remote);

          $display(
            "[%0t] REMOTE_MONITOR: data_remote=0x%08h",
            $time,
            vif.mon_cb.data_remote
          );
        end
      end
    end
  endtask

endclass

`endif

