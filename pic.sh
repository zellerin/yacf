 make microchip.blk compshare.blk all
 cat compshare.blk microchip.blk > mblk ; ./yacf 4<mblk 3> code
 objcopy -I binary -O ihex code 
 gpdasm -p16f628 code 
