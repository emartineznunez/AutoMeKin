#!/bin/bash
# script to remove ts $1
source utils.sh
#On exit remove tmp files
tmp_files=(rmts_arg rmts_arg* fort.*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
cwd=$PWD
if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi

for var in "$@"
do
    echo $var >> rmts_arg
done
###reading input
read_input
###

#backup RXNet files
cp ${tsdirll}/KMC/RXNet ${tsdirll}/KMC/RXNet_backup
cp ${tsdirll}/KMC/RXNet.cg ${tsdirll}/KMC/RXNet.cg_backup
cp ${tsdirll}/KMC/RXNet_long.cg ${tsdirll}/KMC/RXNet_long.cg_backup
cp ${tsdirll}/KMC/RXNet_long.cg_groupedprods ${tsdirll}/KMC/RXNet_long.cg_groupedprods_backup
cp ${tsdirll}/KMC/RXNet.relevant ${tsdirll}/KMC/RXNet.relevant_backup
#remove $1 ts in rxnet files
awk '{if(NR==FNR){ts[NR]=$1;++nts}};{if(NR>FNR) {lp=0;for(i=1;i<=nts;i++) {if($2==ts[i]) lp=1}; if(lp==0) print $0}}' rmts_arg ${tsdirll}/KMC/RXNet_backup > ${tsdirll}/KMC/RXNet
awk '{if(NR==FNR){ts[NR]=$1;++nts}};{if(NR>FNR) {lp=0;for(i=1;i<=nts;i++) {if($2==ts[i]) lp=1}; if(lp==0) print $0}}' rmts_arg ${tsdirll}/KMC/RXNet.cg_backup > ${tsdirll}/KMC/RXNet.cg
awk '{if(NR==FNR){ts[NR]=$1;++nts}};{if(NR>FNR) {lp=0;for(i=1;i<=nts;i++) {if($2==ts[i]) lp=1}; if(lp==0) print $0}}' rmts_arg ${tsdirll}/KMC/RXNet_long.cg_backup > ${tsdirll}/KMC/RXNet_long.cg
awk '{if(NR==FNR){ts[NR]=$1;++nts}};{if(NR>FNR) {lp=0;for(i=1;i<=nts;i++) {if($2==ts[i]) lp=1}; if(lp==0) print $0}}' rmts_arg ${tsdirll}/KMC/RXNet_long.cg_groupedprods_backup > ${tsdirll}/KMC/RXNet_long.cg_groupedprods
awk '{if(NR==FNR){ts[NR]=$1;++nts}};{if(NR>FNR) {lp=0;for(i=1;i<=nts;i++) {if($2==ts[i]) lp=1}; if(lp==0) print $0}}' rmts_arg ${tsdirll}/KMC/RXNet.relevant_backup > ${tsdirll}/KMC/RXNet.relevant


#Re-do the kmc simulations and gather results in final directory
kmc.sh
final.sh

#remove tss from TSinfo
awk 'BEGIN{ch=1}
{if(NR==FNR){ts[NR]=$1;++nts}}
/Conformational/{ch=0}
{if(ch==0) print $0}
{if(NR>FNR && ch==1) {lp=0;for(i=1;i<=nts;i++) {if($1==ts[i]) lp=1}; if(lp==0) print $0}}{if(NR==FNR){ts[NR]=$1;++nts}}' rmts_arg FINAL_LL_${molecule}/TSinfo > FINAL_LL_${molecule}/TSinfo_backup 

cp FINAL_LL_${molecule}/TSinfo_backup FINAL_LL_${molecule}/TSinfo

#recover the original rxnet files
cp ${tsdirll}/KMC/RXNet_backup ${tsdirll}/KMC/RXNet
cp ${tsdirll}/KMC/RXNet.cg_backup ${tsdirll}/KMC/RXNet.cg
cp ${tsdirll}/KMC/RXNet_long.cg_backup ${tsdirll}/KMC/RXNet_long.cg
cp ${tsdirll}/KMC/RXNet_long.cg_groupedprods_backup ${tsdirll}/KMC/RXNet_long.cg_groupedprods
cp ${tsdirll}/KMC/RXNet.relevant_backup ${tsdirll}/KMC/RXNet.relevant
