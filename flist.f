-sverilog
-timescale=1ns/1ps
-debug_access+all
-cm line+cond+tgl+branch+fsm

+incdir+./verif/cfg
+incdir+./verif/env
+incdir+./verif/if
+incdir+./verif/seq
+incdir+./verif/tb
+incdir+./verif/tests


./design/bird.sv

./verif/if/bird_if.sv

./verif/env/bird_pkg.sv
./verif/env/bird_local_generator.sv
./verif/env/bird_remote_generator.sv
./verif/env/bird_drop_generator.sv
./verif/env/bird_driver.sv
./verif/env/bird_input_monitor.sv
./verif/env/bird_local_monitor.sv
./verif/env/bird_remote_monitor.sv
./verif/env/bird_scoreboard.sv
./verif/env/bird_assertions.sv
./verif/env/bird_coverage.sv
./verif/env/bird_env.sv

./verif/seq/bird_rand_seq.sv

./verif/tests/bird_drop_conditions_test.sv
./verif/tests/bird_backpressure_test.sv
./verif/tests/bird_remote_reorder_test.sv
./verif/tests/bird_reset_test.sv
./verif/tests/bird_sanity_test.sv
./verif/tests/bird_drop_test_a.sv
./verif/tests/bird_remote_full_test.sv
./verif/tests/bird_drop_full_test.sv
./verif/tests/bird_proto_full_test.sv
./verif/tests/bird_loc_full_test.sv
./verif/tests/bird_legacy_extra_test.sv
./verif/tests/bird_coverage_boost_test.sv

./verif/tb/bird_tb.sv
