 make microchip.blk
 strace ./yacf 4< microchip.blk 3> code
 objcopy -I binary -O ihex code 
 gpdasm -p16f628 code 
