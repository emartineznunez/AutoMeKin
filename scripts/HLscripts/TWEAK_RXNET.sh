#!/bin/bash
#default sbatch resources
#SBATCH --time=12:00:00
#SBATCH -n 4
#SBATCH --output=hlcalcs-%j.log
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#

inputfile="amk.dat"
exe="TWEAK_RXNET.sh"
cwd="$PWD"
sharedir=${AMK}/share
source utils.sh

read_input
echo "   Tweaking the Reaction Network  "
start=$(date +%s.%N)
RXN_NETWORK.sh modify >/dev/null
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo "   Running kinetics  "
start=$(date +%s.%N)
KMC.sh >/dev/null
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

if [ "$program_hl" = "g09" ] && [ "$barrierless" = "yes" ]; then
   echo "   Addding barrless procs"
   start=$(date +%s.%N)
   LOCATE_BARRIERLESS.sh >/dev/null
   end=$(date +%s.%N)
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
elif [ "$program_hl" = "g16" ] && [ "$barrierless" = "yes" ]; then
   echo "   Addding barrless procs"
   start=$(date +%s.%N)
   LOCATE_BARRIERLESS.sh >/dev/null
   end=$(date +%s.%N)
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
fi

echo "   Running frags opt "
start=$(date +%s.%N)
PRODs.sh >/dev/null
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo ""
echo "Making final folder: FINAL_HL_${molecule}"
FINAL.sh >/dev/null 
echo ""
echo "END OF THE CALCULATIONS"
echo ""

