# XSDB Automation Script for Programming Zynq & Running Application

# Initial RESET SYSTEM AND WAIT FOR 2s remove if causing Invalid error
puts "Initial RESET SYSTEM AND WAIT FOR 2s"
rst -system
after 2000

# 1) Connect to hardware server
connect
after 2000

# 2) List targets (optional diagnostic)
targets
after 2000

# 3) Select the correct PL target that contains the PS configuration
# NOTE: Update target ID to match your board
targets -set 26
after 2000

# Program the FPGA bitstream
puts "Programming the FPGA..."
fpga -file "/home/rithwik/gpio_led/gpio_led.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000

# 4) Select the APU parent and core 0 for debug (IMPORTANT: not MicroBlaze)
# Update IDs (77 & 78) based on `targets` listing

targets -set 23
after 2000
# Set ARM Cortex-A9 #0 as context
targets -set 24
after 2000
# 5) Stop CPU before loading FSBL
stop
after 2000
# 6) Load FSBL to initialize DDR & SLCR
# Modify path as needed
puts "Flashing the First Stage Boot Loader..."
dow "/home/rithwik/gpio_led/gpio_led.vitis/platform/zynq_fsbl/build/fsbl.elf"
puts "Completed FSBL Flashing!"
# Run FSBL
after 2000
con

after 2000
# 7) Load and run application ELF
puts "Flashing your application..."
dow "/home/rithwik/gpio_led/gpio_led.vitis/xgpio_example/build/xgpio_example.elf"
puts "Completed Flashing!"

after 2000
# 8) Run the application
con

# Script Finished
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"
#Delay (represented in us) Extend if needed
after 60000

rst -system
puts "Completed the task and reset has been applied"


