quit -sim
.main clear

set PrefMain(saveLines) 100000000000

cd ../sim
cmd /c "if exist work rmdir /S /Q work"
vlib work
vmap work
vmap unisim

vcom -2008 ../source/MyPackage.vhd
vcom -2008 ../source/*.vhd
vcom -2008 ../test/KernelConvolver_tb.vhd

vsim -t 100ps -vopt KernelConvolver_tb -voptargs=+acc

config wave -signalnamewidth 1

add wave -format Logic -radix decimal sim:/KernelConvolver_tb/KernelConvolverInst/*

run 10 us
