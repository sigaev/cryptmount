a=`egrep '^/dev/mapper/(crypt|private)' /etc/mtab | cut -d\  -f2`
[[ $a ]] && fuser -TERM -km $a && sleep 2 && fuser -KILL -km $a && sleep 1
[[ -z $a ]] || umount -r $a
e=$?

for i in /dev/mapper/crypt* /dev/mapper/private*; do
  if [[ -e $i ]]; then
    cryptsetup remove ${i#/dev/mapper/} || e=1
  fi
done

for i in `losetup -a | grep ^/dev/loop | cut -d: -f1`; do
  [[ 1 == `blockdev --getro $i` ]]
  t=$?
  f=
  ((t)) && f=`losetup $i | sed 's/.*(\(.*\))/\1/'`
  losetup -d $i || e=1
  ((t)) && touch -c "$f"
done

losetup -a
((e == 0))
