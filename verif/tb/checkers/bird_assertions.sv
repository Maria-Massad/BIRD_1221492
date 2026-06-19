`ifndef BIRD_ASSERTIONS_SV
`define BIRD_ASSERTIONS_SV

//=============================================================================
// File        : bird_assertions.sv
// Project     : BIRD - Birzeit Integrated Router Design
// Description : Five protocol/reset assertions for the BIRD interface.
//               These assertions are independent from bird_env.sv.
//=============================================================================

module bird_assertions (bird_if.MONITOR vif);

  // 1) Input stability rule: when producer is valid and DUT is not ready,
  //    input data and cfg must stay stable until the next cycle.
  property p_input_stable_under_backpressure;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.in_vld && !vif.mon_cb.in_rdy)
      |=> (vif.mon_cb.in_vld &&
           $stable(vif.mon_cb.data_in) &&
           $stable(vif.mon_cb.cfg));
  endproperty

  a_input_stable_under_backpressure:
    assert property (p_input_stable_under_backpressure)
    else $error("ASSERT FAIL: input data/cfg changed while in_vld=1 and in_rdy=0");

  // 2) Local output stability rule under local backpressure.
  property p_local_output_stable_under_backpressure;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.local_vld && !vif.mon_cb.local_rdy)
      |=> (vif.mon_cb.local_vld && $stable(vif.mon_cb.data_local));
  endproperty

  a_local_output_stable_under_backpressure:
    assert property (p_local_output_stable_under_backpressure)
    else $error("ASSERT FAIL: local output changed while local_vld=1 and local_rdy=0");

  // 3) Remote output stability rule under remote backpressure.
  property p_remote_output_stable_under_backpressure;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.remote_vld && !vif.mon_cb.remote_rdy)
      |=> (vif.mon_cb.remote_vld && $stable(vif.mon_cb.data_remote));
  endproperty

  a_remote_output_stable_under_backpressure:
    assert property (p_remote_output_stable_under_backpressure)
    else $error("ASSERT FAIL: remote output changed while remote_vld=1 and remote_rdy=0");

  // 4) Reset behavior: during reset, valid outputs must be deasserted and drop_cnt cleared.
  property p_reset_clears_visible_state;
    @(posedge vif.clk)
      (!vif.mon_cb.rst_n)
      |-> (!vif.mon_cb.local_vld &&
           !vif.mon_cb.remote_vld &&
           (vif.mon_cb.drop_cnt == 16'd0));
  endproperty

  a_reset_clears_visible_state:
    assert property (p_reset_clears_visible_state)
    else $error("ASSERT FAIL: reset did not clear local_vld, remote_vld, or drop_cnt");

  // 5) No unknowns on accepted input transfers.
  property p_no_unknowns_on_input_transfer;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.in_vld && vif.mon_cb.in_rdy)
      |-> (!$isunknown(vif.mon_cb.data_in) &&
           !$isunknown(vif.mon_cb.cfg));
  endproperty

  a_no_unknowns_on_input_transfer:
    assert property (p_no_unknowns_on_input_transfer)
    else $error("ASSERT FAIL: X/Z detected on accepted input transfer");

endmodule : bird_assertions

`endif
