# ===================== USER CONFIG =====================
set PROJECT_NAME "your_project_name"
set USERNAME "your_username"
set APP_NAME "app_component"
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
targets -set -filter {name =~ "xc7z020"}   
after 2000

# Program the FPGA bitstream
puts "Programming the FPGA..."
fpga -file "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.runs/impl_1/design_1_wrapper.bit"
puts "FPGA Programming Completed!"
after 2000

# 4) Select the APU parent and core 0 for debug
targets -set -filter {name =~ "APU"} 
after 2000

targets -set -filter {name =~ "ARM Cortex-A9 MPCore #0"}    
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
dow "/home/$USERNAME/$PROJECT_NAME/$PROJECT_NAME.vitis/$APP_NAME/build/$APP_NAME.elf"
puts "Completed Flashing!"

after 2000

# 8) Run the application
con

# Script Finished
puts "XSDB programming sequence completed successfully!"
puts "A 60s delay has been provided to debug and analyse your waveform"
# Uncomment only if you require a serial monitor for printing texts
puts "Displaying Serial Monitor"
#exec putty -serial /dev/ttyPYNQ1 -sercfg 115200,8,n,1,N
after 60000

rst -system
puts "Completed the task and reset has been applied"
