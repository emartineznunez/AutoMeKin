#!/bin/bash
source utils.sh
#remove tmp files
tmp_files=(tmp tmp_code tmp_geom tmp_pf tmp* fort.*)
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

nlprlist=$(wc -l $tsdirll/PRODs/PRlist | awk '{print $1}')

if [ $nlprlist -eq 1 ];then
   echo "No products for this system"
   minn0=$(awk '/min0/{print $2}' $tsdirll/MINs/SORTED/MINlist_sorted)
   minn=$(awk 'BEGIN{minn='$minn0'};/ '$minn0' /{minn=$1};END{print minn}' $tsdirll/working/conf_isomer.out)
   if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirll/KMC/RXNet_long.cg ) -eq 0 ]; then 
      echo "No connected paths found (RXNet_long.cg is empty)"
   else
      linked_paths.py $tsdirll/KMC/RXNet_long.cg $minn $en  > $tsdirll/KMC/RXNet_long.cg_groupedprods
   fi
   exit
fi

echo "codes of products" > tmp_code
rm -rf ${tsdirll}/PRODs/PRlist_tags.log
for name in $(sqlite3 ${tsdirll}/PRODs/prod.db "select name from prod")
do
   named=$(echo $name | sed 's/_min/ min/' | awk '{print $2}')
   if [ ! -f ${tsdirll}/PRODs/${named}_formula ]; then
      echo "Getting the formula for $name"
      formula="$(sqlite3 ${tsdirll}/PRODs/prod.db "select natom,geom from prod where name='$name'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
      echo "$formula" > ${tsdirll}/PRODs/${named}_formula
   else
      formula="$(cat ${tsdirll}/PRODs/${named}_formula)"
   fi
   if [ ! -f ${tsdirll}/PRODs/${named}_tag ]; then
      echo "Getting the unique tag for $name"
      sqlite3 ${tsdirll}/PRODs/prod.db "select natom,geom from prod where name='$name'" | sed 's@|@\n\n@g'  > tmp_geom
      tag_prod.py tmp_geom | sed 's@-0.000@0.000@g'  > ${tsdirll}/PRODs/${named}_tag
   fi 
   sqlite3 ${tsdirll}/PRODs/prod.db "update prod set formula='$formula' where name='$name';"
   cat ${tsdirll}/PRODs/${named}_formula >>tmp_code
   sqlite3 ${tsdirll}/PRODs/prod.db "select energy,formula from prod where name='$name'" | awk '{for (i=1;i<=NF;i++) printf "%s",$i;printf "\n"}' | sed 's@|@ @g' >tmp_pf
   paste tmp_pf ${tsdirll}/PRODs/${named}_tag  >> ${tsdirll}/PRODs/PRlist_tags.log
done

paste $tsdirll/PRODs/PRlist tmp_code > $tsdirll/PRODs/PRlist_kmc

lastmin=$(awk '{lm=$2};END{print lm}' $tsdirll/MINs/SORTED/MINlist_sorted )

sed 's/ + /+/g' $tsdirll/PRODs/PRlist_kmc | awk 'BEGIN{n='$lastmin'} 
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
}' > $tsdirll/PRODs/PRlist_kmc.log


cat $tsdirll/PRODs/PRlist_kmc.log $tsdirll/KMC/RXNet_long.cg | awk '/PROD/{if(NF==3) ncode[$2]=$3} 
/KMC file/{lp=1;print $0}
{if(lp==1) {
  if($10~"MIN" || $1~"number") print $0
  if($10~"PROD") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %15.0f %6.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,ncode[$11],$12,$13,$14
  }
}' >tmp

minn0=$(awk '/min0/{print $2}' $tsdirll/MINs/SORTED/MINlist_sorted)
minn=$(awk 'BEGIN{minn='$minn0'};/ '$minn0' /{minn=$1};END{print minn}' $tsdirll/working/conf_isomer.out)

if [ $(awk 'BEGIN{nts=0};{if($1=="TS") ++nts};END{print nts}' $tsdirll/KMC/RXNet_long.cg ) -eq 0 ]; then 
   echo "No connected paths found (RXNet_long.cg is empty)"
   exit 
else
   linked_paths.py tmp $minn $en > $tsdirll/KMC/RXNet_long.cg_groupedprods
fi

