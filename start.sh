#!/bin/bash
end ()
{
	stty icanon echo
}

trap end 0

stty -icanon -echo

cat editor.blk compshare.blk > ed
4<ed strace -o /tmp/bar ./yacf 3> /tmp/foo
