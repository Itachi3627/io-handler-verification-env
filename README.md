# io-handler-verification-env

## Overview

The **io-handler-verification-env** repository contains a complete SystemVerilog verification environment for the `IO_Handler` module. The environment is a pure SystemVerilog (SV) class-based testbench designed to verify memory-mapped I/O operations, interrupt logic, and register integrity without reliance on UVM methodology.

## EDA Playground Demo

**Try it online:** [https://www.edaplayground.com/x/ecaW](https://www.edaplayground.com/x/ecaW)

This project is ready to run on EDA Playground using **Cadence Xcelium** simulator.

## Architecture

The testbench follows a layered architecture:

| Component | Description |
| :--- | :--- |
| **Interface** (`interface.sv`) | Defines signal bundles, clocking blocks (`drv_cb`, `mon_cb`) for synchronization, and modports to restrict access rights. |
| **Transaction** (`transaction.sv`) | The base object representing a bus cycle. Includes constraints to target specific memory maps and legal address ranges. |
| **Generator** (`generator.sv`) | Creates randomized `transaction` objects and passes them to the driver via a mailbox. |
| **Driver** (`driver.sv`) | Converts high-level transactions into pin-level signal toggles, adhering to the bus protocol (Address → Write/Read Enable → Data). |
| **Monitor** (`monitor.sv`) | Passively samples the interface. It synchronizes with the clock, waits for DUT response logic, and reconstructs the transaction for analysis. |
| **Scoreboard** (`scoreboard.sv`) | The "Golden Model." It maintains a shadow copy of the internal registers (Data In, Data Out, Control, Status) to predict expected read data and IRQ behavior. |
| **Coverage** (`coverage.sv`) | Collects functional coverage metrics, tracking register access (DATA_IN vs CTRL), specific port usage, and data corner cases (0x00, 0xFF). |
| **Environment** (`environment.sv`) | The container class that instantiates all components and connects their mailboxes. |

## Key Architectural Features

### Layered Approach
Separates signal-level activity (Driver/Monitor) from high-level logic (Generator/Scoreboard) for better maintainability and reusability.

### Transaction-Level Modeling
Data is passed between components as high-level transaction objects rather than raw bits, enabling cleaner abstractions and easier debugging.

### Self-Checking
The scoreboard contains a reference model that mirrors the DUT's internal register state (data_in, data_out, control, status) to predict expected outputs.

### Functional Coverage
A dedicated coverage class tracks which registers, ports, and corner-case values (e.g., 0x00, 0xFF) have been exercised.

## Data Flow

```
   ┌──────────────┐
   │  Generator   │  Creates randomized transactions
   └──────┬───────┘
          │ (Mailbox)
          ▼
   ┌──────────────┐
   │   Driver     │  Drives physical signals via interface
   └──────┬───────┘
          │
          ▼
   ┌──────────────┐        ┌──────────────┐
   │  IO_Handler  │◄──────►│   Monitor    │  Samples interface signals
   │     DUT      │        └──────┬───────┘
   └──────────────┘               │
                                  ├────────► Scoreboard (checking)
                                  └────────► Coverage (analysis)
```

## Verification Features

### Reference Model
The scoreboard implements a full replica of the 4-port IO logic:
* **Write Logic:** Updates shadow registers (`ref_data_out`, `ref_control`) on valid writes.
* **Read Logic:** Predicts `io_rdata` based on the requested address.
* **IRQ Logic:** Predicts interrupt assertions based on input changes and control register settings; verifies "Read-to-Clear" behavior on the Status register.

### Constraints
The `transaction` class includes constraints to ensure valid testing:
* **Address Decoding:** Distributes traffic evenly across the 4 internal registers (`DATA_IN`, `DATA_OUT`, `CTRL`, `STATUS`).
* **Port Selection:** Weighs traffic toward valid ports (0-3) while occasionally injecting invalid port addresses to test robustness.
* **Read/Write Ratio:** Maintains a 50/50 split between read and write operations.

## Directory Structure

```
verification_env/
├── rtl/
│   └── design.sv           # The IO_Handler DUT
├── tb/
│   ├── interface.sv        # Interface with modports and clocking blocks
│   ├── transaction.sv      # Transaction data class with randomization constraints
│   ├── generator.sv        # Generates constrained random stimulus
│   ├── driver.sv           # Drives packet data to pins
│   ├── monitor.sv          # Samples pins to reconstruct packets
│   ├── scoreboard.sv       # Reference model and checker
│   ├── coverage.sv         # Functional coverage groups and bins
│   ├── environment.sv      # Container class connecting all components
│   └── top.sv              # Top-level testbench module
├── README.md               # This file
└── LICENSE                 # MIT License
```

## Simulation Output

### Console Logs
During simulation, you'll see detailed logs from each component:
```
[SCOREBOARD] Transaction #1: PASS
[MONITOR] Captured Write to CTRL register
[COVERAGE] Port 2 accessed - coverage updated
```

### Status Reports
At the end of simulation, the Scoreboard reports:
* **Total Transactions** executed
* **Pass/Fail Counts** for each transaction
* **Final Pass Rate (%)** indicating verification quality

### Waveform Output
A VCD file (`waveform.vcd`) is generated for signal-level debugging and protocol verification.

### Coverage Reports
When using the `run.bash` script or `-coverage all` option, Xcelium generates comprehensive coverage databases:

#### Viewing Coverage (IMC - Interactive Metrics Center)
```bash
imc &
```

Then load the coverage database to view:
- **Code Coverage:** Line, branch, condition, and expression coverage
- **Functional Coverage:** Covergroup and coverpoint hit statistics
- **Coverage Summary:** Overall metrics and coverage holes

#### Coverage Database Location
```
xcelium.d/
├── cov_work/         # Coverage database
└── coverage.vdb/     # Merged coverage data
```

#### Key Coverage Metrics to Monitor
1. **Register Access Coverage:** All 4 registers accessed (DATA_IN, DATA_OUT, CTRL, STATUS)
2. **Port Coverage:** All 4 ports exercised (0-3)
3. **Corner Case Coverage:** Boundary values tested (0x00, 0xFF)
4. **Operation Coverage:** Read and write operations balanced

## Customization

### Adjusting Test Length
Modify the transaction count in `tb/top.sv`:
```systemverilog
initial begin
  env = new(vif);
  env.gen.num_transactions = 100;  // Change this value
  env.run();
end
```

### Modifying Constraints
Edit `tb/transaction.sv` to adjust:
* Address distribution weights
* Read/write ratio
* Port selection probability
* Data value ranges

### Coverage Goals
Update `tb/coverage.sv` to add new coverpoints:
* Specific register field combinations
* Protocol corner cases
* Back-to-back transaction scenarios

### Running Without Coverage
If you need faster simulation without coverage overhead:
```bash
xrun -Q -unbuffered -timescale 1ns/1ns -sysv -access +rw design.sv testbench.sv
```

## Coverage Analysis Best Practices

### Achieving 100% Coverage
1. **Review Coverage Holes:** Use IMC to identify untested scenarios
2. **Add Directed Tests:** Create specific test cases for missed conditions
3. **Adjust Constraints:** Modify transaction constraints to hit corner cases
4. **Increase Transaction Count:** Run longer simulations for random coverage

### Coverage Closure Checklist
- [ ] All registers read and written
- [ ] All ports (0-3) accessed
- [ ] Boundary values tested (0x00, 0xFF, mid-range)
- [ ] Interrupt scenarios covered (assertion, clearing)
- [ ] Back-to-back transactions tested
- [ ] Read-after-write scenarios verified

## Requirements

* SystemVerilog-compatible simulator (IEEE 1800-2012 or later)
* Recommended: Cadence Xcelium, Synopsys VCS, Mentor Questa, or Xilinx Vivado

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## Support

For questions or issues:
* Open an issue in this repository
* Try the interactive demo on EDA Playground: [https://www.edaplayground.com/x/fH77](https://www.edaplayground.com/x/fH77)