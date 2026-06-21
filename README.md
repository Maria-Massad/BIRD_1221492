cd C:\Users\Admin\Desktop\BIRD

@'
# BIRD - Birzeit Integrated Router Design

SystemVerilog verification environment for BIRD, a packet-based routing block.

Course project for ENCS5337 - Chip Design Verification.  
Birzeit University, Second Semester 2025/2026.

Server folder: BIRD_1221492

## Overview

BIRD receives packets through one input interface and routes them to one of two output interfaces: local or remote.

Local traffic is forwarded directly to the local output interface.

Remote traffic is received as one or more fragments. The fragments are accumulated, reordered according to their fragment number, merged into one payload, and then transmitted on the remote output interface with a regenerated CRC16.

Invalid or malformed packets are silently dropped, and the drop counter `drop_cnt` is incremented. Packet routing and processing are controlled by the 32-bit sideband configuration word `cfg`.

## Repository structure

```text
BIRD/
│
├── coverage/
│   ├── code_coverage/
│   └── func_coverage/
│
├── design/
│   └── bird.sv
│
├── sim/
│
├── test_plan/
│
├── verif/
│   │
│   ├── cfg/
│   │   └── optional configuration files
│   │
│   ├── env/
│   │   ├── bird_env.sv
│   │   ├── bird_driver.sv
│   │   ├── bird_monitor.sv
│   │   ├── bird_input_monitor.sv
│   │   ├── bird_local_monitor.sv
│   │   ├── bird_remote_monitor.sv
│   │   ├── bird_scoreboard.sv
│   │   ├── bird_assertions.sv
│   │   ├── bird_packet.sv
│   │   ├── bird_pkg.sv
│   │   └── bird_coverage.sv
│   │
│   ├── if/
│   │   └── bird_if.sv
│   │
│   ├── seq/
│   │   ├── bird_base_seq.sv
│   │   ├── bird_local_seq.sv
│   │   ├── bird_remote_seq.sv
│   │   ├── bird_random_seq.sv
│   │   ├── bird_drop_seq.sv
│   │   └── bird_backpressure_seq.sv
│   │
│   ├── tb/
│   │   └── bird_tb.sv
│   │
│   └── tests/
│       ├── bird_sanity_test.sv
│       ├── bird_reset_test.sv
│       ├── bird_drop_conditions_test.sv
│       ├── bird_backpressure_test.sv
│       ├── bird_remote_reorder_test.sv
│       ├── bird_drop_full_test.sv
│       ├── bird_legacy_extra_test.sv
│       ├── bird_loc_full_test.sv
│       ├── bird_proto_full_test.sv
│       └── bird_remote_full_test.sv
│
├── flist.f
├── verdi_config_file
└── README.md