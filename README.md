# BIRD - Birzeit Integrated Router Design

UVM verification environment for BIRD, a packet-based routing block.
Course project for ENCS5337 - Chip Design Verification.
Birzeit University, Second Semester 2025/2026.

Server folder: BIRD_1221492

## Overview

BIRD receives packets on a single input interface and routes them to one of two outputs:

- Local traffic: forwarded directly to the local output.
- Remote traffic: received as fragments, accumulated, reordered, merged, and emitted as one packet with a regenerated CRC16.

Invalid packets are silently dropped and counted in drop_cnt.
Routing is driven by a 32-bit cfg sideband word.

## Repository structure

- tb/interface  : bird_if.sv, clocking blocks, tb_top.sv
- tb/env        : bird_env.sv, bird_pkg.sv
- tb/agents     : driver, monitors, agent, sequencer
- tb/sequences  : bird_seq_item.sv, sequence classes
- tb/tests      : base test + individual test classes
- tb/checkers   : scoreboards (local + remote), coverage
- dut/          : bird.sv (design under test)
- sim/          : run scripts / filelist / Makefile
- coverage/code_coverage : code coverage report
- coverage/func_coverage : functional coverage report
- test_plan/    : test_plan.xlsx

## Team

- Member 1: Interface + local tests + local scoreboard
- Member 2: Driver + sequences + remote scoreboard (CRC16)
- Member 3: Monitors + agent + coverage + drop tests
- Member 4: Env + package + base test + reset/stress + reporting

## Build and run

To be completed once the run setup in sim/ is in place.
