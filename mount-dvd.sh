#!/bin/bash

drive= port=7451 dev=14
[[ $1 ]]                           || drive=c
[[ c == $1 || d == $1 ]]           && drive=$1
[[ d == $drive ]]                  && port=$((1+port)) dev=$((1+dev))
[[ $drive ]]                       || { echo "usage: mount-dvd.sh {c|d}"                 >&2; exit 1; }
nbd-client data $port /dev/nbd$dev || { echo "fatal: nbd-client data $port /dev/nbd$dev" >&2; exit 1; }
chgrp cdrom /dev/nbd$dev
blockdev --setra 0 /dev/nbd$dev
pmount -r /dev/nbd$dev data-$drive || { echo "fatal: pmount -r /dev/nbd$dev data-$drive" >&2; exit 1; }
