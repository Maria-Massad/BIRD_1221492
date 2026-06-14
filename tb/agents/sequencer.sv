//=============================================================================
// Sequencer for BIRD input transactions.
//=============================================================================

`ifndef BIRD_SEQUENCER_SV
`define BIRD_SEQUENCER_SV

class bird_sequencer extends uvm_sequencer #(bird_seq_item);

  `uvm_component_utils(bird_sequencer)

  function new(string name = "bird_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : bird_sequencer

`endif // BIRD_SEQUENCER_SV

