#!/bin/bash
#installation as conda environment using micromamba

if ! which micromamba
then
  echo -e "\n" | "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
  export PATH=$HOME/.local/bin:$PATH
  micromamba shell deinit
fi
eval "$(micromamba shell hook --shell bash)"
MB=$(which micromamba)

micromamba create -y -f automekin.yml
micromamba activate amk_env

mkdir $CONDA_PREFIX/install_dir
cd $CONDA_PREFIX/install_dir
git clone https://github.com/emartineznunez/AutoMeKin.git
cd AutoMeKin
autoreconf -i
./configure --prefix=$CONDA_PREFIX/opt/AutoMeKin
make
make install
rm -f $CONDA_PREFIX/opt/AutoMeKin/modules/amk/2021ft2
cd $CONDA_PREFIX/install_dir
curl -s -L https://rxnkin.usc.es/images/5/56/molden6.2.full.ubuntu.64.tar.gz | tar -xvz -C $CONDA_PREFIX/opt
rm -rf $CONDA_PREFIX/install_dir

echo "amk_env installed"
echo "To use it:"
echo "eval \"\$($MB shell hook --shell bash)\""
echo "micromamba activate amk_env"
