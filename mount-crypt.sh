#!/bin/bash
# usage: mount-crypt.sh [-f|-w] [ [HOST:]FILE ]
# IMPORTANT SECURITY NOTE: WHOEVER SUDOES THIS FILE MAY TAKE OVER THE SYSTEM
# set MC_FORMAT to mkreiserfs to format accordingly (default is mke2fs -m0)

[[ -e /etc/env.d/02localdomain ]] && eval export `cat /etc/env.d/02localdomain`
# ^^^to allow execution via sudo
[[ mkreiserfs == ${MC_FORMAT:-mkreiserfs} ]] || \
	{ echo error: Supported filesystems are ext2 and reiserfs >&2; exit 1; }
# ^^ SECURITY PRECAUTION

key=/mnt/private/backup/key
ntd=/var/run/mount-crypt
rl=nbd_server.allow # remote allow list
port=7437

nbd-kill () { su sigaev -c \
	"ssh -x $1 'ps x | grep \[n]bd-server.$2 | awk {print\\\$1} | xargs -r kill'"; }

bddel ()
{ if [[ $h ]]; then
	rm -f $ntd/$l
	nbd-client -d $d
	nbd-kill $h $((port+l))
else
	losetup -d $d
fi; }

bdsetup ()
{ if [[ $h ]]; then
	local p=$((port+l))
	[[ -e /sbin/modprobe ]] && modprobe -q nbd
	sleep 2
	[[ -e $d ]] && \
	su sigaev -c "ssh -x $h 'echo \$SSH_CLIENT | cut -d\  -f1 | xargs -r bin.mine/nbd-server $p \"$f\" $RO -l'" && \
	if nbd-client $h $p $d </dev/null >/dev/tty12 2>&1; then
		echo "$d:$h:$p:($f)" >$ntd/$l || { bddel; false; }
	else
		nbd-kill $h $p
		false
	fi
else
	losetup $RO $d "$f"
fi; }

umask 0027
mkdir -pm2750 $ntd
chgrp wheel $ntd
RO=-r
[[ \-f == $1 ]]; NF=$?; ((NF)) || { shift; RO=; }
[[ \-w == $1 ]] && { shift; RO=; }
h=
f=${1:-/home/sigaev/sandbox/.private}
k=
[[ $1 =~ ^([^:]+):([^:]+)$ ]] && { h=${BASH_REMATCH[1]}; f=${BASH_REMATCH[2]}; }
[[ $f =~ ^/ ]] || { echo error: \"$f\" is not a full file name >&2; exit 1; }
# parameter check (SECURITY PRECAUTION)
# NOTABENE: SCRIPT IS STILL VULNERABLE TO TOCTOU ATTACKS
if [[ $h ]]; then
	[[ lqcd == $h && $f =~ ^/data/sigaev/backup/[0-9]{5}$ ]] || \
	[[ data == $h && $f =~ ^/home/sigaev/[0-9]{5}$ ]]
else
	if [[ $f =~ ^/home ]]; then
		[[ $f =~ ^/home/sigaev/sandbox/\.private[0-9]?$ && \
			-f $f && ! -h $f && ! -h /home/sigaev/sandbox && \
			! -h /home/sigaev ]] || \
		[[ $f =~ ^/home/sigaev/[0-9]{5}$ && \
			-f $f && ! -h $f && ! -h /home/sigaev ]]
	else
		[[ $f =~ ^/data/[0-9]{5}$ && \
			-f $f && ! -h $f && sigaev == `ls -ld $f | awk '{print$3}'` ]]
	fi
fi || { echo error: PARAMETER SECURITY CHECK FAILED >&2; exit 1; }
# end of parameter check
if [[ $f =~ [0-9]+$ ]]; then
	k=$((10#${BASH_REMATCH[0]}))
	[[ -f $key ]] || { echo error: Key file \"$key\" does not exist >&2; exit 1; }
fi

e=1
l=0
if [[ $h ]]; then
	for i in $ntd/*; do
		[[ $i =~ [^0-9]$l$ ]] && ((l++))
	done
	d=/dev/nbd$l
	m=/mnt/crypt/n$l
	n=crypt-net$l; [[ -z $k ]] && n=private-net$l
else
	for i in `losetup -a | grep ^/dev/loop/ | cut -d: -f1`; do
		[[ $i =~ [^0-9]$l$ ]] && ((l++))
	done
	d=/dev/loop$l
	m=/mnt/crypt/$l
	if [[ $k ]]; then
		n=crypt$l
	else
		n=private${1:+$l}
		[[ $1 ]] || m=/mnt/private
	fi
fi
[[ -e /dev/mapper/$n ]] && { echo error: /dev/mapper/$n exists >&2; exit 1; }
if bdsetup; then
	cryptsetup -${RO:+r}caes-lrw-benbi -hsha384 -s384 ${k:+-d<(dd if="$key" bs=48 skip=$k count=1 2>/dev/null)} create $n $d
	if [[ 0 == $? ]]; then
		((NF)) || ${MC_FORMAT:-mke2fs -m0 -O-resize_inode} /dev/mapper/$n <<<y
		mkdir -pm700 $m
#		[[ $1 || $RO ]] || cp -af "$f" "$f.old"
		if mount $RO -onodev,nosuid,noexec,noatime${MC_FORMAT:+,user_xattr} /dev/mapper/$n $m; then
			e=0
		else
			cryptsetup remove $n
			bddel
		fi
	else
		bddel
	fi
fi

! ((NF)) && ! ((e)) && \
if [[ $k ]]; then
	chmod 1777 $m
else
	chmod 700 $m
	chown sigaev:users $m
fi

exit $e
