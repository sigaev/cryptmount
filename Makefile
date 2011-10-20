install:
	install -m755 -t/usr/local/sbin mount-dvd.sh umount-crypt.sh mount-crypt.sh nbd-client umount-dvd.sh
	install -m755 -t/etc/init.d cryptmount cryptnmount
