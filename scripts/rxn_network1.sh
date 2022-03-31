#!/bin/bash
sharedir=${AMK}/share
source utils.sh
#remove tmp files
tmp_files=(fort.* deg.out deg_form.out deg* ConnMat mingeom ScalMat sprint.out sprint.* symm.dat tmp_ci tmp_nisol tmp_inp tmp_symm tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
inputfile=amk.dat
cwd=$PWD
# ci is a flag to determine the conformational isomers (if ci==1 calculate them).
# ci=0 do not re-calculate conformational isomers. You can edit them in workdir/conf_isomer.out
# ci=2 "echo -n >workdir/conf_isomer.out". All isomers are considered in the kinetics
ci=$1

##reading input file
read_input
###
elements=${sharedir}/elements

#create the neccesary folders
#if [ $ci -ne 0 ]; then
#   rm -rf $working && mkdir $working
#fi
if [ ! -d $working ]; then mkdir $working ; fi
rm -rf ${tsdirll}/KMC && mkdir ${tsdirll}/KMC
#create data.db if not exits
sqlite3 ${working}/data.db "create table if not exists data (id INTEGER PRIMARY KEY,name TEXT,datas TEXT,diags TEXT,unique(name));"
#

if [ $ci -eq 2 ]; then
   echo "$workdir/conf_isomer.out will be emptied. All conf isomers are considered different states in KMC calc."
   echo -n > $working/conf_isomer.out 
   echo -n > $working/conf_isomer_ts.out 
elif [ $ci -eq 1 ]; then
   echo "Screening" > $working/MINlist_screened
# First of all, we gather conformational isomers (those with the same Adjacency matrix)
   for name in $(sqlite3 ${tsdirll}/MINs/SORTED/mins.db "select lname from mins")
   do 
      echo $name
      named=$(echo $name | sed 's/_min/ min/' | awk '{print $2}')
      #Create _diag and _data files for $name if they do not exist 
      if [ -z $(sqlite3 ${working}/data.db "select id from data where name='$named'") ]; then
         sqlite3 ${tsdirll}/MINs/SORTED/mins.db "select natom,geom from mins where lname='$name'" | sed 's@|@\n\n@g'  >mingeom
         createMat.py mingeom 1 $nA
         echo "1 $natom" | cat - ConnMat | sprint.exe >sprint.out
         paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
         deg_form.sh > deg_form.out
         format.sh $named $working $thdiss
         awk '{if( NR == FNR) {l[NR]=$1;n[NR]=NR/10+1;tne=NR}}
         {if(FNR > 1 && NR >FNR ) {
            IGNORECASE = 1
            for(i=1;i<=tne;i++) {if( $1 == l[i]) print n[i]}
           }
         }' $elements mingeom > ${working}/${named}_diag
         awk '/Natom/{natom=$2};/Adjace/{for(i=1;i<=natom;i++){getline;print $0}}' sprint.out >> ${working}/${named}_diag
         datas="$(cat ${working}/${named}_data)"
         diags="$(cat ${working}/${named}_diag)"
         sqlite3 ${working}/data.db "insert into data (name,datas,diags) values ('$named','$datas','$diags');"
     else
         sqlite3 ${working}/data.db "select datas from data where name='$named'" > ${working}/${named}_data
         sqlite3 ${working}/data.db "select diags from data where name='$named'" > ${working}/${named}_diag
     fi
#ccccc

      echo $name "data" >>  ${working}/MINlist_screened
      cat ${working}/${named}_data >> ${working}/MINlist_screened

      awk '{if(NF==1) n[NR]=$1}
      {if(NF>1) {++i; for(j=1;j<=NF;j++) a[i,j]=$j;a[i,i]=n[i]} }
      END{
      print i
      for(ii=1;ii<=i;ii++) {
         for(j=1;j<=i;j++) 
           printf("%2.1f ",a[ii,j])
           print "" 
         }
      }' ${working}/${named}_diag | diag.exe >> ${working}/MINlist_screened
      rm -rf ${working}/${named}_data ${working}/${named}_diag
   done
#Looking for conf. isomers
   reduce2.sh $working MIN 

   sed 's@-0.000@0.000@g' ${working}/MINlist_screened.red | awk '{$1="";tag[NR]=$0}
   END{
   for(i=1;i<=NR;i++) {
      for(j=1;j<i;j++) {
      if(tag[i]==tag[j]) {print j,i;break}} }
   }'  > ${working}/conf_isomer 
 
   awk '{niso[int($1)]++;iso[int($1),niso[int($1)]]=int($2)}
   END{for (ele in niso) {
       printf "%s ",ele;for(i=1;i<=niso[ele];i++) printf "%s ",iso[ele,i]; print ""}
   }' ${working}/conf_isomer > ${working}/conf_isomer.out 
##Keep only isomers within 20 kcal/mol 
   awk 'NR==FNR{e[$2]=$NF}
   NR>FNR{nb=0
   for(i=1;i<=NF;i++) {
   if( (e[$i]-e[$1])<20 )
      printf "%s ",$i
   else {++nb
      if(nb==1) {print "";ref=$i}
      if ( (e[$i]-e[ref])<20 ) printf "%s ",$i }
   }
   print ""}' ${tsdirll}/MINs/SORTED/MINlist_sorted ${working}/conf_isomer.out | awk 'NF>1{print $0}'  > tmp_ci && mv tmp_ci ${working}/conf_isomer.out 
##
   cp ${working}/conf_isomer.out ${working}/conf_isomer_old.out
   
#sort conf_isomer.out file
   output="$(sort -k 1n ${working}/conf_isomer.out)"
   echo "$output" > ${working}/conf_isomer.out
else
   echo "conf_isomers will not be re-calculated again"
fi

# Now, the KMC stuff
echo "KMC file" > $tsdirll/KMC/RXNet
nmnr="$(cat $tsdirll/MINs/names_of_minima_norep)"
endf="$(echo "End of nomenclature")"
mlsl="$(cat $tsdirll/MINs/minlist_screened.lowdiffs)"
dum="$nmnr
$endf
$mlsl"

dumout="$(echo "$dum" | awk '/min/{++i;min[i]=$2}
/End of nomenclature/{flag=1;getline}
{if(flag==1) {
    j=0
    found=0
    while(j<=i){
     if(min[j]==$1) {++rmin[min[j]];lmin[min[j],rmin[min[j]]]=$2;found=1;++ntr;fl[ntr]=$2;rep[$2]=$1}
     j++
     }
# count also those that are reps of reps
     if(found==0) {
       j=0
       ok=0
       while(j<=ntr){
         if($2==fl[ntr]) ok=1
         j++
         }
         if(ok==0) {++rmin[rep[$1]]
             lmin[rep[$1],rmin[rep[$1]]]=$2
             ++ntr
             fl[ntr]=$2}
     }
   }
}
END{j=1
while(j<=i){
  if(rmin[min[j]]>0) print "min",min[j],"rep=",rmin[min[j]]
    for(k=1;k<=rmin[min[j]]; k++)
       print "min",lmin[min[j],k]
  j++
  }
}')"

nmn="$(cat $tsdirll/MINs/names_of_minima)"
dum="$nmn
$endf
$dumout"

dumlog="$(echo "$dum" | awk '/min/{
if(flag==0) {i=$2;name[i]=$4}
}
/End of nomenclature/{flag=1}
/min/{if(flag==1 && NF==4) print name[$2],$3,$4}
/min/{if(flag==1 && NF==2) print name[$2]
}')"

eor="$(echo "End of reps")"
mlsl="$(cat $tsdirll/MINs/SORTED/MINlist_sorted.log)"
dumm="$dumlog
$eor
$mlsl"

echo "$dumm" | awk '/rep=/{++r;i=1;ss[r,i]=$1;rep[$1]=$3;nn[$1]=r}
{if(NF==1)  {++i;ss[r,i]=$1}
}
/MIN/{print $1,$2,"E=",$4," rep=",rep[$3]+1
if(rep[$3]==0)
  print $3 
else 
  for(j=1;j<=rep[$3]+1; j++) print ss[nn[$3],j]
}' > $tsdirll/MINs/SORTED/MINlist_sorted_withreps.log


for i in $(awk '{print $2}' $tsdirll/TSs/SORTED/TSlist_sorted)
do
  ts=$(awk 'NR=='$i',NR=='$i'{print $3}' $tsdirll/TSs/SORTED/TSlist_sorted)
  en=$(awk 'NR=='$i',NR=='$i'{print $4}' $tsdirll/TSs/SORTED/TSlist_sorted)
####################
  int_min_rxn="$(awk '/MIN/{min=$2};/'$ts'/{
  ++i
  mname[i]=$0
  m[i]=min}
  END{n=i
  if(n>=1)print mname[1],m[1]
  i=2
  while(i<=n){
     lp=1
     for(j=1;j<i;j++) {if(mname[j]==mname[i]) lp=0 }
     if(lp==1) print mname[i],m[i]
     i++
     }
  }' $tsdirll/MINs/SORTED/MINlist_sorted_withreps.log)"
####################
  min1="$(echo "$int_min_rxn" | awk '{++i; minn[i]=$2};END{if(i>0) print "MIN",minn[1];if(i==0) print "0"}')" 
  min2="$(echo "$int_min_rxn" | awk '{++i; minn[i]=$2};END{if(i==2) print "MIN",minn[2];if(i<2) print "0"}')" 
  nmin1="$(echo "$int_min_rxn" | awk '{++i; minn[i]=$2};END{if(i>0) print minn[1];if(i==0) print "0"}')" 
  nmin2="$(echo "$int_min_rxn" | awk '{++i; minn[i]=$2};END{if(i==2) print minn[2];if(i<2) print "0"}')" 
  if [[ ("$nmin1" -gt -0) && ("$nmin2" -eq -0) ]]; then  
    min2=$(awk '/PROD/{prod=$2}
    /'$ts'/{prnn=prod;++i};END{if(i>0) print "PROD",prnn;if(i==0) print "failed"}' $tsdirll/PRODs/PRlist)
  fi
  if [[ ("$nmin1" -eq -0) && ("$nmin2" -eq -0) ]]; then  
    min1=$(awk '/PROD/{prod=$2}
    /'$ts'/{++i;prnn[i]=prod};END{if(i>0) print "PROD",prnn[1];if(i==0) print "failed"}' $tsdirll/PRODs/PRlist)
    min2=$(awk '/PROD/{prod=$2}
    /'$ts'/{++i;prnn[i]=prod};END{if(i==2) print "PROD",prnn[2];if(i<2) print "failed"}' $tsdirll/PRODs/PRlist)
  fi
  echo "TS "$i $ts "DE= "$en "Path:" $min1 "<--> " $min2 >>$tsdirll/KMC/RXNet
done

output="$(awk '{if(NR==1) print $0; if(NR>1) printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}' $tsdirll/KMC/RXNet)"
echo "$output" > $tsdirll/KMC/RXNet

if [ $mdc -ge 1 ]; then
#the products with the same formula as min0 are converted to min0
   f0="$(sqlite3 ${tsdirll}/MINs/min.db "select natom,geom from min where name='min0_0'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
   minn=$(awk '/min0/{print $2}' ${tsdirll}/MINs/SORTED/MINlist_sorted)
   for i in $(sqlite3 ${tsdirll}/PRODs/prod.db "select id from prod")
   do
      f="$(sqlite3 ${tsdirll}/PRODs/prod.db "select natom,geom from prod where id='$i'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
      if [[ "$f" == "$f0" ]]; then
         sed -i 's/PROD   '$i'/ MIN   '$minn'/' ${tsdirll}/KMC/RXNet
      fi
   done
fi

# Edit RXNet to remove PROD<-->PROD channels and coarse-grain it by removing fast equilibium (between conf isomers)
ciout="$(cat $working/conf_isomer.out)"
rxnet="$(cat $tsdirll/KMC/RXNet)"
dum1="$ciout
$rxnet"

dumout="$(echo "$dum1" | awk 'BEGIN{one="  1"}
{
if(fl==0 && $1!~"KMC") {
   ++jwiso
   niso[jwiso]=NF
   for(i=1;i<=NF;++i) {n[jwiso,i]=$i;niso2[$i]=NF}
   }
}
/KMC file/{print $0;fl=1}
{
if(NF>2 && fl==1) {
 lpp=1
 lp1=0
 lp2=0
 d1=one
 d2=one
 if($7~"MIN"  && niso2[$8]>0)  d1=niso2[$8]
 if($10~"MIN" && niso2[$11]>0) d2=niso2[$11]
 for(i=1;i<=jwiso;++i) {
   for(j=2;j<=niso[i];++j) {
       if($7 ~"MIN" && $10~"MIN" && $8==n[i,1] && $11==n[i,j] ) {lpp=0}
       if($7 ~"MIN" &&  $8==n[i,j]) {lp1=1;min1=n[i,1]}
       if($10~"MIN" && $11==n[i,j]) {lp2=1;min2=n[i,1]}
     }
   }
 if(lpp==1) {
 if(lp1==0 && lp2==0 && $10~"MIN")    printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,d1,d2
 if(lp1==1 && lp2==0 && $10~"MIN")    printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,$11,d1,d2
 if(lp1==0 && lp2==1 && $10~"MIN")    printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,min2,d1,d2
 if(lp1==1 && lp2==1 && $10~"MIN")    printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,min2,d1,d2

 if(lp1==0 && lp2==0 && $10~"PROD")   printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,d1
 if(lp1==0 && lp2==0 && $10~"failed") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s%10.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,d1
 if(lp1==1 && lp2==0 && $10~"PROD")   printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,$11,d1
 if(lp1==1 && lp2==0 && $10~"failed") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s%10.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,d1
 if(lp1==0 && lp2==1 && $10~"PROD")   printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,d1
 if(lp1==0 && lp2==1 && $10~"failed") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s%10.0f\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,d1
 if(lp1==1 && lp2==1 && $10~"PROD")   printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s %3.0f %5.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,$11,d1
 if(lp1==1 && lp2==1 && $10~"failed") printf "%2s %4.0f %20s %3s %8.3f %5s %4s %3.0f %4s %6s%10.0f\n",$1,$2,$3,$4,$5,$6,$7,min1,$9,$10,d1
   }
 }
}')"

echo "$dumout" | awk '{
if(NR==1) {
 print $0
 print " number         TS file name                                             NisoR NisoP"
 } 
else { 
 ok=1
 if($7=="PROD") ok=0
 if($7=="failed") ok=0
 if($10=="failed") ok=0
 if($7~"MIN" && $10~"MIN" && $8 == $11) ok=0
 if(ok==1) print $0 }
}' >$tsdirll/KMC/RXNet.cg


echo "Number of optimical isomers list" >tmp_nisol
echo " niso_1 nisots niso_2" >> tmp_nisol
for ts in $(awk '{if(NR>2) print $2}' $tsdirll/KMC/RXNet.cg)
do
 nmin1=$(awk 'NR>2{if($2=='$ts') print $8}' $tsdirll/KMC/RXNet.cg)
 nmin2=$(awk 'NR>2{if($2=='$ts'){
  if($10=="MIN")
    print $11
  else
    print "0"}
 }' $tsdirll/KMC/RXNet.cg)
 lnmin1="MIN"$nmin1
 lnmin2="MIN"$nmin2
 lts="TS"$ts
 sqlite3 $tsdirll/TSs/SORTED/tss.db "select natom,geom from tss where name='$lts'" | sed 's@|@\n@g' >tmp_inp
 symm.sh tmp_inp
 nisots=$(awk '/C1/{print "2"};/CS/{print "1"}' tmp_symm)
 sqlite3 $tsdirll/MINs/SORTED/mins.db "select natom,geom from mins where name='$lnmin1'" | sed 's@|@\n@g' >tmp_inp
 symm.sh tmp_inp
 nisomin1=$(awk '/C1/{print "2"};/CS/{print "1"}' tmp_symm)
 if [ $nmin2 -gt 0 ]; then
   sqlite3 $tsdirll/MINs/SORTED/mins.db "select natom,geom from mins where name='$lnmin2'" | sed 's@|@\n@g' >tmp_inp
   symm.sh tmp_inp
   nisomin2=$(awk '/C1/{print "2"};/CS/{print "1"}' tmp_symm)
   printf "%6.0f %6.0f %6.0f\n" $nisomin1   $nisots   $nisomin2 >>tmp_nisol
 else
   printf "        %6.0f %6.0f\n" $nisomin1   $nisots  >>tmp_nisol
 fi
done
paste $tsdirll/KMC/RXNet.cg tmp_nisol > $tsdirll/KMC/RXNet_long.cg

# Conformational isomers of the TS
echo "Conformational isomers of the TS structures"
if [ $ci -eq 1 ]; then
   conf_isomer_ts.sh 0
fi
