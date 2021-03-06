# Finish bunny directory structure
mkdir /bunny/mnt
mkdir /bunny/storage


# Install dependencies
apt install -y isc-dhcp-server python-pip
pip install rpyc


# Make HID work and make quack script work
cd /bunny/src/rspiducky
gcc usleep.c -o /bunny/bin/usleep
chmod 755 /bunny/bin/usleep
gcc hid-gadget-test.c -o /bunny/bin/keyboardtype
chmod 755 /bunny/bin/keyboardtype
chmod +x duckpi.sh


# Set up permissions - make all payloads executable    TODO move this to a separate script and call it from bunny-launcher.py if target-side edited payloads require so
for i in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
chmod +x /bunny/payloads/$i/boot
chmod +x /bunny/payloads/$i/button_red
chmod +x /bunny/payloads/$i/button_green
done

chmod +x /bunny/bin/EDIT_PAYLOADS

# Create a mass storage device that can be used for target machine
mkdir -p /bunny/storage
dd if=/dev/zero of=/bunny/storage/system.img bs=1M count=1024
mkdosfs /bunny/storage/system.img
fatlabel /bunny/storage/system.img BUNNY
mkdir -p /bunny/mnt
mount -o loop /bunny/storage/system.img /bunny/mnt
mkdir /bunny/mnt/loot
/bunny/bin/SYNC_PAYLOADS # Make sure payloads are on storage device.


# Make sure that gadgets can be used. Modules need to be loaded at boot time
grep -q -F 'dwc2' /etc/modules || echo 'dwc2' >> /etc/modulessudo git clone https://github.com/Adntrky/PoorMansBashBunny /bunny
grep -q -F 'libcomposite' /etc/modules || echo 'libcomposite' >> /etc/modules
grep -q -F 'dtoverlay=dwc2' /boot/config.txt || echo 'dtoverlay=dwc2' >> /boot/config.txt

# Setup DHCP server
grep -q "172.16.64.0" /etc/dhcp/dhcpd.conf
if [[ $? != 0 ]]; then
	echo "subnet 172.16.64.0 netmask 255.255.255.0 {" >> /etc/dhcp/dhcpd.conf
	echo "  range 172.16.64.10 172.16.64.12;" >> /etc/dhcp/dhcpd.conf
	echo "}" >> /etc/dhcp/dhcpd.conf
fi
sed -i '/INTERFACESv6=\"\"/d' /etc/default/isc-dhcp-server


# Make sure the launcher starts at boot time.
ln -s /bunny/etc/systemd/system/bunny-launcher.service /etc/systemd/system/bunny-launcher.service
systemctl enable bunny-launcher.service


# Make important bunny binaries easily accessible
ln -s /bunny/bin/ATTACKMODE /usr/bin/ATTACKMODE
ln -s /bunny/bin/LED /usr/bin/LED
ln -s /bunny/bin/QUACK /usr/bin/QUACK
ln -s /bunny/bin/SYNC_PAYLOADS /usr/bin/SYNC_PAYLOADS
ln -s /bunny/bin/EDIT_PAYLOADS /usr/bin/EDIT_PAYLOADS
ln -s /bunny/bin/WAIT_TARGET /usr/bin/WAIT_TARGET
