`ifndef BIRD_ENV_SV
`define BIRD_ENV_SV

import bird_pkg::*;

class bird_env;

  virtual bird_if vif;

  mailbox #(bird_packet)   input_mbx;
  mailbox #(bird_packet)   coverage_mbx;
  mailbox #(byte unsigned) local_mbx;
  mailbox #(bit [31:0])    remote_mbx;

  bird_driver         driver;
  bird_input_monitor  input_monitor;
  bird_local_monitor  local_monitor;
  bird_remote_monitor remote_monitor;
  bird_scoreboard     scoreboard;
  bird_coverage       coverage;

  // new()
  // Creates the environment infrastructure only.  Test stimulus stays inside
  // the individual test files; this class only owns common components.
  function new(virtual bird_if vif);
    this.vif = vif;
    connect();
  endfunction

  // connect()
  // Creates and wires the common mailboxes/components exactly once.
  function void connect();
    if (driver != null) begin
      return;
    end

    input_mbx    = new();
    coverage_mbx = new();
    local_mbx    = new();
    remote_mbx   = new();

    driver         = new(vif);
    input_monitor  = new(vif, input_mbx, coverage_mbx);
    local_monitor  = new(vif, local_mbx);
    remote_monitor = new(vif, remote_mbx);
    scoreboard     = new(vif, input_mbx, local_mbx, remote_mbx);
    coverage       = new(coverage_mbx);

    $display("[%0t] ENV: Components created and connected", $time);
  endfunction

  // start_monitors()
  // Launches passive infrastructure threads.  The driver is not started here;
  // each test drives its own packets through env.driver.drive_packet().
  task start_monitors();
    $display("[%0t] ENV: Starting monitors, scoreboard, and coverage", $time);
    fork
      input_monitor.run();
      local_monitor.run();
      remote_monitor.run();
      scoreboard.run();
      coverage.run();
    join_none
  endtask

  // report()
  // Prints checker and functional coverage summaries.
  task report();
    scoreboard.report();
    coverage.report();
  endtask

  // wait_cycles()
  // Shared timing utility only.
  task wait_cycles(input int cycles);
    repeat (cycles) @(vif.drv_cb);
  endtask

endclass : bird_env

`endif
