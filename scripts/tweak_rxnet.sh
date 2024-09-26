#!/bin/bash
# default sbatch
#SBATCH --output=llcalcs-%j.log
#SBATCH --time=04:00:00

#SBATCH -c 1 --mem-per-cpu=2048
#SBATCH -n 32

inputfile="amk.dat"
exe="llcalcs.sh"
cwd="$PWD"
sharedir=${AMK}/share
source utils.sh

read_input
echo "   Tweaking the Reaction Network "
start=$(date +%s.%N)
rxn_network.sh modify >/dev/null
end=$(date +%s.%N)    
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo "   Running Kinetics "
start=$(date +%s.%N)
kmc.sh > /dev/null
end=$(date +%s.%N)    
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

if [ "$program_opt" = "mopac" ] && [ "$barrierless" = "yes" ]; then
   echo "   Adding Barrierless reactions"
   start=$(date +%s.%N)
   locate_barrierless.sh modify  2> barrless.err 1> barrless.log
   end=$(date +%s.%N)    
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
fi

echo "Making final folder: FINAL_LL_${molecule}"
rm -rf batch*
track_view.sh > final.log
final.sh > /dev/null
echo ""
echo "END OF THE CALCULATIONS"
echo ""
