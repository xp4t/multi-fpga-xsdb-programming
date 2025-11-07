# XSDB Automation Guide for Zynq FPGA Programming and Application Execution

This guide walks you through how to **automate programming and running applications** on a Zynq FPGA board using an XSDB `.tcl` script.
Instead of typing each command manually, this script does the entire setup for you — from reset to running your program — in one go.

---

## What This Script Does

The script handles the full process:

1. Resets the board
2. Connects to the hardware server
3. Picks the right FPGA and ARM targets
4. Loads the bitstream
5. Runs the FSBL (First Stage Bootloader)
6. Loads and runs your main application
7. Resets again after execution

You just need to make sure the **target IDs and file paths** are correct for your setup.

---

## Script Name

```
program.tcl
```

---

## Step-by-Step Explanation

### 1) Reset Everything First

```tcl
puts "Initial RESET SYSTEM AND WAIT FOR 2s"
rst -system
after 2000
```

Starts with a clean slate — resets the board and waits for two seconds before moving on. This might turn into an error if the previously selected target is a PL Device and not an APU. So you can avoid this if it hits up an error.

---

### 2) Connect to the Hardware Server

```tcl
connect
after 2000
```

This connects XSDB to your local JTAG hardware server. If you’re using a remote setup, make sure the `hw_server` is running first.

---

### 3) Check Available Targets

```tcl
targets
after 2000
```

Lists all the devices currently visible on JTAG. You’ll see all the FPGAs, CPUs, and debug modules. Use this info to note down which **target IDs** belong to your Zynq board’s PL and ARM cores.

---

### 4) Select FPGA and Program the Bitstream

```tcl
targets -set 34
after 2000
puts "Programming the FPGA..."
fpga -file "/home/rithwik/gpio_led/gpio_led.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000
```

This picks the FPGA fabric (PL) and programs your `.bit` file onto it.
Change the ID (`34`) if your board shows a different number when you run `targets`.

---

### 5) Select the ARM APU and Core 0

```tcl
targets -set 31
after 2000
targets -set 32
after 2000
```

These lines select the ARM Cortex-A9 processing system. The first is the APU cluster, the second is **Core 0**. Make sure these IDs match your setup.

---

### 6) Stop CPU and Load the FSBL

```tcl
stop
after 2000
puts "Flashing the First Stage Boot Loader..."
dow "/home/rithwik/gpio_led/gpio_led.vitis/platform/zynq_fsbl/build/fsbl.elf"
puts "Completed FSBL Flashing!"
after 2000
con
after 2000
```

This stops the processor, loads the **First Stage Boot Loader**, and lets it run.
The FSBL sets up memory, clocks, and peripherals so your main app has everything it needs to run.

---

### 7) Load and Run Your Application

```tcl
puts "Flashing your application..."
dow "/home/rithwik/gpio_led/gpio_led.vitis/xgpio_example/build/xgpio_example.elf"
puts "Completed Flashing!"
after 2000
con
```

Your main program gets loaded into DDR memory and starts running on Core 0.
If it’s the GPIO LED example, the LEDs should start toggling once this runs.

---

### 8) Wait and Reset Again

```tcl
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"
after 60000
rst -system
puts "Completed the task and reset has been applied"
```

After running, the script pauses for a minute so you can observe the output or debug signals.
Then it resets the board again, putting it back into a clean state.

---

## Tips

* Run `targets` every time you reconnect boards — IDs can shuffle around.
* Double-check file paths for your `.bit`, `fsbl.elf`, and `.elf` files.
* Don’t delete the `after` delays; they give XSDB enough time between steps.
* If you’ve got multiple boards connected, make sure you’re programming the right one.

---

## How to Run It

Open a terminal or the XSDB console inside Vitis and type:

```bash
xsdb
source ./program.tcl
```

That’s it. The script does the rest — resets the board, programs the FPGA, runs the FSBL and your app, waits for a while, and resets everything cleanly.

If something fails, rerun the script or go step-by-step manually in XSDB to see where it’s getting stuck.

---

## Why This Helps

Instead of retyping the same commands every time, this one script can bring up your Zynq board from a completely blank state to a fully running application in less than a minute.
It’s simple, repeatable, and removes human error — so you can focus on testing your design, not typing commands.
