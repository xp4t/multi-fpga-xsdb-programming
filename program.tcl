# XSDB Automation Script for Programming Zynq & Running Application

# 1) Connect to hardware server
connect

# 2) List targets (optional diagnostic)
targets

# 3) Select the correct PL target that contains the PS configuration
# NOTE: Update target ID to match your board
targets -set 80

# Program the FPGA bitstream
fpga -file "/home/rithwik/gpio_led/gpio_led.runs/impl_1/design_1_wrapper.bit"

# 4) Select the APU parent and core 0 for debug (IMPORTANT: not MicroBlaze)
# Update IDs (77 & 78) based on `targets` listing
targets -set 77
# Set ARM Cortex-A9 #0 as context
targets -set 78

# 5) Stop CPU before loading FSBL
stop

# 6) Load FSBL to initialize DDR & SLCR
# Modify path as needed
dow "/home/rithwik/gpio_led/gpio_led.vitis/platform/zynq_fsbl/build/fsbl.elf"
# Run FSBL
con

# 7) Load and run application ELF
dow "/home/rithwik/gpio_led/gpio_led.vitis/xgpio_example/build/xgpio_example.elf"

# 8) Run the application
con

# Script Finished
puts "XSDB programming sequence completed successfully!"
