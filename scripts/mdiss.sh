#!/bin/bash

source utils.sh
#On exit remove tmp files
tmp_files=(tmp* fort.*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
exe=$(basename $0)
cwd=$PWD
#Enter HL or LL 
tag=$1

if [ -f amk.dat ];then
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
#reading input
read_input
###
tsdir=tsdir${tag}_${molecule}
rxnet=${tsdir}/KMC/RXNet_long.cg_groupedprods

rm -rf ${tsdir}/rxn_all.txt

if [ ! -f $rxnet ];then
   echo $rxnet has not been created
   exit 0
else
   if [ -f tsdir${tag}_${molecule}/KMC/starting_minimum ]; then
       awk '{print $1,$1," 1"}' tsdir${tag}_${molecule}/KMC/starting_minimum > ${tsdir}/rxn_all.txt
   fi
   awk 'NR>2{if($7=="MIN" && $10=="MIN" ) print $8,$11,"1"}' $rxnet >> ${tsdir}/rxn_all.txt 
   mdiss.py $tag $molecule
fi

