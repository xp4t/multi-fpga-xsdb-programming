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
Like 

```
  1  xc7a100t                                                                   
     2  MicroBlaze Debug Module at USER2
        3  MicroBlaze #0 (Running)
  4  xc7a100t
     5  MicroBlaze Debug Module at USER2
        6  MicroBlaze #0 (Running)
  7  xc7a100t
     8  MicroBlaze Debug Module at USER2
        9  MicroBlaze #0 (Running)
 10  xc7a100t
 11  xc7a100t
    12  MicroBlaze Debug Module at USER2
       13  MicroBlaze #0 (Running)
 14  xc7a100t
    15  MicroBlaze Debug Module at USER2
       16  MicroBlaze #0 (Running)
 17  xc7a100t
    18  MicroBlaze Debug Module at USER2
       19  MicroBlaze #0 (Running)
 20  xc7a100t
    21  MicroBlaze Debug Module at USER2
       22  MicroBlaze #0 (Running)
 23  APU
    24  ARM Cortex-A9 MPCore #0 (Running)
    25  ARM Cortex-A9 MPCore #1 (Running)
 26  xc7z020
 27  xc7a100t
 28  xc7a100t
    29  MicroBlaze Debug Module at USER2
       30  MicroBlaze #0 (Running)
 31  APU
    32  ARM Cortex-A9 MPCore #0 (Running)
    33  ARM Cortex-A9 MPCore #1 (Running)
 34  xc7z020
 35  xc7a100t
 36  xc7a100t
    37  MicroBlaze Debug Module at USER2
       38  MicroBlaze #0 (Running)
 39  xc7a100t
    40  MicroBlaze Debug Module at USER2
       41  MicroBlaze #0 (Running)
 42  xc7a100t
 43  xc7a100t
    44  MicroBlaze Debug Module at USER2
       45  MicroBlaze #0 (Running)
 46  xc7a100t
    47  MicroBlaze Debug Module at USER2
       48  MicroBlaze #0 (Running)
 49  xc7a100t
 50  xc7a100t
    51  MicroBlaze Debug Module at USER2
       52  MicroBlaze #0 (Running)
 53  xc7a100t
 54  xc7a100t
    55  MicroBlaze Debug Module at USER2
       56  MicroBlaze #0 (Running)
 57  APU
    58  ARM Cortex-A9 MPCore #0 (Running)
    59  ARM Cortex-A9 MPCore #1 (Running)
 60  xc7z020
 61  xc7a100t
    62  MicroBlaze Debug Module at USER2
       63  MicroBlaze #0 (Running)
 64  xc7a100t
 65  xc7a100t
    66  MicroBlaze Debug Module at USER2
       67  MicroBlaze #0 (Running)
 68  xc7a100t
    69  MicroBlaze Debug Module at USER2
       70  MicroBlaze #0 (Running)
 71  xc7a100t
    72  MicroBlaze Debug Module at USER2
       73  MicroBlaze #0 (Running)
 74  xc7a100t
    75  MicroBlaze Debug Module at USER2
       76  MicroBlaze #0 (Running)
 77  xc7a100t
    78  MicroBlaze Debug Module at USER2
       79  MicroBlaze #0 (Running)
```
---

### 3) Select the FPGA (PL) That Contains Zynq PS Configuration

```
xsdb% targets -set 26
```

Selects the target index associated with the programmable logic (PL)
The number (80 in this case) may vary depending on your setup
Ensure you pick the PL related to Zynq (xc7z020), not pure MicroBlaze devices if you are working on ZYNQ and not any APUs

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
xsdb% targets -set 23
```

Selects the ARM core cluster parent for further debug control
Do NOT select MicroBlaze debug modules

---

### 6) Select ARM Core 0 as Debug Context

```
xsdb% targets -set 24
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
* IT HAS BEEN FOUND THAT THE DEVICES WHICH APPEAR ONCE MAY CHANGE IT'S TARGET ID WHILE RECONNECTING TO THE SERVER, KINDLY MODIFY YOUR ID IN
```
xsdb% targets -set <ID>

```


---

## Automation Tip

These XSDB commands can be saved to a `.tcl` script and executed using:

```
xsdb
source ./program.tcl
```

// Fully automates FPGA programming + application run flow

---

This documentation allows convenient and correct programming/debugging when multiple FPGA targets are connected simultaneously.
