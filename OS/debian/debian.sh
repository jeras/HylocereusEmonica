################################################################################
# Authors:
# - Pavel Demin <pavel.demin@uclouvain.be>
# - Iztok Jeras <iztok.jeras@gmail.com>
# License:
# https://raw.githubusercontent.com/RedPitaya/RedPitaya/master/COPYING
################################################################################

# Added by DM; 2017/10/17 to check ROOT_DIR setting
if [ $ROOT_DIR ]; then 
    echo ROOT_DIR is "$ROOT_DIR"
else
    echo Error: ROOT_DIR is not set
    echo exit with error
    exit
fi

# Install Debian base system to the root file system
ARCH=armhf
DISTRO=stretch
MIRROR=http://deb.debian.org/debian/
debootstrap --foreign --arch $ARCH $DISTRO $ROOT_DIR $MIRROR

OVERLAY=OS/debian/overlay

# enable chroot access with native execution
cp /etc/resolv.conf         $ROOT_DIR/etc/
cp /usr/bin/qemu-arm-static $ROOT_DIR/usr/bin/

export LC_ALL=en_US.UTF-8

chroot $ROOT_DIR <<- EOF_CHROOT
export LANG=C
/debootstrap/debootstrap --second-stage
EOF_CHROOT

################################################################################
# APT settings
################################################################################

cp -rv $OVERLAY/etc/apt/* $ROOT_DIR/etc/apt/

chroot $ROOT_DIR <<- EOF_CHROOT
apt-get update
apt-get -y upgrade
EOF_CHROOT

################################################################################
# locale and keyboard
# setting LC_ALL overides values for all LC_* variables, this avids complaints
# about missing locales if some of this variables are inherited over SSH
################################################################################

chroot $ROOT_DIR <<- EOF_CHROOT
# this is needed by systemd services 'keyboard-setup.service' and 'console-setup.service'
DEBIAN_FRONTEND=noninteractive \
apt-get -y install console-setup

# setup locale
apt-get -y install locales
locale-gen --purge en_US.UTF-8
update-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8

# TODO seems sytemd is not running without /proc/cmdline or something
#localectl set-locale LANG=en_US.UTF-8 LANGUAGE=en_US LC_ALL=en_US.UTF-8
#localectl set-keymap us

# Debug log
locale -a
locale
cat /etc/default/locale
cat /etc/default/keyboard
EOF_CHROOT

################################################################################
# timezone and fake HW time
################################################################################

chroot $ROOT_DIR <<- EOF_CHROOT
# install fake hardware clock
apt-get -y install fake-hwclock

dpkg-reconfigure --frontend=noninteractive tzdata

# TODO seems sytemd is not running without /proc/cmdline or something
#timedatectl set-timezone Europe/Ljubljana
EOF_CHROOT

# set default timezone
if [ "$TIMEZONE" = "" ]; then
  TIMEZONE="Etc/UTC"
fi
# set timezone and fake RTC time
echo timezone = $TIMEZONE
echo $TIMEZONE > $ROOT_DIR/etc/timezone

# the fake HW clock will be UTC, so an adjust file is not needed
#echo $MYADJTIME > $ROOT_DIR/etc/adjtime
# fake HW time is set to the image build time
DATETIME=`date -u +"%F %T"`
echo date/time = $DATETIME
echo $DATETIME > $ROOT_DIR/etc/fake-hwclock.data

################################################################################
# File System table
################################################################################

install -v -m 664 -o root -D $OVERLAY/etc/fstab  $ROOT_DIR/etc/fstab

################################################################################
# run other scripts
################################################################################

. OS/debian/tools.sh
. OS/debian/network.sh
. OS/debian/zynq.sh
. OS/debian/jupyter.sh

################################################################################
# handle users
################################################################################

# http://0pointer.de/blog/projects/serial-console.html

install -v -m 664 -o root -D $OVERLAY/etc/securetty $ROOT_DIR/etc/securetty
install -v -m 664 -o root -D $OVERLAY/etc/systemd/system/serial-getty@ttyPS0.service.d/override.conf \
                            $ROOT_DIR/etc/systemd/system/serial-getty@ttyPS0.service.d/override.conf

################################################################################
# cleanup
################################################################################

chroot $ROOT_DIR <<- EOF_CHROOT
apt-get clean
history -c
EOF_CHROOT

# kill -k file users and list them -m before Unmount file systems
fuser -km $BOOT_DIR
fuser -km $ROOT_DIR

# file system cleanup for better compression
cat /dev/zero > $ROOT_DIR/zero.file
sync -f $ROOT_DIR/zero.file
rm -f $ROOT_DIR/zero.file

# remove ARM emulation
rm $ROOT_DIR/usr/bin/qemu-arm-static

# one final sync to be sure
sync
