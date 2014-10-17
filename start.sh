#!/bin/bash
end ()
{
	stty icanon echo
}

trap end 0

stty -icanon -echo

strace -o /tmp/bar ./yacf 3> /tmp/foo
