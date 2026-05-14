onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib bunting_bram_opt

do {wave.do}

view wave
view structure
view signals

do {bunting_bram.udo}

run -all

quit -force
