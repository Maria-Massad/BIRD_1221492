//=============================================================================
// bird_env.sv
// Environment — infrastructure only, NO test logic
// Reference: BIRD Functional Specification
//=============================================================================
`ifndef BIRD_ENV_SV
`define BIRD_ENV_SV

class bird_env;

  virtual bird_if vif;

  // Mailboxes — connect monitors to scoreboard
  mailbox #(bird_packet)   input_mbx;
  mailbox #(byte unsigned) local_mbx;
  mailbox #(bit [31:0])    remote_mbx;

  // Components
  bird_driver         driver;
  bird_input_monitor  input_monitor;
  bird_local_monitor  local_monitor;
  bird_remote_monitor remote_monitor;
  bird_scoreboard     scoreboard;
  bird_coverage       coverage;

  // Generators (act as sequences)
  bird_local_generator  local_gen;
  bird_remote_generator remote_gen;
  bird_drop_generator   drop_gen;

  //-------------------------------------------------------------------------
  // new() — create and wire all components
  //-------------------------------------------------------------------------
  function new(virtual bird_if vif);
    this.vif   = vif;
    input_mbx  = new();
    local_mbx  = new();
    remote_mbx = new();
    driver         = new(vif.DRIVER);
    input_monitor  = new(vif.MONITOR, input_mbx);
    local_monitor  = new(vif.MONITOR, local_mbx);
    remote_monitor = new(vif.MONITOR, remote_mbx);
    scoreboard     = new(input_mbx, local_mbx, remote_mbx);
    coverage       = new();
    local_gen      = new();
    remote_gen     = new();
    drop_gen       = new();
  endfunction

  //-------------------------------------------------------------------------
  // init() — safe defaults before any test
  //-------------------------------------------------------------------------
  task init();
    driver.reset_driver_signals();
    scoreboard.clear();
    $display("[%0t] ENV: Initialized", $time);
  endtask

  //-------------------------------------------------------------------------
  // start_monitors() — launch monitors and scoreboard in background
  //-------------------------------------------------------------------------
  task start_monitors();
    fork
      input_monitor.run();
      local_monitor.run();
      remote_monitor.run();
    join_none
    scoreboard.run();
    $display("[%0t] ENV: Monitors started", $time);
  endtask

  //-------------------------------------------------------------------------
  // wait_cycles() — wait N clock cycles
  //-------------------------------------------------------------------------
  task wait_cycles(input int cycles);
    repeat (cycles) @(posedge vif.clk);
  endtask

  //-------------------------------------------------------------------------
  // wait_outputs_idle() — wait until both outputs quiet
  // Use between tests to prevent data leaking
  //-------------------------------------------------------------------------
  task wait_outputs_idle();
    int idle_count = 0;
    while (idle_count < 10) begin
      @(vif.mon_cb);
      if (!vif.mon_cb.local_vld && !vif.mon_cb.remote_vld)
        idle_count++;
      else
        idle_count = 0;
    end
  endtask

  //-------------------------------------------------------------------------
  // drain_mailboxes() — flush leftover items between tests
  //-------------------------------------------------------------------------
  task drain_mailboxes();
    bird_packet   tmp_pkt;
    byte unsigned tmp_byte;
    bit [31:0]    tmp_word;
    while (input_mbx.try_get(tmp_pkt))  ;
    while (local_mbx.try_get(tmp_byte)) ;
    while (remote_mbx.try_get(tmp_word)) ;
  endtask

  //-------------------------------------------------------------------------
  // prepare_for_test() — call at start of every test
  //-------------------------------------------------------------------------
  task prepare_for_test();
    scoreboard.clear();
    drain_mailboxes();
  endtask

  //-------------------------------------------------------------------------
  // report() — final scoreboard + coverage summary
  //-------------------------------------------------------------------------
  function void report();
    scoreboard.summary();
    coverage.report();
  endfunction

endclass

`endif
