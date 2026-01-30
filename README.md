# SDRAM Controller - SystemVerilog Implementation

A complete, fully-functional SDRAM controller designed from scratch in SystemVerilog for third-generation synchronous DRAM (SDRAM) memory systems. This controller implements all essential SDRAM operations including initialization, read/write transactions, auto-refresh, and low-power self-refresh modes.

## Overview

This project provides a modular SDRAM controller architecture that handles all aspects of SDRAM memory management. The design is fully verified using a Micron SDRAM behavioral model and includes comprehensive testbenches for each module.

**Target Platform:** Vivado 2024  
**Language:** SystemVerilog  
**Clock Frequency:** 100 MHz (10ns period)  
**Memory Type:** Third-generation SDRAM (1Meg x 16 x 4 Banks)

## Features

- **Complete SDRAM Protocol Implementation**
  - Initialization sequence with proper power-on delay (150µs)
  - Precharge, auto-refresh, and mode register configuration
  - Burst read and write operations with configurable burst length
  - Data masking (DQM) support

- **Automatic Refresh Management**
  - Auto-refresh generator with 15.5µs refresh intervals
  - Interrupt-aware write operations (aborts writes when refresh required)
  - Self-refresh mode for low-power operation

- **Timing Compliance**
  - tRCD (RAS to CAS delay): 2 cycles
  - tRP (Precharge time): 2 cycles
  - tRFC (Auto-refresh time): 7 cycles
  - tCAS (CAS latency): 3 cycles
  - tWR (Write recovery): 2 cycles

## Architecture

### Module Hierarchy

```
sdram_top_struct (Top-level integration)
├── sdram_init          - Initialization FSM
├── controller          - Main controller FSM
├── sdram_ar            - Auto-refresh generator
├── sdram_write         - Write path controller
└── (sdram_read)        - Read path controller (standalone)
```

### Core Modules

#### 1. **Initialization Module** (`sdram_init.sv`)
Handles SDRAM power-up initialization sequence:
- 150µs power-on delay
- Precharge all banks
- 2 auto-refresh cycles
- Mode register programming
- Initialization completion flag

#### 2. **Controller** (`controller.sv`)
Main FSM that arbitrates between operations:
- Manages transitions between IDLE, WRITE, and AUTO-REFRESH states
- Handles write request acceptance and auto-refresh priority
- Provides busy signal to prevent conflicts
- Supports abrupt write termination for urgent refresh

#### 3. **Auto-Refresh Module** (`sdram_ar.sv`)
Ensures SDRAM data retention:
- Generates refresh requests every ~15.5µs (1540 clock cycles)
- FSM-based refresh sequence (Precharge → Wait tRP → Auto-refresh → Wait tRFC)
- Integrates with controller for refresh arbitration

#### 4. **Self-Refresh Module** (`sdram_self_refresh.sv`)
Low-power mode implementation:
- Entry: Precharge all → Auto-refresh with CKE low
- Maintains self-refresh state while `self_ref_en` is high
- Exit: 4096 auto-refresh cycles → tXSR wait → Normal operation

#### 5. **Write Controller** (`sdram_write.sv`)
Manages SDRAM write operations:
- Row activation (ACTIVE command with row address)
- Burst write with configurable length
- Auto-precharge support (A10 bit control)
- Write interruption for auto-refresh requests
- Data masking via DQM signals
- Error detection for incomplete bursts

#### 6. **Read Controller** (`sdram_read.sv`)
Handles SDRAM read transactions:
- Row activation and CAS latency management
- Burst read with configurable length
- Read data valid signaling
- Auto-precharge or manual precharge modes
- Burst termination support

## Project Structure

```
sdram_controller/
├── src/
│   ├── controller.sv              - Main controller FSM
│   ├── sdram_init.sv              - Initialization module
│   ├── sdram_ar.sv                - Auto-refresh generator
│   ├── sdram_self_refresh.sv      - Self-refresh controller
│   ├── sdram_write.sv             - Write path controller
│   ├── sdram_read.sv              - Read path controller
│   ├── sdram_top_struct.sv        - Top-level integration
│   ├── sdram_model_plus.sv        - Micron SDRAM behavioral model
│   ├── tb_sdram_init.sv           - Initialization testbench
│   ├── tb_sdram_ar.sv             - Auto-refresh testbench
│   ├── tb_sdram_self_refresh.sv   - Self-refresh testbench
│   ├── tb_sdram_write.sv          - Write controller testbench
│   ├── tb_sdram_read.sv           - Read controller testbench
│   └── tb_sdram_top_struct.sv     - Top-level testbench
└── docs/
    ├── DRAM circuit design - a tutorial.pdf
    ├── Micron_SDRAM_Datasheet.pdf
    ├── SDRAM_Hynix_Datasheet.pdf
    └── SDRAM_operation_samsung.pdf
```

## SDRAM Command Encoding

| Command       | CS# | RAS# | CAS# | WE# | Binary |
|---------------|-----|------|------|-----|--------|
| NOP           | 0   | 1    | 1    | 1   | 0111   |
| ACTIVE        | 0   | 0    | 1    | 1   | 0011   |
| READ          | 0   | 1    | 0    | 1   | 0101   |
| WRITE         | 0   | 1    | 0    | 0   | 0100   |
| PRECHARGE     | 0   | 0    | 1    | 0   | 0010   |
| AUTO-REFRESH  | 0   | 0    | 0    | 1   | 0001   |
| BURST STOP    | 0   | 1    | 1    | 0   | 0110   |

## Key Design Decisions

### Address Mapping (25-bit)
```
[24:23] - Bank address (2 bits, 4 banks)
[22:11] - Row address (12 bits)
[10]    - Auto-precharge flag
[9:8]   - Reserved
[7:0]   - Column address (8 bits)
```

### FSM-Based Design
All modules use finite state machines for reliable timing control:
- Clear state transitions
- Clock-cycle accurate timing
- Compliant with SDRAM timing specifications

### Refresh Priority
Auto-refresh takes priority over write operations:
- Write operations can be interrupted
- Controller provides `wr_wait` signal to write module
- Write FSM handles graceful termination
- Error flag indicates incomplete bursts

## Simulation and Verification

Each module includes a dedicated testbench that:
- Uses the Micron SDRAM behavioral model
- Verifies timing compliance
- Tests all FSM states and transitions
- Validates command sequences

### Running Simulations

1. **Individual Module Testing:**
   ```tcl
   # Example: Test initialization module
   vivado -mode batch -source sim_init.tcl
   ```

2. **Top-Level Integration:**
   ```tcl
   # Test complete controller with write operations
   vivado -mode batch -source sim_top.tcl
   ```

## Technical Specifications

- **Clock Domain:** Single clock domain (100 MHz)
- **Reset:** Asynchronous active-low reset
- **Data Width:** 16 bits
- **Address Width:** 12 bits (row/column), 2 bits (bank)
- **Burst Lengths:** Configurable (tested with 8-beat bursts)
- **CAS Latency:** 3 clock cycles

## DRAM Fundamentals

This controller addresses fundamental DRAM characteristics:
- **Destructive Read:** Data must be rewritten after every read operation
- **Capacitive Storage:** Requires periodic refresh to maintain data integrity
- **Row/Column Multiplexing:** Reduces pin count through address multiplexing
- **Bank Architecture:** 4 independent banks for improved throughput

