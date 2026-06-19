`ifndef BIRD_ASSERTIONS_SV
`define BIRD_ASSERTIONS_SV

module bird_assertions (bird_if.MONITOR vif);

  bit drop_cnt_past_valid;

  initial begin
    drop_cnt_past_valid = 1'b0;
  end

  always @(posedge vif.clk) begin
    if (!vif.mon_cb.rst_n) begin
      drop_cnt_past_valid <= 1'b0;
    end
    else begin
      drop_cnt_past_valid <= 1'b1;
    end
  end

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

  property p_local_output_stable_under_backpressure;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.local_vld && !vif.mon_cb.local_rdy)
      |=> (vif.mon_cb.local_vld && $stable(vif.mon_cb.data_local));
  endproperty

  a_local_output_stable_under_backpressure:
    assert property (p_local_output_stable_under_backpressure)
    else $error("ASSERT FAIL: local output changed while local_vld=1 and local_rdy=0");

  property p_remote_output_stable_under_backpressure;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.remote_vld && !vif.mon_cb.remote_rdy)
      |=> (vif.mon_cb.remote_vld && $stable(vif.mon_cb.data_remote));
  endproperty

  a_remote_output_stable_under_backpressure:
    assert property (p_remote_output_stable_under_backpressure)
    else $error("ASSERT FAIL: remote output changed while remote_vld=1 and remote_rdy=0");

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

  property p_no_unknowns_on_input_transfer;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n)
      (vif.mon_cb.in_vld && vif.mon_cb.in_rdy)
      |-> (!$isunknown(vif.mon_cb.data_in) &&
           !$isunknown(vif.mon_cb.cfg));
  endproperty

  a_no_unknowns_on_input_transfer:
    assert property (p_no_unknowns_on_input_transfer)
    else $error("ASSERT FAIL: X/Z detected on accepted input transfer");

  property p_drop_cnt_increments_by_one_only;
    @(posedge vif.clk) disable iff (!vif.mon_cb.rst_n || !drop_cnt_past_valid)
      (vif.mon_cb.drop_cnt != $past(vif.mon_cb.drop_cnt))
      |-> (vif.mon_cb.drop_cnt == ($past(vif.mon_cb.drop_cnt) + 16'd1));
  endproperty

  a_drop_cnt_increments_by_one_only:
    assert property (p_drop_cnt_increments_by_one_only)
    else $error("ASSERT FAIL: drop_cnt changed by more than one or changed incorrectly");

endmodule : bird_assertions

`endif
