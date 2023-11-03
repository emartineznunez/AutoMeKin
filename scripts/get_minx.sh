#!/bin/bash
source utils.sh
#On exit remove tmp files
tmp_files=(kk )
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
rxnfile=$1
smin=$2
en=$3
factor=$4

awk '{if(NR>2 && $10=="MIN" && $5<='$en') print $0}' $rxnfile > tmp_rxn

nlin=$(wc -l tmp_rxn | awk '{print $1}')
if [ $nlin -eq 0 ]; then
   echo "Warning, MaxEn is probably too low!!!. iamk not running: No minima selected besides the reference structure"
   echo $smin 
   exit
fi

rm -rf tmp_rxn2
for i in $(awk '{print NR}' tmp_rxn)
do
  awk 'NR=='$i',NR=='$i'{print $8}'  tmp_rxn >> tmp_rxn2
  awk 'NR=='$i',NR=='$i'{print $11}' tmp_rxn >> tmp_rxn2
done

awk '{a[NR]=$1}
END{
for(i=1;i<=NR;i++) {ok=1;
     for(j=1;j<i;j++) if(a[i]==a[j]) ok=0 ;
     if(ok==1) print a[i] }
}' tmp_rxn2 | sort -g 

