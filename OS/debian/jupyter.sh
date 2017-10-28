################################################################################
# Authors:
# - Iztok Jeras <iztok.jeras@redpitaya.com>
# License:
# https://raw.githubusercontent.com/RedPitaya/RedPitaya/master/COPYING
################################################################################

###############################################################################
# install packages
###############################################################################

# Added by DM; 2017/10/17 to check ROOT_DIR setting
if [ $ROOT_DIR ]; then 
    echo ROOT_DIR is "$ROOT_DIR"
else
    echo Error: ROOT_DIR is not set
    echo exit with error
    exit
fi

chroot $ROOT_DIR <<- EOF_CHROOT
# proxy server for Jupyter
apt-get -y install nginx

# Sigrok
# TODO: this packages are not available on Debian
apt-get -y install libsigrok libsigrokdecode sigrok-cli
# OWFS 1-wire library
# NOTE: for now do not install OWFS, and avoid another http/ftp server from running by default
#apt-get -y install owfs python-ow

# Python numerical processing and plotting
apt-get -y install python3-numpy python3-scipy python3-pandas
apt-get -y install python3-matplotlib

# Jupyter
apt-get -y install jupyter-notebook

# http://bokeh.pydata.org/ interactive visualization library
pip3 install bokeh

# additional Python support for GPIO, LED, PWM, SPI, I2C, MMIO, Serial
# https://pypi.python.org/pypi/python-periphery
pip3 install python-periphery
pip3 install smbus2
pip3 install i2cdev

# support for VCD files
pip3 install pyvcd

# UDEV support can be used to search for peripherals loaded using DT overlays
# https://pypi.python.org/pypi/pyudev
# https://pypi.python.org/pypi/pyfdt
pip3 install pyudev pyfdt
EOF_CHROOT

###############################################################################
# create user and add it into groups for HW access rights
###############################################################################

chroot $ROOT_DIR <<- EOF_CHROOT
useradd -m -c "Jupyter notebook user" -s /bin/bash -G xdevcfg,uio,xadc,led,gpio,spi,i2c,eeprom,dialout,dma jupyter
EOF_CHROOT

###############################################################################
# systemd service
###############################################################################

# copy systemd service
install -v -m 664 -o root -D  $OVERLAY/etc/systemd/system/jupyter.service \
                             $ROOT_DIR/etc/systemd/system/jupyter.service

# create configuration directory for users root and jupyter
install -v -m 664 -o root -D  $OVERLAY/home/jupyter/.jupyter/jupyter_notebook_config.py \
                             $ROOT_DIR/root/.jupyter/jupyter_notebook_config.py
# let the owner be root, since the user should not change it easily
install -v -m 664 -o root -D  $OVERLAY/home/jupyter/.jupyter/jupyter_notebook_config.py \
                             $ROOT_DIR/home/jupyter/.jupyter/jupyter_notebook_config.py

chroot $ROOT_DIR <<- EOF_CHROOT
chown -v -R jupyter:jupyter /home/jupyter/.jupyter
EOF_CHROOT

chroot $ROOT_DIR <<- EOF_CHROOT
systemctl enable jupyter
EOF_CHROOT

###############################################################################
# copy/link notebook examples
###############################################################################

mkdir $ROOT_DIR/home/jupyter/RedPitaya
git clone https://github.com/redpitaya/jupyter.git $ROOT_DIR/home/jupyter/RedPitaya

chroot $ROOT_DIR <<- EOF_CHROOT
pip3 install -e /home/jupyter/RedPitaya
EOF_CHROOT

mkdir $ROOT_DIR/home/jupyter/WhirlwindTourOfPython
git clone https://github.com/jakevdp/WhirlwindTourOfPython.git $ROOT_DIR/home/jupyter/WhirlwindTourOfPython
