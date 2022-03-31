#!/bin/bash
source utils.sh
#On exit remove tmp files
tmp_files=(tmp_min tmp_rxn tmp* fort.17)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
rxnfile=$1
smin=$2
en=$3
factor=$4

if [ ! -d "tmp_min" ]; then
   mkdir tmp_min
else
   rm -r tmp_min/
   mkdir tmp_min
fi

inputfile=amk.dat
##### units employed in the RRKM calc. default is ps-1
units=1e-12
temperature=$( awk 'BEGIN{t=0};{if($1=="Temperature") t=$2};END{print t*'$factor'}'  $inputfile )
energy=$( awk 'BEGIN{e=0};{if($1=="Energy") e=$2};END{print e*'$factor'}'  $inputfile )
nmol=1000
rate=$( awk '{if ($1=="Temperature") print "0";if($1=="Energy") print "1" }' $inputfile )
maxtime=1e24
step=1e23

if [ ! -f $rxnfile ]; then
   echo "RXNfile does not exist"
   exit
fi

if [ $rate -eq 1 ]; then
   if [ -z $energy ]; then
      echo "Energy not given. Please provide an energy (in kcal/mol) using keyword Energy" 
      exit
   fi 
   if [ ! -d "tmp_min/RRKM" ]; then
      mkdir tmp_min/RRKM
   else
      rm -r tmp_min/RRKM	
      mkdir tmp_min/RRKM
   fi

elif [ $rate -eq 0 ]; then
   if [ -z $temperature ]; then
      echo "Temperature not given. Please provide a temperature (in K) using keyword Temperature" 
      exit
   fi 
   if [ ! -d "tmp_min/TST" ]; then
      mkdir tmp_min/TST
   else
      rm -r tmp_min/TST/
      mkdir tmp_min/TST
   fi
fi

pelao=$(basename $rxnfile)
dir="$(echo "$rxnfile" | sed 's/\/KMC\/'$pelao'//g')"
#ext is hl only when tsdirHL_molecule dir is employed 
ext=$(echo $dir | awk '/HL/{print "hl"}')

nnpro=0
awk '{if(NR>2 && $10=="MIN" && $5<='$en') print $0}' $rxnfile > tmp_rxn
nlin=$(wc -l tmp_rxn | awk '{print $1}')
if [ $nlin -eq 0 ]; then
   echo "Warning, MaxEn is probably too low!!!. iamk not running: No minima selected besides the reference structure"
   echo $smin 
   exit
fi

for i in $(awk '{print NR}' tmp_rxn)
do
  ((nnpro=nnpro+1))
  ts=$(awk 'NR=='$i',NR=='$i'{print $3}' tmp_rxn)
  tsn=$(awk 'NR=='$i',NR=='$i'{print $2}' tmp_rxn)
  procn=$(awk 'NR=='$i',NR=='$i'{print $2}' tmp_rxn)
  min1=$(awk 'NR=='$i',NR=='$i'{print $8}'  tmp_rxn)
  min2=$(awk 'NR=='$i',NR=='$i'{print $11}' tmp_rxn)
  deg1=$(awk 'NR=='$i',NR=='$i'{print $15/$14/$12}' tmp_rxn)
  deg2=$(awk 'NR=='$i',NR=='$i'{print $15/$16/$13}' tmp_rxn)
  lmin1="MIN"$min1
  lmin2="MIN"$min2
  lts="TS"$tsn
#
  if [ $rate -eq 0 ]; then
     g1="$(awk 'NR=='$i',NR=='$i'{printf "%10.3f\n",$5}' tmp_rxn)"
     g2="$(awk '{if($2=='$min1') printf "%10.3f\n",$4}' $dir/MINs/SORTED/MINlist_sorted)"
     deltag="$(echo "$g1" "$g2" | awk '{printf "%10.3f",$1-$2}')"
     echo $deltag $temperature $deg1 > tmp_min/TST/proc1_TS${procn}.dat 
     tst.exe <tmp_min/TST/proc1_TS${procn}.dat > tmp_min/TST/proc1_TS${procn}.out
     rate1=$(awk '{print $0}' tmp_min/TST/proc1_TS${procn}.out) 
     echo $rate1 $min1 $min2 >> tmp_min/TST/rate${temperature}.out
  elif [ $rate -eq 1 ]; then
     ets=$(awk 'NR=='$i',NR=='$i'{printf "%10.0f\n",349.75*$5}' tmp_rxn)
     e1="$(awk '{if($1=="Energy") printf "%10.0f\n",349.75*$2}'  $inputfile)"
     e2="$(awk '{if(NR==1) printf "%10.0f\n",349.75*$4}' $dir/MINs/SORTED/MINlist_sorted)"
     e12="$e1
     $e2"
     errkm="$(echo "$e12" | awk '{e[NR]=$1};END{print int('$factor'*(e[1]-e[2])+1000)}')"
     egap=$(awk '{if($2=='$min1') printf "%10.0f\n",349.75*$4}' $dir/MINs/SORTED/MINlist_sorted)
     egapkcal=$(awk '{if($2=='$min1') printf "%15.4f\n",$4}' $dir/MINs/SORTED/MINlist_sorted)
     echo "Direct via TS"$procn" for process "$min1 $min2 $egapkcal $energy > tmp_min/RRKM/proc1_TS${procn}.dat
     ((ebarrier=ets-egap))
     if [ $ebarrier -lt 0 ]; then ebarrier=0 ; fi
     echo "$errkm,"$ebarrier",100,0,"$deg1",0,0" >> tmp_min/RRKM/proc1_TS${procn}.dat
     echo "0,0" >> tmp_min/RRKM/proc1_TS${procn}.dat
     echo "rrkm" >> tmp_min/RRKM/proc1_TS${procn}.dat
     echo "1.0" >> tmp_min/RRKM/proc1_TS${procn}.dat

###sqlite3
     sqlite3 $dir/MINs/SORTED/mins${ext}.db "select freq from mins${ext} where name='$lmin1'" | wc -l >> tmp_min/RRKM/proc1_TS${procn}.dat
     sqlite3 $dir/MINs/SORTED/mins${ext}.db "select freq from mins${ext} where name='$lmin1'" | awk '{printf "%10.0f\n",sqrt($1*$1)}'  >> tmp_min/RRKM/proc1_TS${procn}.dat
     sqlite3 $dir/TSs/SORTED/tss${ext}.db "select freq from tss${ext} where name='$lts'" | awk 'END{print NR-1}'  >> tmp_min/RRKM/proc1_TS${procn}.dat
     sqlite3 $dir/TSs/SORTED/tss${ext}.db "select freq from tss${ext} where name='$lts'" | awk 'NR>1{printf "%10.0f\n",sqrt($1*$1)}'  >> tmp_min/RRKM/proc1_TS${procn}.dat
###
     rrkm.exe <tmp_min/RRKM/proc1_TS${procn}.dat > tmp_min/RRKM/proc1_TS${procn}.out  
     awk 'BEGIN{ns=100000}
     /via/{p1=$6;p2=$7;e=('$energy'-$8)*349.75;if(e<0) {print "0.0",p1,p2;exit}}
     /k\(E/{ns=NR}
     {if(NR<(ns+2))
        dif=1000
     else {
        dif=e-$1
        if(dif<0 && NR==(ns+2)) {print "0.0",p1,p2;exit}
        if(dif<0 && NR>(ns+2)) {print $2*'$units',p1,p2;exit}} }'  tmp_min/RRKM/proc1_TS${procn}.out >> tmp_min/RRKM/rate${energy}.out
  fi 
  ((nnpro=nnpro+1))
  if [ $rate -eq 0 ]; then
     g1="$(awk 'NR=='$i',NR=='$i'{printf "%10.3f\n",$5}' tmp_rxn)"
     g2="$(awk '{if($2=='$min2') printf "%10.3f\n",$4}' $dir/MINs/SORTED/MINlist_sorted)"
     deltag="$(echo "$g1" "$g2" | awk '{printf "%10.3f",$1-$2}')" 
     echo $deltag $temperature $deg2 > tmp_min/TST/proc2_TS${procn}.dat 
     tst.exe <tmp_min/TST/proc2_TS${procn}.dat >tmp_min/TST/proc2_TS${procn}.out
     rate2=$(awk '{print $0}' tmp_min/TST/proc2_TS${procn}.out) 
     echo $rate2 $min2 $min1 >> tmp_min/TST/rate${temperature}.out
  elif [ $rate -eq 1 ]; then
     egap=$(awk '{if($2=='$min2') printf "%10.0f\n",349.75*$4}' $dir/MINs/SORTED/MINlist_sorted)
     egapkcal=$(awk '{if($2=='$min2') printf "%15.4f\n",$4}' $dir/MINs/SORTED/MINlist_sorted)
     echo "Reverse via TS"$procn" for process "$min2 $min1 $egapkcal $energy > tmp_min/RRKM/proc2_TS${procn}.dat
     deg2=$(awk 'NR=='$i',NR=='$i'{print $15/$16/$13}' tmp_rxn)
     ((ebarrier=ets-egap))
     if [ $ebarrier -lt 0 ]; then ebarrier=0 ; fi
     echo "$errkm,"$ebarrier",100,0,"$deg2",0,0" >> tmp_min/RRKM/proc2_TS${procn}.dat
     echo "0,0" >> tmp_min/RRKM/proc2_TS${procn}.dat
     echo "rrkm" >> tmp_min/RRKM/proc2_TS${procn}.dat
     echo "1.0" >> tmp_min/RRKM/proc2_TS${procn}.dat
###sqlite3
     sqlite3 $dir/MINs/SORTED/mins${ext}.db "select freq from mins${ext} where name='$lmin2'" | wc -l >> tmp_min/RRKM/proc2_TS${procn}.dat
     sqlite3 $dir/MINs/SORTED/mins${ext}.db "select freq from mins${ext} where name='$lmin2'" | awk '{printf "%10.0f\n",sqrt($1*$1)}'  >> tmp_min/RRKM/proc2_TS${procn}.dat
     sqlite3 $dir/TSs/SORTED/tss${ext}.db "select freq from tss${ext} where name='$lts'" | awk 'END{print NR-1}'  >> tmp_min/RRKM/proc2_TS${procn}.dat
     sqlite3 $dir/TSs/SORTED/tss${ext}.db "select freq from tss${ext} where name='$lts'" | awk 'NR>1{printf "%10.0f\n",sqrt($1*$1)}'  >> tmp_min/RRKM/proc2_TS${procn}.dat
###

     rrkm.exe <tmp_min/RRKM/proc2_TS${procn}.dat >tmp_min/RRKM/proc2_TS${procn}.out
     awk 'BEGIN{ns=100000}
     /via/{p1=$6;p2=$7;e=('$energy'-$8)*349.75;if(e<0) {print "0.0",p1,p2;exit}}
     /k\(E/{ns=NR}
     {if(NR<(ns+2))
        dif=1000
     else {
        dif=e-$1
        if(dif<0 && NR==(ns+2)) {print "0.0",p1,p2;exit}
        if(dif<0 && NR>(ns+2)) {print $2*'$units',p1,p2;exit}} }'  tmp_min/RRKM/proc2_TS${procn}.out >> tmp_min/RRKM/rate${energy}.out
  fi
done


if [ $rate -eq 0 ]; then
   echo "kmc calc" > tmp_min/kmcT${temperature}.dat
   nproc=$(awk 'END{print NR}' tmp_min/TST/rate${temperature}.out)
   nspec=$(awk 'BEGIN{max=0};{if($2 >max) max=$2;if($3>max) max=$3};END{print max}' tmp_min/TST/rate${temperature}.out)
   echo $nproc, $nspec, "1" >> tmp_min/kmcT${temperature}.dat
   cat tmp_min/TST/rate$temperature.out >> tmp_min/kmcT${temperature}.dat
   for i in $(seq 1 $nspec)
   do
     if [ $i -eq $smin ]; then
        echo $nmol >> tmp_min/kmcT${temperature}.dat
     else
        echo "0" >> tmp_min/kmcT${temperature}.dat
     fi
   done
   echo "0" >> tmp_min/kmcT${temperature}.dat
   echo $maxtime $step >> tmp_min/kmcT${temperature}.dat
   kmcEND.exe <tmp_min/kmcT${temperature}.dat>tmp_min/kmcout
   rm -r tmp_min/TST
elif [ $rate -eq 1 ]; then
   echo "kmc calc" > tmp_min/kmcE${energy}.dat
   nproc=$(awk 'END{print NR}' tmp_min/RRKM/rate${energy}.out)
   nspec=$(awk 'BEGIN{max=0};{if($2 >max) max=$2;if($3>max) max=$3};END{print max}' tmp_min/RRKM/rate${energy}.out)
   echo $nproc, $nspec, "1" >> tmp_min/kmcE${energy}.dat
   cat tmp_min/RRKM/rate$energy.out >> tmp_min/kmcE${energy}.dat
   for i in $(seq 1 $nspec)
   do
     if [ $i -eq $smin ]; then
        echo $nmol >> tmp_min/kmcE${energy}.dat
     else
        echo "0" >> tmp_min/kmcE${energy}.dat
     fi
   done
   echo "0" >> tmp_min/kmcE${energy}.dat
   echo $maxtime $step >> tmp_min/kmcE${energy}.dat
   kmcEND.exe <tmp_min/kmcE${energy}.dat>tmp_min/kmcout
   rm -r tmp_min/RRKM
fi

awk '/counts per process/{p=1}
{if(NF==4 && p==1){
  if($2>0) print $2,$3,$4
  }
}' tmp_min/kmcout>tmp_min/kmcout.log

sort -rg tmp_min/kmcout.log | awk 'BEGIN{m[0]='$smin';i=1;det=0}
{++i;m[i]=$3
++i;m[i]=$2
if($2==m[0] && det==0) {m[1]=$3;det=1}
if($3==m[0] && det==0) {m[1]=$2;det=1}
n=i
}
END{i=0
while(i<=n){
   j=0
   ok=1
   while(j<i){
      if(m[j]==m[i]) ok=0
      j++
      }
   if(ok==1) print m[i]
   i++
   }
}' 

