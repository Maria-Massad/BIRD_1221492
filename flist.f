-sverilog
-timescale=1ns/1ps
-debug_access+all

+incdir+./design
+incdir+./verif/tb
+incdir+./verif/tb/agents
+incdir+./verif/tb/checkers
+incdir+./verif/tb/env
+incdir+./verif/tb/generators
+incdir+./verif/tb/interface
+incdir+./verif/tb/monitors
+incdir+./verif/tb/sequences
+incdir+./verif/tb/tests
+incdir+./coverage/func_coverage

./design/*.sv
./verif/tb/interface/*.sv
./verif/tb/bird_tb.sv
