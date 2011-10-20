#!/bin/bash

for i in /media/data-[cd]; do [[ -e $i ]] && {
	dev=14
	[[ ${i%d} == $i ]]         || dev=$((1+dev))
	pumount $i                 || { echo "fatal: pumount $i"                 >&2; exit 1; }
	nbd-client -d /dev/nbd$dev || { echo "fatal: nbd-client -d /dev/nbd$dev" >&2; exit 1; }
}; done
