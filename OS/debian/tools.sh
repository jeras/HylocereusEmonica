################################################################################
# miscelaneous tools
################################################################################

# Added by DM; 2017/10/17 to check ROOT_DIR setting
if [ $ROOT_DIR ]; then 
    echo ROOT_DIR is "$ROOT_DIR"
else
    echo Error: ROOT_DIR is not set
    echo exit with error
    exit
fi

chroot $ROOT_DIR <<- EOF_CHROOT
# UDEV tools
apt-get -y install libudev-dev
apt-get -y install udev

# DBUS
apt-get -y install dbus

# Git can be used to share notebook examples
apt-get -y install git

# gcc & debugger
apt-get -y install gcc bison flex
apt-get -y install gdb cgdb

# development tools
apt-get -y install less vim nano sudo usbutils psmisc lsof

# Python 3
apt-get -y install python3 python3-pip python3-setuptools
apt-get -y install python3-wheel
pip3 install --upgrade pip

# Meson+ninja build system
pip3 install meson
apt-get -y install ninja-build

# file system tools
apt-get -y install mtd-utils
apt-get -y install parted dosfstools

# DSP library for C language
# TODO: the package does not exist yet in Ubuntu 16.04, But is available in Debian stretch
apt-get -y install libliquid-dev
EOF_CHROOT
