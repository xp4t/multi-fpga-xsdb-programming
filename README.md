# XSDB Automation Guide for Zynq FPGA Programming and Application Execution

This guide defines a parameterized workflow for automating programming and execution on a Zynq platform using an XSDB `.tcl` script. Hardcoded paths and target IDs are eliminated using variables and name-based target filters.

---

## What This Script Does

End-to-end execution:

1. Hardware server connection
2. Target discovery (optional diagnostic)
3. PL target selection (by device name filter)
4. Bitstream download to PL
5. APU / Cortex-A9 core selection (by name filter)
6. FSBL execution (PS initialization)
7. Application ELF execution
8. Post-run delay, optional serial monitor, and system reset

---

## Script Name

```
program.tcl
```

---

## Required Variables (Defined in Script)

```tcl
# ===================== USER CONFIG =====================
set PROJECT_NAME "your_project_name"
set USERNAME "your_username"
set APP_NAME "app_component"
# ======================================================
```

All file paths derive from these three variables. Changing project, user, or application requires modifying only this block.

> **Important — Vitis workspace naming convention:**
> The script assumes your Vitis workspace folder is named `$PROJECT_NAME.vitis` (e.g. `gpio_led.vitis`), sitting alongside your Vivado project folder (`$PROJECT_NAME` / `$PROJECT_NAME.runs`). If your Vitis workspace uses a different name, either rename it to match this convention, or manually edit the `dow` paths in Steps 6 and 7 of the script to point to your actual workspace directory.

---

## Step-by-Step Explanation

### 0) Initial System Reset (optional, first run only)

```tcl
# puts "Initial RESET SYSTEM AND WAIT FOR 2s"
# rst -system
# after 2000
```

Commented out by default. Ensures deterministic startup state, but is only needed on the **first** invocation of a debug session.
Failure case: running this with an active PL target already selected → reset error.
Mitigation: leave commented for repeat runs within the same session; uncomment only when starting fresh. Not usually required.

---

### 1) Connect to Hardware Server

```tcl
connect
after 2000
```

Attaches XSDB to `hw_server`. Required before any JTAG interaction.

---

### 2) Enumerate Targets (optional diagnostic)

```tcl
targets
after 2000
```

Displays the JTAG chain. Useful for confirming device names before relying on the filters below — not required for the automated flow to function, but helpful for debugging target-selection issues.

---

### 3) Program FPGA (PL)

```tcl
targets -set -filter {name =~ "xc7z020"}
after 2000

puts "Programming the FPGA..."
fpga -file "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000
```

* Selects the PL device by **name filter** instead of a numeric target ID.
* Downloads the bitstream.

Constraint: the filter string (`xc7z020`) must match your specific Zynq part. Update this if you're using a different device (e.g. `xc7z010`, `xc7z030`).If you are having multiple (`xc7z020`) then provide numeric target ID

**Improvement over ID-based selection:** target IDs shift between sessions and hardware server restarts, but device/core names are stable — so filter-based selection (`-filter {name =~ "..."}`) is significantly more reliable for automation than hardcoded numeric IDs.

---

### 4) Select Processing System (APU)

```tcl
targets -set -filter {name =~ "APU"}
after 2000

targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}
after 2000
```

* First: selects the APU parent context
* Second: selects Cortex-A9 Core 0 for debug

Execution always binds to the last-selected core.

---

### 5) Stop CPU Before Loading FSBL

```tcl
stop
after 2000
```

The CPU must be halted before `dow` (download) operations; downloading to a running core produces undefined behavior or a hang.

---

### 6) Load FSBL

```tcl
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

### 7) Load and Run Application ELF

```tcl
puts "Flashing your application..."
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/$APP_NAME/build/$APP_NAME.elf"
puts "Completed Flashing!"

after 2000
con
```

Loads the executable into DDR and starts execution. The application name is now parameterized via `$APP_NAME`, so switching applications no longer requires editing the path by hand.

---

### 8) Post-Run Delay, Serial Monitor, and Reset

```tcl
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"

# Uncomment only if you require a serial monitor for printing texts
puts "Displaying Serial Monitor"
#exec putty -serial /dev/ttyPYNQ1 -sercfg 115200,8,n,1,N

after 60000

rst -system
puts "Completed the task and reset has been applied"
```

* Provides a 60-second observation/debug window
* Optionally launches a serial terminal (PuTTY) to view UART output — uncomment the `exec putty ...` line and adjust the serial device (`/dev/ttyPYNQ1`) and baud settings to match your setup
* Restores the system to a known idle state via `rst -system`

---

## File Path Abstraction

All critical paths are derived as:

```
/home/$USERNAME/$PROJECT_NAME/
```

### Examples

| Artifact    | Path                                                      |
| ----------- | ---------------------------------------------------------- |
| Bitstream   | `$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit`            |
| FSBL        | `$PROJECT_NAME.vitis/platform/zynq_fsbl/build/fsbl.elf`     |
| Application | `$PROJECT_NAME.vitis/$APP_NAME/build/$APP_NAME.elf`         |

**Note:** The `$PROJECT_NAME.vitis` folder name is a required convention for this script — see the callout under "Required Variables" above.

---

## Constraints

* Filter strings (`-filter {name =~ "..."}`) must match your specific part number and core naming — verify with `targets` if selection fails
* `after` delays are **timing-critical** (XSDB is not synchronous)
* FSBL must always execute before the application
* CPU must be stopped (`stop`) before any `dow` operation
* Vitis workspace directory must be named `$PROJECT_NAME.vitis`, or the `dow` paths must be edited manually

---

## Execution

```bash
xsdb
source ./program.tcl
```

---

## Failure Modes

| Symptom              | Root Cause                                      |
| --------------------- | ------------------------------------------------ |
| `fpga` fails          | PL target filter doesn't match connected device |
| `dow` hangs           | CPU not stopped                                 |
| App not running       | FSBL not executed                               |
| Reset error           | Incorrect target context / reset run mid-session |
| No hardware detected  | `hw_server` not running                         |
| Target filter matches nothing | Device/core name differs from filter string — run `targets` to check actual names |

---

## Operational Advantage

* Removes manual XSDB sequencing
* Uses stable name-based target filters instead of session-dependent numeric IDs
* Enforces deterministic bring-up
* Reduces configuration drift
* Parameterizes the application name (`$APP_NAME`) alongside project and user
* Enables repeatable validation cycles
* Minimizes human-induced latency and error

---
