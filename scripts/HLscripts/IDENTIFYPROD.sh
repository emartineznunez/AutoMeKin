#!/bin/bash
source utils.sh
#remove tmp files
tmp_files=(tmp tmp_code tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing"
   exit
fi

cwd=$PWD
exe=$(basename $0)

###reading input file
read_input
####

en=$(awk 'BEGIN{if('$rate'==0) en=100;if('$rate'==1) en='$energy'};{if($1=="MaxEn") en=$2};END{print en}' $inputfile )

nlprlist=$(wc -l $tsdirhl/PRODs/PRlist | awk '{print $1}')

if [ $nlprlist -eq 1 ];then
   echo "No products for this system"
   minn0=$(awk '/min0/{print $2}' $tsdirhl/MINs/SORTED/MINlist_sorted)
   minn=$(awk 'BEGIN{minn='$minn0'};/ '$minn0' /{minn=$1};END{print minn}' $tsdirhl/working/conf_isomer.out)
   if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirhl/KMC/RXNet_long.cg ) -eq 0 ]; then 
      echo "No connected paths found (RXNet_long.cg is empty)"
   else
      linked_paths.py $tsdirhl/KMC/RXNet_long.cg $minn $en > $tsdirhl/KMC/RXNet_long.cg_groupedprods
   fi
   exit
fi

echo "codes of products" > tmp_code
for name in $(sqlite3 $tsdirhl/PRODs/prodhl.db "select name from prodhl")
do
   formula="$(sqlite3 $tsdirhl/PRODs/prodhl.db "select natom,geom from prodhl where name='$name'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
   echo "$formula" >>tmp_code
   sqlite3 ${tsdirhl}/PRODs/prodhl.db "update prodhl set formula='$formula' where name='$name';"
   echo "Getting the formula for $name"
done


paste $tsdirhl/PRODs/PRlist tmp_code > $tsdirhl/PRODs/PRlist_kmc

lastmin=$(awk '{lm=$2};END{print lm}' $tsdirhl/MINs/SORTED/MINlist_sorted )

sed 's/ + /+/g' $tsdirhl/PRODs/PRlist_kmc | awk 'BEGIN{n='$lastmin'} 
{if(NR==1) print $0
if($1=="PROD") {++i
  fl[i]=$NF
  j=1
  p=1
  while(j<=i-1){
   if(fl[i]==fl[j]) {p=0;code[i]=code[j];break}
   j++
   }
  if(p==1) {++n;code[i]=n}
  print $1,$2,code[i]
  }
}' > $tsdirhl/PRODs/PRlist_kmc.log


cat $tsdirhl/PRODs/PRlist_kmc.log $tsdirhl/KMC/RXNet_long.cg | awk '/PROD/{if(NF==3) ncode[$2]=$3} 
/KMC file/{lp=1;print $0}
{if(lp==1) {
  if($10~"MIN" || $1~"number") print $0
  if($10~"PROD") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %15.0f %6.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,ncode[$11],$12,$13,$14
  }
}' >tmp

minn0=$(awk '/min0/{print $2}' $tsdirhl/MINs/SORTED/MINlist_sorted)
minn=$(awk 'BEGIN{minn='$minn0'};/ '$minn0' /{minn=$1};END{print minn}' $tsdirhl/working/conf_isomer.out)

if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirhl/KMC/RXNet_long.cg ) -eq 0 ]; then 
   echo "No connected paths found (RXNet_long.cg is empty)"
   exit
else
   linked_paths.py tmp $minn $en > $tsdirhl/KMC/RXNet_long.cg_groupedprods
fi


