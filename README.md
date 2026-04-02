# XSDB Automation Guide for Zynq FPGA Programming and Application Execution

This guide defines a parameterized workflow for automating programming and execution on a Zynq platform using an XSDB `.tcl` script. Hardcoded paths are eliminated using variables.

---

## What This Script Does

End-to-end execution:

1. System reset
2. Hardware server connection
3. Target discovery and selection
4. Bitstream download to PL
5. FSBL execution (PS initialization)
6. Application ELF execution
7. Post-run delay and system reset

---

## Script Name

```
program.tcl
```

---

## Required Variables (Defined in Script)

```tcl
set PROJECT_NAME "gpio_led"
set USERNAME "rithwik"
```

All file paths derive from these variables. Changing project or user requires modifying only these two.

---

## Step-by-Step Explanation

### 1) Reset System

```tcl
puts "Initial RESET SYSTEM AND WAIT FOR 2s"
rst -system
after 2000
```

Ensures deterministic startup state.
Failure case: active PL target selected → reset error.
Mitigation: comment this block on first execution or ensure APU context before reset.

---

### 2) Connect to Hardware Server

```tcl
connect
after 2000
```

Attaches XSDB to `hw_server`. Required before any JTAG interaction.

---

### 3) Enumerate Targets

```tcl
targets
after 2000
```

Displays JTAG chain. Required for identifying dynamic target IDs.

---

### 4) Program FPGA (PL)

```tcl
targets -set 34
after 2000

puts "Programming the FPGA..."
fpga -file "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000
```

* Selects PL device
* Downloads bitstream

Constraint: target ID must correspond to FPGA fabric.

---

### 5) Select Processing System (APU)

```tcl
targets -set 31
after 2000

targets -set 32
after 2000
```

* First: APU cluster
* Second: Cortex-A9 Core 0

Execution always binds to selected core.

---

### 6) Load FSBL

```tcl
stop
after 2000

puts "Flashing the First Stage Boot Loader..."
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/platform/zynq_fsbl/build/fsbl.elf"
puts "Completed FSBL Flashing!"

after 2000
con
after 2000
```

FSBL responsibilities:

* DDR initialization
* Clock configuration
* Peripheral enablement

Without FSBL, application execution is undefined.

---

### 7) Load Application ELF

```tcl
puts "Flashing your application..."
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/xgpio_example/build/xgpio_example.elf"
puts "Completed Flashing!"

after 2000
con
```

Loads executable into DDR and starts execution.

---

### 8) Delay and Reset

```tcl
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"

after 60000

rst -system
puts "Completed the task and reset has been applied"
```

* Provides observation/debug window
* Restores system to known idle state

---

## File Path Abstraction

All critical paths are derived as:

```
/home/$USERNAME/$PROJECT_NAME/
```

### Examples

| Artifact    | Path                                                        |
| ----------- | ----------------------------------------------------------- |
| Bitstream   | `$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit`            |
| FSBL        | `$PROJECT_NAME.vitis/platform/zynq_fsbl/build/fsbl.elf`     |
| Application | `$PROJECT_NAME.vitis/xgpio_example/build/xgpio_example.elf` |

---

## Constraints

* Target IDs are **non-deterministic across sessions**
* `after` delays are **timing-critical** (XSDB is not synchronous)
* FSBL must always execute before application
* CPU must be stopped before `dow`

---

## Execution

```bash
xsdb
source ./program.tcl
```

---

## Failure Modes

| Symptom              | Root Cause               |
| -------------------- | ------------------------ |
| `fpga` fails         | Wrong PL target ID       |
| `dow` hangs          | CPU not stopped          |
| App not running      | FSBL not executed        |
| Reset error          | Incorrect target context |
| No hardware detected | `hw_server` not running  |

---

## Operational Advantage

* Removes manual XSDB sequencing
* Enforces deterministic bring-up
* Reduces configuration drift
* Enables repeatable validation cycles
* Minimizes human-induced latency and error

---
