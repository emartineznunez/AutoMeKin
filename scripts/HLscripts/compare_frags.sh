#!/bin/bash
#Input  geom name_frag working_dir
# name_frag= fragn_$nn  (sed --> frag n _ $nn )
sharedir=${AMK}/share
source utils.sh
#remove tmp files
tmp_files=(deg.out deg_form.out deg* ConnMat labels mingeom ScalMat sprint.out)
trap 'err_report $LINENO' ERR
trap cleanup2 EXIT INT

exe=$(basename $0)
inputfile=amk.dat
cwd=$PWD

##reading input
read_input
###

elements=${sharedir}/elements
natom=$(cat $1 | wc -l)
##Get the number and name of frag and put it in fraglist
number=$(echo $2 | sed 's/_/ _ /;s/frag/frag /' | awk '{print $2}')
name=$(echo $2 | sed 's/_/ _ /;s/frag/frag /' | awk '{print $4}')
working=$3

echo $natom > mingeom
echo ''>> mingeom
cat $1 >> mingeom
createMat.py mingeom 1

echo "1 $natom" | cat - ConnMat | sprint.exe >sprint.out

awk '{if( NR == FNR) {l[NR]=$1;n[NR]=NR/10+1;tne=NR}}
{if(FNR > 1 && NR >FNR ) {
   IGNORECASE = 1
   i=1
   while(i<=tne){
      if( $1 == l[i]) print n[i]
      i++
      }
  }
}' $elements mingeom > tmp_wrk
awk '/Natom/{natom=$2}
/Adjace/{i=1
while(i<=natom){
  getline
  print $0
  i++
  }
}' sprint.out >>tmp_wrk

paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
deg_form.sh > deg_form.out
format.sh $2 $working $thdiss
echo $2 "data" >>  $working/fraglist_screened
cat $working/${2}_data >> $working/fraglist_screened

if [ $natom -gt 1 ]; then
   awk '{if(NF==1) n[NR]=$1}
   {if(NF>1) {++i; for(j=1;j<=NF;j++) a[i,j]=$j;a[i,i]=n[i]} }
   END{
   print i
   for(ii=1;ii<=i;ii++) {
   for(j=1;j<=i;j++)
        printf("%2.1f ",a[ii,j])
        print ""
      }
   }' tmp_wrk | diag.exe >> $working/fraglist_screened
else
   echo "0.0" >> $working/fraglist_screened
fi

if [ $number -gt 1 ]; then
#Looking for conf. isomers of frag
   reduce3.sh $working frag 
   iso=$(awk '{nfnr[NR]=NF;for(i=1;i<=NF;i++) n[NR,i]=$i}
   END{j=1
   while(j<NR){
      err=0
      if(nfnr[NR]==nfnr[j] && n[NR,2]==n[j,2])
         for(i=3;i<=nfnr[NR];i++) err+=(n[NR,i]-n[j,i])^2
      else
         err=1
      if(err==0) {printf "1 %6.0f\n",n[j,1];exit}
      j++
      }
   print "0"
   }' $working/fraglist_screened.red )
   res=$(echo $iso | awk '{print $1}')
else 
   echo $number $name > $working/fraglist
   exit
fi
#remove the last entry in fraglist_screened if the frag is repeated and also write stuff in fraglist
if [ $res -eq 1 ]; then
   fra=$(niso=$(echo $iso | awk '{print $2}'); awk 'NR=='$niso'{print $2}' $working/fraglist)
   awk '{line[NR]=$0};/data/{ldata=NR}
   END{for(i=1;i<ldata;i++) print line[i]}' $working/fraglist_screened >tmp_fls
   mv tmp_fls $working/fraglist_screened
   echo $number $name $fra >> $working/fraglist
else
   echo $number $name >> $working/fraglist
fi


