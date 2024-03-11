#!/bin/bash
#default sbatch resources
#SBATCH --time=12:00:00
#SBATCH -n 4
#SBATCH --output=hlcalcs-%j.log
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#

exe="hlcalcs.sh"
cwd="$PWD"
sharedir=${AMK}/share
source utils.sh
###
print_ref
##
#if no arguments are provided, then a gui pops up 
if [ $# -eq 1 ]; then
   inputfile=$1
   if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
      runningtasks=$SLURM_NTASKS
   else
     echo "With one argument it must be run under the SLURM batch system:"
     echo "sbatch $exe inputfile"
     exit 1
   fi
elif [ $# -eq 2 ]; then
   inputfile=$1
   runningtasks=$2
else
   echo You must run this script as:
   echo "nohup $exe inputfile runningtasks >hlcalcs.log 2>&1 &"
   exit 1
fi
export runningtasks

###Are we in the right folder?
if [ ! -f $inputfile ];then
   echo "$inputfile is not in this folder"
   exit 1
fi
###
read_input
###
##Printing some stuff
hl_print
##start of calcs
echo ""
echo "CALCULATIONS START HERE"
echo ""
#set interactive mode to 0
inter=0
export inter
echo $$ > .script.pid
#
system="$(basename $inputfile .dat)"
echo "   Running TS opt    "
start=$(date +%s.%N)
TS.sh $inputfile > /dev/null
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo "   Running IRC       " 
start=$(date +%s.%N)
IRC.sh  >/dev/null 
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo "   Running min opt    "
start=$(date +%s.%N)
MIN.sh  >/dev/null 
end=$(date +%s.%N)
tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
echo "   time: $tt s"

echo "   Building network  "
if [ $sampling -eq 31 ]; then
   start=$(date +%s.%N)
   RXN_NETWORK.sh allstates >/dev/null
   end=$(date +%s.%N)
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
else
   start=$(date +%s.%N)
   RXN_NETWORK.sh >/dev/null
   end=$(date +%s.%N)
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
fi
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

