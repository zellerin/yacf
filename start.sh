#!/bin/bash
end ()
{
	stty icanon echo
}

trap end 0

stty -icanon -echo

make
./yacf 36
