# Multi-FPGA XSDB Programming Guide

This guide demonstrates how to reliably select, program, and run applications on the correct FPGA when multiple boards are connected to a single host machine. Each XSDB command is followed by a brief explanation for clarity. Each command is shown first, followed by a descriptive comment explaining what it does.

---

## Steps & Explanation

### Establish XSDB Connection in terminal or open in Vitis -> XSDB Console

```
xsdb
```

### 1) Connect to the Hardware Server

```
xsdb% connect
```

Establish a connection between XSDB and the local JTAG hardware server

---

### 2) List All Available Debug Targets

```
xsdb% targets
```

Shows all devices (PLs, PS CPUs, and MicroBlaze cores) detected on the JTAG chain
Helps identify the target index number for your FPGA platform and ARM Cortex-A9

---

### 3) Select the FPGA (PL) That Contains Zynq PS Configuration

```
xsdb% targets -set 80
```

Selects the target index associated with the programmable logic (PL)
The number (80 in this case) may vary depending on your setup
Ensure you pick the PL related to Zynq (xc7z020), not pure MicroBlaze devices

---

### 4) Program the FPGA Bitstream

```
xsdb% fpga -file /home/rithwik/gpio_led/gpio_led.runs/impl_1/design_1_wrapper.bit
```

Downloads the bitstream (.bit file) to the FPGA fabric (PL)
Ensures GPIO hardware is configured correctly before software execution

---

### 5) Select APU (Zynq ARM Cortex-A9 Cluster)

```
xsdb% targets -set 77
```

Selects the ARM core cluster parent for further debug control
Do NOT select MicroBlaze debug modules

---

### 6) Select ARM Core 0 as Debug Context

```
xsdb% targets -set 78
```

Chooses CPU #0 of the dual-core Zynq A9 MPCore
The app will be downloaded and executed on this core

---

### 7) Stop the Processor Before Loading Code

```
xsdb% stop
```

Halts execution at current PC address
Required before downloading the FSBL or application

---

### 8) Download and Run the FSBL (First Stage Bootloader)

```
xsdb% dow /home/rithwik/gpio_led/gpio_led.vitis/platform/zynq_fsbl/build/fsbl.elf
```

Loads the FSBL which initializes PS peripherals and configures DDR memory
Memory, SLCR, and clocks are properly setup before running the application

```
xsdb% con
```

Resume execution and let FSBL run to completion

---

### 9) Download the Application into DDR

```
xsdb% dow /home/rithwik/gpio_led/gpio_led.vitis/xgpio_example/build/xgpio_example.elf
```

Loads your bare-metal user application into DDR
Sets PC to the start address of the program

---

### 10) Run the Application

```
xsdb% con
```

Starts program execution on ARM Cortex-A9 Core 0
GPIO LEDs should toggle as per example functionality

---

### Optional: Stop CPU Execution

```
xsdb% stop
```

Halts program execution to observe and debug state

---

## Notes

* Target numbers change system-to-system → always run `targets` first
* Ensure FSBL is always run before the main application to initialize DDR
* If multiple Zynq boards exist, verify xc7z020 target entries correctly
* Script works over both local JTAG and remote servers

---

## Automation Tip

These XSDB commands can be saved to a `.tcl` script and executed using:

```
xsdb -source script_name.tcl
```

// Fully automates FPGA programming + application run flow

---

This documentation allows convenient and correct programming/debugging when multiple FPGA targets are connected simultaneously.
