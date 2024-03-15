#!/bin/bash
#System-wide installation on Ubuntu

apt update
apt --assume-yes install git 
apt --assume-yes install make 
apt --assume-yes install automake 
apt --assume-yes install autoconf 
apt --assume-yes install gawk 
apt --assume-yes install gfortran
apt --assume-yes install gcc
apt --assume-yes install bc
apt --assume-yes install environment-modules 
apt --assume-yes install parallel 
apt --assume-yes install sqlite 
apt --assume-yes install python3-pip 
apt --assume-yes install curl
apt --assume-yes install snapd
source /etc/profile.d/modules.sh
snap install molden
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt --assume-yes install nodejs -y
python3 -m pip install --upgrade pip
python3 -m pip install --upgrade Pillow
pip3 install ase
pip3 install networkx
mkdir /install_dir
cd /install_dir
git clone https://github.com/emartineznunez/AutoMeKin.git
cd AutoMeKin
autoreconf -i
./configure --prefix=/opt/AutoMeKin
make
make install
cd /opt
git clone https://github.com/dgarayr/amk_tools.git
cd amk_tools
pip3 install -e .
cd scripts
chmod +x amk_gen_view.py
rm -rf /install_dir
