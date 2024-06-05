#!/bin/bash
# default sbatch
#SBATCH --output=llcalcs-%j.log
#SBATCH --time=04:00:00

#SBATCH -c 1 --mem-per-cpu=2048
#SBATCH -n 32

# first  arg is inputfile
# second arg is nbatches (200 is a good number)
# third  arg is niter  
#if no arguments are provided, then a gui pops up
#convergence is achieved when no new TSs are found in three consecutive iterations
convergence=0
exe="llcalcs.sh"
cwd="$PWD"
iter=0
sharedir=${AMK}/share
source utils.sh
# Printing the references of the method
print_ref
#
if [ $# -eq 3 ]; then
   inputfile=$1
   nbatch=$2
   niter=$3
   if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
      runningtasks=$SLURM_NTASKS
   else
     echo "With three arguments it must be run under the SLURM batch system:"
     echo "sbatch $exe inputfile ntasks niter"
     exit 1
   fi
elif [ $# -eq 4 ]; then
   inputfile=$1
   nbatch=$2
   niter=$3
   runningtasks=$4
else
   echo You must run this script as:
   echo "nohup $exe inputfile ntasks niter runningtasks >llcalcs.log 2>&1 &" 
   exit 1
fi
export runningtasks

###Are we in the right folder?
if [ ! -f $inputfile ];then
   echo "$inputfile is not in this folder"
   exit 1
fi
if [ -z $nbatch ] || [ -z $niter ]; then
   echo "Number of batches and/or number of iterations have not been set"
   exit 1
fi
#EMN. If nbatch=0 do not run dynamics.
if [ $nbatch -eq 0 ]; then niter=1 ; fi
#EMN
read_input
###
echo ""
echo "Number of iterations  = $niter"
echo "Tasks per iteration   = $nbatch"
echo ""
###checks and writing stuff
xyzfiles_check 
###
sampling_calcs
###
amkscript=0
print_method_screening
###
echo ""
echo "CALCULATIONS START HERE"
echo ""
iter=1
#set interactive mode to 0
inter=0
export inter
echo $$ > .script.pid
#
if [ $sampling -eq 3 ]; then echo " CK calculations " > ChemKnow.log ; fi
while [ $iter -le $niter ]; do
   export iter
   echo "======================="
   echo "      Iter: ${iter}/${niter}"
   echo "======================="
   echo "$iter/$niter" > iter.txt
   if [ $nbatch -gt 0 ]; then
      echo "   Running TS search"
      start=$(date +%s.%N)
      amk_parallel.sh $inputfile $nbatch >/dev/null
      end=$(date +%s.%N)    
      tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
      echo "   time: $tt s"
   fi
##check that in ChemKnow nts is not -1 (-->all minima explored). If that is the case-->stop
   nts=$(sqlite3 ${tsdirll}/track.db "select nts from track" | awk '{a=$1};END{print a+1-1}')
   if [ $nts -lt 0 ]; then
      echo "   All MIN employed "
      echo "   Stop iters here  " 
      rm -rf batch*
      break 
   fi
##check that tslistll file exists
   if [ ! -f $tslistll ]; then
      echo ""
      echo "   ERROR:           "
      echo "   tslist is empty  "
      echo "   Check: batch dirs"
      if [ $sampling -eq 3 ]; then echo "   or ChemKnow.log  " ; fi 
      echo ""
      exit
   fi
##Doing IRCs
   echo "   Running IRC      "
   start=$(date +%s.%N)
   irc.sh > /dev/null
   end=$(date +%s.%N)    
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
###check that the nts is greater than the previous value
   cid=$(sqlite3 ${tsdirll}/track.db "select max(id) from track" | awk '{print $1+1-1}' )
   if [ $cid -eq 1 ]; then
     ntsp=0
   else
     ((itm1=cid-1))
     ntsp=$(sqlite3 ${tsdirll}/track.db "select nts from track where id=$itm1" | awk '{print $1+1-1}' )
   fi
   ntsa=$(sqlite3 ${tsdirll}/track.db "select nts from track where id=$cid" | awk '{print $1+1-1}' )
   if (( $(echo "$ntsa <= $ntsp" |bc -l) )); then
      echo "   No new TSs found "
      echo "   Skip this iter   "
      echo ""  
      rm -rf batch*
      ((iter=iter+1))
      ((convergence=convergence+1))
      if [ $convergence -eq 3 ]; then
         echo "   Stop iters here  " 
         echo "   Convergence      " 
         break
      fi
      continue 
   else
      new_ts=$(echo "$ntsa-$ntsp" |bc -l)
      echo "   New TSs found: $new_ts"
   fi
###
   convergence=0
   echo "   Running min opt  "
   start=$(date +%s.%N)
   min.sh  > /dev/null
   end=$(date +%s.%N)    
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
   echo "   Building network "
   if [ $sampling -eq 31 ]; then
      start=$(date +%s.%N)
      rxn_network.sh allstates >/dev/null
      end=$(date +%s.%N)    
      tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
      echo "   time: $tt s"
   else
      start=$(date +%s.%N)
      rxn_network.sh >/dev/null
      end=$(date +%s.%N)    
      tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
      echo "   time: $tt s"
   fi
   echo "   Running Kinetics "
   start=$(date +%s.%N)
   kmc.sh > /dev/null
   if [ -f ${tsdirll}/KMC/branching*.out ]; then 
      sed 's/ + /+/g' ${tsdirll}/KMC/branching*.out > ${tsdirll}/branching_${iter} 
      awk 'NR>1{print $2}' ${tsdirll}/branching_${iter} > ${tsdirll}/prods
      for i in $(seq $iter)
      do
         if [ ! -f ${tsdirll}/branching_$i ]; then echo "  %  Products" > ${tsdirll}/branching_$i ; fi
         if [ $i -eq 1 ]; then
            awk 'NR==FNR{col[NR]=$1;mc=NR;n[col[NR]]=0};NR>FNR{n[$2]=$1};END{for(i=1;i<=mc;i++) printf "%15s %5.1f\n",col[i],n[col[i]]}' ${tsdirll}/prods ${tsdirll}/branching_$i  > ${tsdirll}/tmp_br$i
         else
            awk 'NR==FNR{col[NR]=$1;mc=NR;n[col[NR]]=0;colt[NR]=$0};NR>FNR{n[$2]=$1};END{for(i=1;i<=mc;i++) printf "%s %5.1f\n",colt[i],n[col[i]]}' ${tsdirll}/tmp_br$((i-1)) ${tsdirll}/branching_$i  > ${tsdirll}/tmp_br$i
         fi
      done
      cp ${tsdirll}/tmp_br${iter} ${tsdirll}/branching_convergence
      rm -rf ${tsdirll}/tmp_br* ${tsdirll}/prods
   fi
   end=$(date +%s.%N)    
   tt=$( echo "$end - $start" | bc -l | awk '{printf "%4.0f",$1}')
   echo "   time: $tt s"
   echo ""  
   ((iter=iter+1))
done
if [ "$program_opt" = "mopac" ] && [ "$barrierless" = "yes" ]; then
   echo "Adding Barrierless reactions"
   start=$(date +%s.%N)
   locate_barrierless.sh  2> barrless.err 1> barrless.log
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
