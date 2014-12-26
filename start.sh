#!/bin/bash
end ()
{
	stty icanon echo
}

trap end 0

stty -icanon -echo

make compshare.blk editor.blk compiler.blk future.blk
cat compshare.blk editor.blk compiler.blk future.blk > ed
./yacf 36
