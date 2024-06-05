#!/bin/bash
# Run this script to test the program for the formic acid example
# You must have loaded amk module before:
# module load amk/2021

# run_test.sh --tests=test
# ntasks: is number of parallel tasks
# niter: is the number of iterations
cwd=$PWD

tests0=(assoc assoc_qcore rdiels_bias diels_bias FA_biasH2 FA_biasH2O FA_bxde FA_singletraj FA FAthermo FA_programopt vdW FA_ck FA_qcore FA_bxde_qcore ttors)

if [ $# -ge 1 ]; then
   args=${@}
   tests=("$(echo $args | sed  's/=/ /g;s/,/ /g' | awk 'BEGIN{f=0};{for(i=1;i<=NF;++i) if($i=="--tests") f=i}
   END{if(f>0)
         for(i=f+1;i<=NF;i++) {if($i~/--/) exit;printf "%s ",$i}
       else
         print "all"
        }' )")
   if [[ "$tests" == *"all"* ]]; then
      tests=(${tests0[@]})
   fi
else
   tests=(${tests0[@]})
fi

ptp=${AMK}/examples
ntasks=10
niter=2
runningtasks=$ntasks

len=0
for i in $(echo ${tests[@]}); do ((len=len+1)) ; done
n=0
for i in $(echo ${tests[@]})
do
   ((n=n+1))
   printf "\n======================================\n"
   printf "Running test (%2d / %2d): %s\n" $n $len $i
   printf "======================================\n"
   if [ ! -f ${ptp}/${i}.dat  ];then
      echo "this test does not exist" 
      exit
   fi
   rm -rf $i && mkdir $i
   cd $i   
   cp ${ptp}/${i}.dat .
   xyz=$(awk 'BEGIN{tf=0};{if($1=="fragmentA") {tf=1;fl1=$2}};{if($1=="fragmentB") fl2=$2};{if($1=="molecule") fl=$2};END{if(tf==0) print fl; else print fl1,fl2}' ${i}.dat)
   for j in $(echo "$xyz"); do cp ${ptp}/${j}.xyz . ; done
   if [ "$i" == "FA" ] || [ "$i" == "FA_bxde" ] || [ "$i" == "FAthermo" ] || [ "$i" == "FA_programopt" ] || [ "$i" == "vdW" ] || [ "$i" == "diels_bias" ] || [ "$i" == "FA_qcore" ] || [ "$i" == "FA_bxde_qcore" ]; then
      echo "LL calculations"
      time llcalcs.sh ${i}.dat $ntasks $niter $runningtasks > llcalcs.log 
   elif [ "$i" == "FA_ck" ]; then
      echo "LL calculations"
      time llcalcs.sh ${i}.dat 50 10 50 > llcalcs.log 
   elif [ "$i" == "ttors" ]; then
      time tors.sh ${i}.dat > ttors.log
   else
      time amk.sh ${i}.dat > ${i}.log
   fi
   if [ "$i" == "FA_programopt" ] || [ "$i" == "FA_qcore" ]; then
      echo "HL calculations"
      if [ "$i" == "FA_qcore" ];then cp $ptp/qcore_template . ; fi
      time hlcalcs.sh ${i}.dat $runningtasks > hlcalcs.log 
   fi
   if [ "$i" == "FA" ]; then
      cp -r FINAL_LL_FA FINAL_LL_FA_coarse_grained
      tsn=$(awk 'NR==3{print $1}' FINAL_LL_FA_coarse_grained/RXNet.cg)
      echo "Removing ts number $tsn"
      remove_ts.sh $tsn  > removets.log
      mv FINAL_LL_FA FINAL_LL_FA_coarse_grained_TS${tsn}_removed
      echo "Considering all states"
      rxn_network.sh allstates > allstates.log
      kmc.sh >> allstates.log
      locate_barrierless.sh  2> barrless.err 1>> allstates.log
      final.sh >> allstates.log
      mv FINAL_LL_FA FINAL_LL_FA_all_states
      echo "One-level HL calculations"
      time hlcalcs.sh ${i}.dat $runningtasks > hlcalcs_onelevel.log 
      if [ -d FINAL_HL_FA ]; then mv FINAL_HL_FA FINAL_HL_FA_onelevel ; fi
      if [ -d tsdirHL_FA ]; then mv tsdirHL_FA tsdirHL_FA_onelevel ; fi
      cp $ptp/FA_2level.dat FA.dat 
      echo "Two-level HL calculations"
      time hlcalcs.sh ${i}.dat $runningtasks > hlcalcs_twolevel.log 
      if [ -d FINAL_HL_FA ]; then mv FINAL_HL_FA FINAL_HL_FA_twolevel ; fi
      if [ -d tsdirHL_FA ]; then mv tsdirHL_FA tsdirHL_FA_twolevel ; fi
   fi
   if [ "$i" == "FAthermo" ]; then
      mv FINAL_LL_FA FINAL_LL_FA_T300
      kinetics.sh 5000 ll > htemp.log
   fi
   if [ "$i" == "FA_singletraj" ]; then 
      tsll_view.sh > tslist.log
   fi
   echo ""
   echo $i test Done
   echo ""
   cd $cwd
done

echo "==========================="
echo "   Info about the tests:   "
echo "==========================="
echo
echo " 1. assoc:         Geometries of Bz-N2 complexes"
echo " 2. assoc_qcore:   Geometries of Bz-N2 complexes using qcore (xtb method)"
echo " 3. rdiels_bias:   Mechanism for a retro Diels-Alder rxn"
echo " 4. diels_bias:    Mechanism for a Diels-Alder rxn"
echo " 5. FA_biasH2:     H2 elimination in formic acid"
echo " 6. FA_biasH2O:    H2O elimination in formic acid"
echo " 7. FA_bxde:       Mechanisms of formic acid decomposition using BXDE sampling"
echo " 8. FA_singletraj: Using a random number seed to obtain two TSs involved in formic acid rxns"
echo " 9. FA:            Mechanisms of formic acid decomposition. Several calculations (coarse grained, all states, high level,etc.)"
echo "10. FAthermo:      Mechanisms of formic acid decomposition. Thermal calculations of rate coefficients at two temperatures"
echo "11. FA_programopt: Mechanisms of formic acid decomposition using gaussian to optimize TSs at low-level"
echo "12. vdW:           vdW complexes and TSs in Bz-N2"
echo "13. FA_ck:         Mechanisms of formic acid decomposition using external forces"
echo "14. FA_qcore:      Mechanisms of formic acid decomposition using qcore (xtb method)"
echo "15. FA_bxde_qcore: Mechanisms of formic acid decomposition using qcore (xtb method) and BXDE sampling"
echo "16. ttors:         Torsional transition states of FA"
