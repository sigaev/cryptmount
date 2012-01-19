install:
	install -m755 -t/usr/local/sbin mount-dvd.sh umount-crypt.sh mount-crypt.sh umount-dvd.sh
	install -m755 -t/etc/init.d cryptmount cryptnmount
	mkdir -m755 /mnt/crypt
