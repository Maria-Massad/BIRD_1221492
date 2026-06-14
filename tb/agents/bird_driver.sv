//=============================================================================
// Driver behavior:
//   - Holds cfg stable for the full fragment.
//   - Sends payload bytes first.
//   - Sends CRC16 immediately after payload, MSB then LSB.
//   - Uses valid/ready handshake.
//   - When in_vld=1 and in_rdy=0, keeps in_vld, data_in, and cfg stable.
//
// NOTE:
//   This driver matches the provided bird_if.sv clocking block name:
//     driver_cb
//=============================================================================

`ifndef BIRD_DRIVER_SV
`define BIRD_DRIVER_SV

class bird_driver extends uvm_driver #(bird_seq_item);

  `uvm_component_utils(bird_driver)

  virtual bird_if vif;

  function new(string name = "bird_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual bird_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("BIRD_DRV", "Virtual interface 'vif' not set for bird_driver")
    end
  endfunction

  task run_phase(uvm_phase phase);
    bird_seq_item req;

    drive_idle();
    wait_for_reset_deassert();

    forever begin
      seq_item_port.get_next_item(req);

      `uvm_info("BIRD_DRV",
                $sformatf("Driving item: %s", req.convert2string()),
                UVM_MEDIUM)

      drive_fragment(req);

      seq_item_port.item_done();
    end
  endtask

  task drive_idle();
    vif.driver_cb.in_vld  <= 1'b0;
    vif.driver_cb.data_in <= 8'h00;
    vif.driver_cb.cfg     <= 32'h0000_0000;

    // Keep output consumers ready during simple Phase 1 bring-up.
    // This prevents DUT output queues from stalling.
    vif.driver_cb.local_rdy  <= 1'b1;
    vif.driver_cb.remote_rdy <= 1'b1;
  endtask

  task wait_for_reset_deassert();
    while (vif.rst_n !== 1'b1) begin
      @(vif.driver_cb);
    end

    @(vif.driver_cb);
  endtask

  task drive_fragment(bird_seq_item req);
    bit [31:0]    cfg_word;
    byte unsigned stream[$];

    cfg_word = req.get_cfg();
    req.get_input_stream(stream);

    foreach (stream[i]) begin
      drive_byte_with_backpressure(stream[i], cfg_word);
    end

    drive_idle();

    // One idle cycle between fragments/items.
    @(vif.driver_cb);
  endtask

  task drive_byte_with_backpressure(byte unsigned data_byte,
                                    bit [31:0] cfg_word);

    vif.driver_cb.in_vld  <= 1'b1;
    vif.driver_cb.data_in <= data_byte;
    vif.driver_cb.cfg     <= cfg_word;

    @(vif.driver_cb);

    while (vif.driver_cb.in_rdy !== 1'b1) begin
      @(vif.driver_cb);
    end
  endtask

endclass : bird_driver

`endif // BIRD_DRIVER_SV
