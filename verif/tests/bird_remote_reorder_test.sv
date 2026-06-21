import bird_pkg::*;
`ifndef BIRD_REMOTE_REORDER_TEST_SV
`define BIRD_REMOTE_REORDER_TEST_SV

class bird_remote_reorder_test;

  bird_env env;
  bird_remote_generator remote_gen;

  function new(bird_env env);
    this.env        = env;
    this.remote_gen = new();
  endfunction

  task run();
    bird_packet frag1;
    bird_packet frag2;

    $display("============================================================");
    $display("TEST START: bird_remote_reorder_test");
    $display("============================================================");

    frag1 = remote_gen.create_two_fragment_packet_frag1();
    frag2 = remote_gen.create_two_fragment_packet_frag2();

    env.coverage.sample_packet(frag2);
    env.coverage.sample_packet(frag1);
    env.coverage.sample_reorder(1'b1);

    env.driver.drive_packet(frag2);
    env.driver.idle(2);
    env.driver.drive_packet(frag1);

    env.wait_cycles(30);

    $display("============================================================");
    $display("TEST END: bird_remote_reorder_test");
    $display("============================================================");
  endtask

endclass

`endif
