#!/bin/bash
#System-wide installation on CentOS

yum -y install epel-release
yum -y update
yum -y install redhat-lsb 
yum -y install yum-utils 
yum -y install git 
yum -y install make 
yum -y install automake 
yum -y install libtool 
yum -y install autoconf 
yum -y install bc 
yum -y install which 
yum -y install environment-modules 
yum -y install gawk 
yum -y install gcc 
yum -y install gcc-c++ 
yum -y install gnuplot 
yum -y install gcc-gfortran 
yum -y install parallel 
yum -y install sqlite 
yum -y install zenity 
yum -y install vim-common 
yum -y install vim-minimal 
yum -y install vim-enhanced 
yum -y install vim-filesystem 
yum -y install python3-pip 
yum -y install openblas 
yum -y install curl
update-mime-database /usr/share/mime
curl -sL https://rpm.nodesource.com/setup_14.x | bash -
yum -y install nodejs
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
rm -f /opt/AutoMeKin/modules/amk/2021ft2
cd /install_dir
curl -O https://rxnkin.usc.es/images/5/56/molden6.2.full.ubuntu.64.tar.gz
cd /opt
tar zxvf /install_dir/molden6.2.full.ubuntu.64.tar.gz
git clone https://github.com/dgarayr/amk_tools.git
cd amk_tools
pip3 install -e .
cd scripts
chmod +x amk_gen_view.py
rm -rf /install_dir
