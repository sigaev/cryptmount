install:
	install -m755 -t/usr/local/sbin mount-dvd.sh umount-crypt.sh mount-crypt.sh umount-dvd.sh
	[ ! -e /etc/init.d ] || install -m755 -t/etc/init.d cryptmount cryptnmount
	[ -e /etc/init.d ] || install -m644 -t/usr/local/sbin cryptmount-stop.sh
	[ -e /etc/init.d ] || install -m644 -t/etc/systemd/system cryptmount.service
	[ -e /etc/init.d ] || systemctl enable cryptmount.service
	mkdir -pm755 /mnt/crypt
