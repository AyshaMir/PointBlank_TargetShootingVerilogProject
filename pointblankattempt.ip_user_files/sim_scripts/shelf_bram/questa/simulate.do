onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib shelf_bram_opt

do {wave.do}

view wave
view structure
view signals

do {shelf_bram.udo}

run -all

quit -force
