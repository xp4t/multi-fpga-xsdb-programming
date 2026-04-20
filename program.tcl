# XSDB Automation Script for Programming Zynq & Running Application

# ===================== USER CONFIG =====================
set PROJECT_NAME "gpio_led"
set USERNAME "rithwik"
# ======================================================

# Initial RESET SYSTEM AND WAIT FOR 2s (REQUIRED ONLY WHILE DOING THE SECOND TIME)
# puts "Initial RESET SYSTEM AND WAIT FOR 2s"
# rst -system
# after 2000

# 1) Connect to hardware server
connect
after 2000

# 2) List targets (optional diagnostic)
targets
after 2000

# 3) Select the correct PL target that contains the PS configuration
targets -set 26
after 2000

# Program the FPGA bitstream
puts "Programming the FPGA..."
fpga -file "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000

# 4) Select the APU parent and core 0 for debug
targets -set 23
after 2000

targets -set 24
after 2000

# 5) Stop CPU before loading FSBL
stop
after 2000

# 6) Load FSBL to initialize DDR & SLCR
puts "Flashing the First Stage Boot Loader..."
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/platform/zynq_fsbl/build/fsbl.elf"
puts "Completed FSBL Flashing!"

after 2000
con
after 2000

# 7) Load and run application ELF
puts "Flashing your application..."
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/xgpio_example/build/xgpio_example.elf"
puts "Completed Flashing!"

after 2000

# 8) Run the application
con

# Script Finished
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"

# Uncomment only if you require a serial monitor for printing texts
#puts "Displaying Serial Monitor"
#the below comment requires putty installed in your system.
#exec putty -serial /dev/ttyPYNQ1 -sercfg 115200,8,n,1,N
#for nerds, I Created a udev rule to assign /dev/ttyPYNQ1 as a persistent name for a specific FPGA board, so it maintains the same device path regardless of USB enumeration order.
after 60000


rst -system
puts "Completed the task and reset has been applied"
