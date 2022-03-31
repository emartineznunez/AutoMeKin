#!/bin/bash

source utils.sh
#On exit remove tmp files
tmp_files=(tmp_cpp0 tmp_cppkin tmp_cppi tmp* fort.*)
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
final=FINAL_${tag}_${molecule}
rxnet=${final}/RXNet.cg
if [ $rate -eq 0 ]; then
     kmcfile=${tsdir}/KMC/kmcT${temperature}.out
fi
if [ $rate -eq 1 ]; then
     kmcfile=${tsdir}/KMC/kmcE${energy}.out
fi


if [ ! -f $rxnet ];then
   echo $rxnet has not been created
   exit 0
else
#all
   awk 'NR>1{if($NF!="DISCONN") print $0}' $rxnet |  awk '{if($3=="MIN" && $6=="MIN" ) print $1,$4,$7}
   {if($6=="PROD") {++pn;p[pn]=$7;m[pn]=$4;ts[pn]=$1} }
   {if($1=="PROD") {++pn2;p2[pn2]=$2;pc[pn2]=$3$4$5$6$7$8$9} }
   END{for(i=1;i<=pn;i++){
     for(j=1;j<=pn2;j++) {if(p[i]==p2[j]) print ts[i],m[i],pc[j]}
     }
   }'  > tmp_cpp0

   awk '{s1[NR]=$2;s2[NR]=$3;w[NR]=1}
   END{k=0
   for(i=1;i<=NR;i++) {
     if(w[i]>0) {k=k+1;wf[k]=w[i];s1f[k]=s1[i];s2f[k]=s2[i]}
     for(j=i+1;j<=NR;j++){
       if( s1[i]==s1[j] && s2[i]==s2[j]) {
             wf[k]+=w[j]
             w[j]=0
             ni=0}
       if( s1[i]==s2[j] && s2[i]==s1[j]) {
             wf[k]+=+w[j]
             w[j]=0
             ni=0}
            }
       }
   for(i=1;i<=k;i++) print s1f[i],s2f[i],wf[i]} ' tmp_cpp0 >${final}/rxn_all.txt
fi

#kinetics
if [ ! -f $kmcfile ];then
   echo $kmcfile has not been created
   exit 0
else
   awk '/counts per process/{p=1};{if(p==1 && NF==2) print $2}' $kmcfile > tmp_cppkin
   paste $tsdir/KMC/processinformation tmp_cppkin  | awk '{if($NF>0) print $0}' | awk '{nts[NR]=$4;m1[NR]=$5;m2[NR]=$6;nn[NR]=$7};END{nts[NR+1]=0;nts[0]=0;for(i=1;i<=NR;i++) { {if(nts[i]!=nts[i+1] && nts[i]!=nts[i-1] ) print nts[i],nn[i]};{if(nts[i]==nts[i+1]) print nts[i],nn[i]+nn[i+1]}} }'  > tmp_cppi 
   
   cat tmp_cppi tmp_cpp0 | awk '{ 
   if(NF==2)
      { 
      ++rel
      nts[rel]=$1
      nn[rel]=$2 
      sum+=$2}
   else
      for(i=1;i<=rel;i++) {if($1==nts[i]) print $2,$3,nn[i]/sum}
   }'   |  awk '{s1[NR]=$1;s2[NR]=$2;w[NR]=$3}
   END{k=0
   for(i=1;i<=NR;i++) {
     if(w[i]>0) {k=k+1;wf[k]=w[i];s1f[k]=s1[i];s2f[k]=s2[i]}
     for(j=i+1;j<=NR;j++){
       if( s1[i]==s1[j] && s2[i]==s2[j]) {
             wf[k]+=w[j]
             w[j]=0
             ni=0}
       if( s1[i]==s2[j] && s2[i]==s1[j]) {
             wf[k]+=+w[j]
             w[j]=0
             ni=0}
            }
       }
   for(i=1;i<=k;i++) print s1f[i],s2f[i],wf[i]} '  >${final}/rxn_kin.txt
fi
