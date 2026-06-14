`ifndef BIRD_IN_MONITOR_SV
`define BIRD_IN_MONITOR_SV

class bird_in_monitor extends uvm_monitor;

  `uvm_component_utils(bird_in_monitor)

  // Virtual interface handle (set via config_db by the agent/env)
  virtual bird_if vif;

  // Broadcasts one bird_seq_item per observed input fragment
  uvm_analysis_port #(bird_seq_item) ap;

  
  function new(string name = "bird_in_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual bird_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("BIRD_IN_MON", "Virtual interface 'vif' not set for input monitor")
    end
  endfunction

  
  // Main collection loop
  
  task run_phase(uvm_phase phase);
    // Wait until we are out of reset before collecting.
    @(posedge vif.clk);
    forever begin
      // Honour reset: if reset is asserted, drop any partial state and wait
      // for reset to deassert before collecting again.
      if (vif.rst_n === 1'b0) begin
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);
      end
      collect_fragment();
    end
  endtask

  
  task collect_fragment();
    bird_seq_item        tr;
    bit [31:0]           cfg_sampled;
    int unsigned         plen;
    byte unsigned        payload_q[$];
    bit [7:0]            crc_msb, crc_lsb;

    //1) First payload byte + cfg
    // Wait for the first valid transfer of this fragment.
    do begin
      @(posedge vif.clk);
      // Abort fragment collection cleanly if reset drops mid-wait.
      if (vif.rst_n === 1'b0) return;
    end while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1));

    // Sample cfg on the same cycle as the first payload byte (spec 2.3).
    cfg_sampled = vif.cfg;
    plen        = vif.cfg[15:8];   // PAYLOAD_LEN field

    payload_q.delete();
    payload_q.push_back(vif.data_in);   // first payload byte

    //2) Remaining payload bytes
    // We have already captured 1 byte, collect (plen - 1) more.
    // Guard against a zero/invalid PAYLOAD_LEN so we never underflow.

    if (plen >= 1) begin
      for (int i = 1; i < plen; i++) begin
        @(posedge vif.clk);
        if (vif.rst_n === 1'b0) return;        // reset aborts the fragment
        while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1)) begin
          @(posedge vif.clk);
          if (vif.rst_n === 1'b0) return;
        end
        payload_q.push_back(vif.data_in);
      end
    end

    //3) Two CRC bytes (MSB then LSB)
    collect_one_byte(crc_msb);
    if (vif.rst_n === 1'b0) return;
    collect_one_byte(crc_lsb);
    if (vif.rst_n === 1'b0) return;

    //4) Build the transaction
    tr = bird_seq_item::type_id::create("in_tr");
    tr.set_cfg(cfg_sampled);                 // unpacks all cfg fields (M2 helper)

    tr.data = new[payload_q.size()];
    foreach (payload_q[i]) tr.data[i] = payload_q[i];

    tr.crc16 = {crc_msb, crc_lsb};           // observed CRC as carried on the bus

    `uvm_info("BIRD_IN_MON",
              $sformatf("Observed input fragment: %s", tr.convert2string()),
              UVM_HIGH)

    ap.write(tr);
  endtask


  // Wait for the next valid input transfer and return the byte on data_in.
  // Implemented as a task because it must block on clock edges.
  // If reset drops while waiting, returns with rst_n low so the caller aborts.

  task automatic collect_one_byte(output bit [7:0] b);
    b = 8'h00;
    do begin
      @(posedge vif.clk);
      if (vif.rst_n === 1'b0) return;
    end while (!(vif.in_vld === 1'b1 && vif.in_rdy === 1'b1));
    b = vif.data_in;
  endtask

endclass : bird_in_monitor

`endif // BIRD_IN_MONITOR_SV
