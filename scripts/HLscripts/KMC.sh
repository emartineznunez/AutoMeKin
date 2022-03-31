#!/bin/bash
source utils.sh
#remove tmp files
tmp_files=(tmprxn tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
exe=$(basename $0)

inputfile=amk.dat
cwd=$PWD
##reading input file
read_input
#####
##### units employed in the RRKM calc. default is ps-1
#####

units=1e-12

rxnfile=$(awk 'BEGIN{suf="_long.cg_groupedprods"};/PathInfo/{if($2=="Relevant") suf=".relevant"};END{print "RXNet"suf}' $inputfile )


if [ $rate -eq 0 ] && [ $temperature -eq 0 ] ; then
      echo "For a canonical ensemble please provide a temperature (Temperature)"
      exit
fi
if [ $rate -eq 1 ] && [ $energy -eq 0 ] ; then
      echo "For a microcanonical ensemble please provide an energy (Energy)"
      exit
fi



if [ $imin == "ask" ]; then
   echo -n "Provide the label of the starting minimum: "
   read imin
fi
if [ $imin == "min0" ]; then
   minn=$(awk '/min0/{print $2}' $tsdirhl/MINs/SORTED/MINlist_sorted)
   imin=$(awk 'BEGIN{min='$minn'}
   {for(i=1;i<=NF;i++) {m[NR,i]=$i;iso[NR]=NF}
   j=1
   while(j<=iso[NR]){
      if('$minn'==m[NR,j]) min=m[NR,1]
      j++
      }
   }
   END{print min}' $tsdirhl/working/conf_isomer.out )
fi




if [ -f $tsdirhl/KMC/$rxnfile ]; then
   echo "RXNfile is: "$tsdirhl"/KMC/"$rxnfile
else
   echo "Specify a valid keyword for PathInfo"
   exit
fi
##is there any connected path?
npaths=$(awk 'END{print NR-2}' ${tsdirhl}/KMC/$rxnfile)
if [ $npaths -eq 0 ]; then
   echo "No connected paths"
   exit 1
fi
if [ $rate -eq 1 ]; then
   if [ -z "$energy" ]; then
      echo "Energy not given. Please provide an energy (in kcal/mol) using keyword Energy" 
      exit
   fi 
   if [ ! -d "$tsdirhl/KMC/RRKM" ]; then
      echo "$tsdirhl/KMC/RRKM does not exist. It will be created"
      mkdir $tsdirhl/KMC/RRKM
   else
      echo "$tsdirhl/KMC/RRKM already exists. It will be created again"
      rm -r $tsdirhl/KMC/RRKM
      mkdir $tsdirhl/KMC/RRKM
   fi

elif [ $rate -eq 0 ]; then
   if [ $temperature -eq 0 ]; then
      echo "Temperature not given. Please provide a temperature (in K) using keyword Temperature" 
      exit
   fi 
   if [ ! -d "$tsdirhl/KMC/TST" ]; then
      echo "$tsdirhl/KMC/TST does not exist. It will be created"
      mkdir $tsdirhl/KMC/TST
   else
      echo "$tsdirhl/KMC/TST already exists. It will be created again"
      rm -r $tsdirhl/KMC/TST
      mkdir $tsdirhl/KMC/TST
   fi
fi
#Now, gather all information: freqs, barriers, etc to make TST/KMC analysis
#temperature is the temperature in K
#units is a factor from s-1 to (ps in this case)
#imin is the min from which we start the kinectics
#nmol is the number of molecules in the KMC calculations
#step is the step size for printout in the KMC calc
if [ -f $tsdirhl/KMC/processinformation ]; then rm $tsdirhl/KMC/processinformation ; fi
zero=0
echo "Starting minimum" $imin
echo  $imin > ${tsdirhl}/KMC/starting_minimum
nnpro=0
awk '{if(NR>2) print $0}' $tsdirhl/KMC/$rxnfile > tmprxn
for i in $(awk '{print NR}' tmprxn)
do
  ((nnpro=nnpro+1))
  ts=$(awk 'NR=='$i',NR=='$i'{print $3}' tmprxn)
  tsn=$(awk 'NR=='$i',NR=='$i'{print $2}' tmprxn)
  procn=$(awk 'NR=='$i',NR=='$i'{print $2}' tmprxn)
  min1=$(awk 'NR=='$i',NR=='$i'{print $8}'  tmprxn)
  nproc=$(awk 'BEGIN{nproc=1};NR=='$i',NR=='$i'{if($10~"MIN") nproc=nproc+1};END{print nproc}' tmprxn)
  state1=$(awk 'NR=='$i',NR=='$i'{print $8}' tmprxn)
  state2=$(awk 'NR=='$i',NR=='$i'{print $11}' tmprxn)
  lmin1=MIN$min1
  lts=TS$tsn
  echo "Proc" $nnpro "TS" $tsn $state1 $state2 >> $tsdirhl/KMC/processinformation

  if [ $nproc -eq 2 ]; then
     deg1=$(awk 'NR=='$i',NR=='$i'{print $15/$14/$12}' tmprxn)
  else
     deg1=$(awk 'NR=='$i',NR=='$i'{print $14/$13/$12}' tmprxn)
  fi

#
  if [ $rate -eq 0 ]; then
     g1="$(awk 'NR=='$i',NR=='$i'{printf "%10.3f\n",$5}' tmprxn)"
     g2="$(awk '{if($2=='$min1') printf "%10.3f\n",$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)"
     deltag="$(echo "$g1" "$g2" | awk '{printf "%10.3f",$1-$2}')"
     echo $deltag $temperature $deg1 > $tsdirhl/KMC/TST/"proc1_TS"$procn".dat" 
     tst.exe <$tsdirhl/KMC/TST/proc1_TS${procn}.dat > $tsdirhl/KMC/TST/proc1_TS${procn}.out
     rate1=$(awk '{print $0}' $tsdirhl/KMC/TST/proc1_TS${procn}.out )
     echo $rate1 $state1 $state2 >> $tsdirhl/KMC/TST/rate${temperature}.out
  elif [ $rate -eq 1 ]; then
     ets=$(awk 'NR=='$i',NR=='$i'{printf "%10.0f\n",349.75*$5}' tmprxn)
     errkm0=$( awk '{if($1=="Energy") printf "%10.0f\n",349.75*$2}'  $inputfile )
     e0=$(awk '{if(NR==1) printf "%10.0f\n",349.75*$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
     ((errkm=errkm0-e0+1000))
     egap=$(awk '{if($2=='$min1') printf "%10.0f\n",349.75*$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
     egapkcal=$(awk '{if($2=='$min1') printf "%15.4f\n",$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
     echo "Direct via TS"$procn" for process "$state1 $state2 $egapkcal $energy > $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     ebarrier=$(echo "$ets - $egap" | bc -l)
     if [ $ebarrier -lt 0 ]; then ebarrier=0 ; fi
     echo "$errkm,"$ebarrier",100,0,"$deg1",0,0" >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     echo "0,0"  >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     echo "rrkm" >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     echo "1.0"  >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
###sqlite3
     sqlite3 $tsdirhl/MINs/SORTED/minshl.db "select freq from minshl where name='$lmin1'" | wc -l >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     sqlite3 $tsdirhl/MINs/SORTED/minshl.db "select freq from minshl where name='$lmin1'" | awk '{printf "%10.0f\n",sqrt($1*$1)}'  >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     sqlite3 $tsdirhl/TSs/SORTED/tsshl.db "select freq from tsshl where name='$lts'" | awk 'END{print NR-1}'  >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
     sqlite3 $tsdirhl/TSs/SORTED/tsshl.db "select freq from tsshl where name='$lts'" | awk '{if($1>0) printf "%10.0f\n",$1}'  >> $tsdirhl/KMC/RRKM/proc1_TS${procn}.dat
###
     echo "Running proc1_TS"$procn".dat"
     rrkm.exe <$tsdirhl/KMC/RRKM/proc1_TS${procn}.dat > $tsdirhl/KMC/RRKM/proc1_TS${procn}.out  
     awk 'BEGIN{ns=100000}
     /via/{p1=$6;p2=$7;e=('$energy'-$8)*349.75;if(e<0) {print "0.0",p1,p2;exit}}
     /k\(E/{ns=NR}
     {if(NR<(ns+2))
        dif=1000
     else {
        dif=e-$1
        if(dif<0 && NR==(ns+2)) {print "0.0",p1,p2;exit}
        if(dif<0 && NR>(ns+2)) {print $2*'$units',p1,p2;exit}} }'  $tsdirhl/KMC/RRKM/proc1_TS${procn}.out >> $tsdirhl/KMC/RRKM/rate${energy}.out
  fi 
  if [ $nproc -eq 2 ]; then
     ((nnpro=nnpro+1))
     echo "Proc" $nnpro "TS" $tsn $state2 $state1 >> $tsdirhl/KMC/processinformation
     min2=$(awk 'NR=='$i',NR=='$i'{print $11}' tmprxn)
     lmin2=MIN$min2
     deg2=$(awk 'NR=='$i',NR=='$i'{print $15/$16/$13}' tmprxn)
     if [ $rate -eq 0 ]; then
        g2="$(awk '{if($2=='$min2') printf "%10.3f\n",$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)"
        deltag="$(echo "$g1" "$g2" | awk '{printf "%10.3f",$1-$2}')"
        echo $deltag $temperature $deg2 > $tsdirhl/KMC/TST/proc2_TS${procn}.dat 
        tst.exe <$tsdirhl/KMC/TST/proc2_TS${procn}.dat > $tsdirhl/KMC/TST/proc2_TS${procn}.out
        rate2=$(awk '{print $0}' $tsdirhl/KMC/TST/proc2_TS${procn}.out )
        echo $rate2 $state2 $state1 >> $tsdirhl/KMC/TST/rate${temperature}.out
     elif [ $rate -eq 1 ]; then
        egap=$(awk '{if($2=='$min2') printf "%10.0f\n",349.75*$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
        egapkcal=$(awk '{if($2=='$min2') printf "%15.4f\n",$4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
        echo "Reverse via TS"$procn" for process "$state2 $state1 $egapkcal $energy > $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        deg2=$(awk 'NR=='$i',NR=='$i'{print $15/$16/$13}' tmprxn)
        ebarrier=$(echo "$ets - $egap" | bc -l)
        if [ $ebarrier -lt 0 ]; then ebarrier=0 ; fi
        echo "$errkm,"$ebarrier",100,0,"$deg2",0,0" >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        echo "0,0"  >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        echo "rrkm" >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        echo "1.0"  >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
###sqlite3
#nfreq_react
        sqlite3 $tsdirhl/MINs/SORTED/minshl.db "select freq from minshl where name='$lmin2'" | wc -l >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        sqlite3 $tsdirhl/MINs/SORTED/minshl.db "select freq from minshl where name='$lmin2'" | awk '{printf "%10.0f\n",sqrt($1*$1)}'  >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
#nfreq_ts
        sqlite3 $tsdirhl/TSs/SORTED/tsshl.db "select freq from tsshl where name='$lts'" | awk 'END{print NR-1}'  >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
        sqlite3 $tsdirhl/TSs/SORTED/tsshl.db "select freq from tsshl where name='$lts'" | awk '{if($1>0) printf "%10.0f\n",$1}'  >> $tsdirhl/KMC/RRKM/proc2_TS${procn}.dat
###
        echo "Running proc2_TS"$procn".dat"
        rrkm.exe <$tsdirhl/KMC/RRKM/proc2_TS${procn}.dat > $tsdirhl/KMC/RRKM/proc2_TS${procn}.out  
        awk 'BEGIN{ns=100000}
        /via/{p1=$6;p2=$7;e=('$energy'-$8)*349.75;if(e<0) {print "0.0",p1,p2;exit}}
        /k\(E/{ns=NR}
        {if(NR<(ns+2))
           dif=1000
        else {
           dif=e-$1
           if(dif<0 && NR==(ns+2)) {print "0.0",p1,p2;exit}
           if(dif<0 && NR>(ns+2)) {print $2*'$units',p1,p2;exit}} }'  $tsdirhl/KMC/RRKM/proc2_TS${procn}.out >> $tsdirhl/KMC/RRKM/rate${energy}.out
     fi
  fi
done

if [ $rate -eq 0 ]; then
   echo "kmc calc" > $tsdirhl/KMC/kmcT${temperature}.dat
   nproc=$(awk 'END{print NR}' $tsdirhl/KMC/TST/rate${temperature}.out)
   nspec=$(awk 'BEGIN{max=0};{if($2 >max) max=$2;if($3>max) max=$3};END{print max}' $tsdirhl/KMC/TST/rate${temperature}.out)
   echo $nproc, $nspec, "1" >> $tsdirhl/KMC/kmcT${temperature}.dat
   cat $tsdirhl/KMC/TST/rate${temperature}.out >> $tsdirhl/KMC/kmcT${temperature}.dat
   for i in $(seq 1 $nspec)
   do
     if [ $i -eq $imin ]; then
        echo $nmol >> $tsdirhl/KMC/kmcT${temperature}.dat
     else
        echo "0" >> $tsdirhl/KMC/kmcT${temperature}.dat
     fi
   done
   echo "0" >> $tsdirhl/KMC/kmcT${temperature}.dat
   echo $step >> $tsdirhl/KMC/kmcT${temperature}.dat
   echo "Running KMC calc"
   kmc.exe <$tsdirhl/KMC/kmcT${temperature}.dat > $tsdirhl/KMC/kmcT${temperature}.out
   kmcfile=$tsdirhl/KMC/kmcT${temperature}.out
   postb=T$temperature
elif [ $rate -eq 1 ]; then
   echo "kmc calc" > $tsdirhl/KMC/kmcE${energy}.dat
   nproc=$(awk 'END{print NR}' $tsdirhl/KMC/RRKM/rate${energy}.out)
   nspec=$(awk 'BEGIN{max=0};{if($2 >max) max=$2;if($3>max) max=$3};END{print max}' $tsdirhl/KMC/RRKM/rate${energy}.out)
   echo $nproc, $nspec, "1" >> $tsdirhl/KMC/kmcE${energy}.dat
   cat $tsdirhl/KMC/RRKM/rate${energy}.out >> $tsdirhl/KMC/kmcE${energy}.dat
   for i in $(seq 1 $nspec)
   do
     if [ $i -eq $imin ]; then
        echo $nmol >> $tsdirhl/KMC/kmcE${energy}.dat
     else
        echo "0" >> $tsdirhl/KMC/kmcE${energy}.dat
     fi
   done
   echo "0" >> $tsdirhl/KMC/kmcE${energy}.dat
   echo $step >> $tsdirhl/KMC/kmcE${energy}.dat
   kmc.exe <$tsdirhl/KMC/kmcE${energy}.dat>$tsdirhl/KMC/kmcE${energy}.out
   kmcfile=$tsdirhl/KMC/kmcE${energy}.out
   postb=E$energy
fi

#getting the branching ratios
lastmin=$(awk '{lm=$2};END{print lm}' $tsdirhl/MINs/SORTED/MINlist_sorted )
awk 'BEGIN{ok=0}
/Population of every species/{point=NR;ok=1}
/counts per process/{ok=0}
{if(ok==1 && NR>point) print $0
}' $kmcfile > $tsdirhl/KMC/branching$postb
echo "  %  Products" > $tsdirhl/KMC/branching${postb}.out
for i in $(awk '{print $1}' $tsdirhl/KMC/branching$postb)
do
   popp=$(awk 'NR=='$i',NR=='$i'{print $2/'$nmol'*100}' $tsdirhl/KMC/branching$postb)
   if [ $i -gt $lastmin ] ; then
      code=$(awk '{if($3=='$i') {print $2;exit}}' $tsdirhl/PRODs/PRlist_kmc.log)
      name=$(awk '{if($2=='$code') print $3}' $tsdirhl/PRODs/PRlist_kmc)
      namen=$(basename $name .rxyz)
      namesql=PR${code}_${namen}
      prod="$(sqlite3 $tsdirhl/PRODs/prodhl.db "select formula from prodhl where name='$namesql'")"
      printf "%8s %10s\n" $popp "$prod" >> $tsdirhl/KMC/branching${postb}.out
   fi
done
