`ifndef BIRD_IF_SV   //They make sure the file is only compiled once, no matter how many other files include it.
`define BIRD_IF_SV

interface bird_if(input logic clk);


  logic rst_n;
  // Input Interface
  logic        in_vld;
  logic        in_rdy;
  logic [7:0]  data_in;
  logic [31:0] cfg;

  logic [15:0] drop_cnt;
   // Local output
  logic        local_vld;
  logic        local_rdy;
  logic [7:0]  data_local;
   //Remote output
  logic        remote_vld; 
  logic        remote_vld;
  logic        remote_rdy;
  logic [31:0] data_remote;



  clocking driver_cb @(posedge clk);
   default input #1step output #1;
    output rst_n;
    output in_vld;
    output data_in;
    output cfg;
    output local_rdy;
    output remote_rdy;
    input  in_rdy;
    input  drop_cnt;
  endclocking
  
  clocking local_cb @(posedge clk);
    default input #1step;
    input local_vld;
    input local_rdy;
    input data_local;
  endclocking
  
  clocking remote_cb @(posedge clk);
   default input #1step;
   
   input remote_vld;
   input remote_rdy;
   input data_remote;
  endclocking
  
  
  // SVA System verilog Assertion
  
  //Assertion 1 input stability
  
  property p_input_stability;
  @(posedge clk) disable iff (!rst_n)
    (in_vld && !in_rdy) |=> ($stable(data_in) && $stable(cfg));
  endproperty
  assert property (p_input_stability)
   else $error("[ASSERT] Stability violation...");
  
  
  // Assertion 2 
  
  
  
 // Outputs deassert during reset
 //p_reset_local_vld    ? reset on = local_vld must be 0, right now
  property p_reset_local_vld;
    @(posedge clk) (!rst_n) |-> (!local_vld);
  endproperty
  assert property (p_reset_local_vld)
    else $error("[ASSERT] local_vld asserted during reset");
  
  //Assertion 3 
  
  
  
  //p_reset_remote_vld   ? reset on = remote_vld must be 0, right now 
   property p_reset_remote_vld;
    @(posedge clk) (!rst_n) |-> (!remote_vld);
  endproperty
  assert property (p_reset_remote_vld)
    else $error("[ASSERT] remote_vld asserted during reset");
 
  // Assertion 4 drop_cnt must be 0 during reset
  
  
  //p_reset_drop_cnt     ? reset on = drop_cnt must be 0, right now
  property p_reset_drop_cnt;
    @(posedge clk) (!rst_n) |-> (drop_cnt == 16'd0);
  endproperty
  assert property (p_reset_drop_cnt)
    else $error("[ASSERT] drop_cnt != 0 during reset");
 
  // Assertion 5 local and remote valid never both asserted
  
  
  //p_mutual_exclusion   ? local_vld and remote_vld can NEVER both be 1
  property p_mutual_exclusion;
    @(posedge clk) disable iff (!rst_n)
      !(local_vld && remote_vld);
  endproperty
  assert property (p_mutual_exclusion)
    else $error("[ASSERT] local_vld and remote_vld both high at same time");
 
endinterface : bird_if
 
`endif

