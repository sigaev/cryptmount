#!/bin/bash
# usage: umount-crypt.sh [ FILE ]
# IMPORTANT SECURITY NOTE: WHOEVER SUDOES THIS FILE MAY TAKE OVER THE SYSTEM

[[ -e /etc/env.d/02localdomain ]] && eval export `cat /etc/env.d/02localdomain`
# ^^^to allow execution via sudo

ntd=/var/run/mount-crypt
rl=nbd_server.allow # remote allow list

f=`losetup -a | grep ^/dev/loop/ | grep -m1 -- "${1:-/home/sigaev/sandbox/.private})"`
if [[ $1 && -z $f && -d $ntd && `ls $ntd/` ]]; then
	f=`cat $ntd/* | grep -m1 -- "$1)"`
	[[ $f =~ ^([^:]+):([^:]+):([^:]+):\((.+)\)$ ]] || \
		{ echo error: No suitable loop or nbd device >&2; exit 1; }
	d=${BASH_REMATCH[1]}
	dp=$d
	h=${BASH_REMATCH[2]}
	p=${BASH_REMATCH[3]}
	f=${BASH_REMATCH[4]}
else
	[[ $f =~ ^([^:]+):.+\((.+)\)$ ]] || \
		{ echo error: No suitable loop or nbd device >&2; exit 1; }
	d=${BASH_REMATCH[1]}
	dp="/dev/loop/?${d#/dev/loop/}"
	h=
	f=${BASH_REMATCH[2]}
fi

n=
for i in /dev/mapper/crypt${h:+-net}* /dev/mapper/private${h:+-net}*; do
	[[ -e $i ]] && cryptsetup status ${i#/dev/mapper/} | grep -Eq "device: *$dp" && n=$i
done

e=0
if [[ $n ]]; then
	mount | grep -q "^$n " && { umount $n || e=1; }
	cryptsetup remove ${n#/dev/mapper/} || e=1
fi
if [[ $h ]]; then
	rm -f $ntd/${d#/dev/nbd}
	nbd-client -d $d
	su sigaev -c \
		"ssh -x $h 'ps x | grep \[n]bd-server.$p | awk {print\\\$1} | xargs -r kill'"
else
	[[ 1 == `blockdev --getro $d` ]]; t=$?
	losetup -d $d || e=1
	((t)) && touch -c "$f"
fi
exit $e
