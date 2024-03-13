#!/bin/bash
{
#installation as conda environment using micromamba

if ! which micromamba
then
  echo -e "\n" | "${SHELL}" <(curl -L micro.mamba.pm/install.sh)
  export PATH=$HOME/.local/bin:$PATH
  micromamba shell deinit
fi
MB=$(type -P micromamba)
eval "$(micromamba shell hook --shell bash)"

micromamba create -y -f automekin.yml
micromamba activate amk_env

curl -L -o $CONDA_PREFIX/bin/amk_gen_view.py https://github.com/dgarayr/amk_tools/raw/master/scripts/amk_gen_view.py
chmod +x $CONDA_PREFIX/bin/amk_gen_view.py 
curl -L -o $CONDA_PREFIX/bin/amk_rxn_stats.py https://github.com/dgarayr/amk_tools/raw/master/scripts/amk_rxn_stats.py
chmod +x $CONDA_PREFIX/bin/amk_rxn_stats.py
} &>$0.log

echo "amk_env installed ..."

{
mkdir $CONDA_PREFIX/install_dir
cd $CONDA_PREFIX/install_dir
git clone https://github.com/emartineznunez/AutoMeKin.git
cd AutoMeKin
autoreconf -i
./configure --prefix=$CONDA_PREFIX/opt/AutoMeKin
make
make install
cd $CONDA_PREFIX/install_dir
curl -s -L  https://github.com/emartineznunez/amk_utils/raw/main/molden6.2.full.ubuntu.64.tar.gz| tar -xvz -C $CONDA_PREFIX/opt
rm -f $CONDA_PREFIX/opt/molden/libstdc++.so.6
for exe in obabel ambmd gmolden obenergy surf open3dqsar ambmd ambfor molden pharmer
  do
  patchelf --set-rpath $CONDA_PREFIX/lib:$CONDA_PREFIX/opt/molden $CONDA_PREFIX/opt/molden/$exe
done
rm -rf $CONDA_PREFIX/install_dir
} &>>$0.log

echo "AutoMeKin installation done  ..."

cat <<'EOL'

AutoMeKin 2021
https://github.com/emartineznunez/AutoMeKin

EOL

echo "To use it:"
echo "eval \"\$($MB shell hook --shell bash)\""
echo "micromamba activate amk_env"
echo "ml use $CONDA_PREFIX/opt/AutoMeKin/modules"
echo "ml amk/2021"
