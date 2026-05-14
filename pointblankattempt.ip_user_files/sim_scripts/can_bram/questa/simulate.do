onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib can_bram_opt

do {wave.do}

view wave
view structure
view signals

do {can_bram.udo}

run -all

quit -force
