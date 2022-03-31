#!/bin/bash
sharedir=${AMK}/share
source utils.sh
#remove tmp files
tmp_files=(tmp_next_layer.out tmp_plotdat1.out tmp_plotdat.out tmp_next_layer tmp_diagram_middle tmp_pr_ts tmp_ee tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
exe=$(basename $0)

inputfile=amk.dat
cwd=$PWD

#reading input
read_input
###

# ptgr is the percent of the total number of processes to be considered a relevant path
#
file=$tsdirhl/KMC/RXNet.relevant
#run simpliflyRXN.sh 
simplifyRXN.sh 1
if [ ! -f $file ]; then exit ; fi

smin=$(awk 'NR>2{print $8}' $file | sort -n | head -n1 )

if [ ! -f $file ]; then
   echo "File $tsdirhl/KMC/RXNet.relevant does not exist."
   exit
fi
eref=$(awk '{if($2=='$smin') print $4}' $tsdirhl/MINs/SORTED/MINlist_sorted)
rm -f tmp_plotdat.out
for i in $(awk '{if($1=="TS") print NR}' $file)
do
   echo "constructing data line" $i
   ts=$(awk 'NR=='$i',NR=='$i'{print $2}' $file)
   min1=$(awk 'NR=='$i',NR=='$i'{print $8}' $file)
   min2=$(awk 'NR=='$i',NR=='$i'{print $11}' $file)
   pro=$(awk 'BEGIN{p=0};NR=='$i',NR=='$i'{if($10=="PROD") p=1};END{print p}' $file)
   ets=$(awk '{if($2=='$ts') print $4-"'$eref'"}' $tsdirhl/TSs/SORTED/TSlist_sorted)
   emin1=$(awk '{if($2=='$min1') print $4-"'$eref'"}' $tsdirhl/MINs/SORTED/MINlist_sorted)
   if [ $pro -eq 1 ]; then
      code=$(awk '{if($2=='$ts') print $11}' $tsdirhl/KMC/RXNet)
      name=$(awk '{if($2=='$code') print $3}' $tsdirhl/PRODs/PRlist_kmc)
      namen=$(basename $name .rxyz)
      namesql="PR"$code"_"$namen
      namemsql="MIN"$smin
###
      calc1="$(sqlite3 $tsdirhl/PRODs/CALC/prodfhl.db "select energy,zpe from prodfhl where name='$namesql'" | sed 's@|@ @g')"
      calc2="$(sqlite3 $tsdirhl/MINs/SORTED/minshl.db "select energy,zpe from minshl where name='$namemsql'" | sed 's@|@ @g')"
      emin2=$(echo -e "$calc1"'\n'"$calc2" | awk '{e[NR]=$1;ezpe[NR]=$2};END{print (e[1]-e[2])*627.51+ezpe[1]-ezpe[2]}')
##   
      pr="$(awk '{if ($2=='$code') {for(i=4;i<NF;i++) printf $i " ";print $NF}}' ${tsdirhl}/PRODs/PRlist_frag | sed 's/.q0//g;s/.qm1/-/g;s/.qm/-/g;s/.q1/+/g;s/.q/+/g;s/.m/ .m/g' | awk '{for(i=1;i<=NF;i++) if ($i !~/.m/) printf " %s",$i;print ""}')" 
#      pr="$(sqlite3 $tsdirhl/PRODs/CALC/prodfhl.db "select formula from prodfhl where name='$namesql'")"
      printf "MIN %4s %10s TS %4s %10s PRO %25s %10s\n" $min1 $emin1 $ts $ets "$pr" $emin2 >> tmp_plotdat.out
   else
      emin2=$(awk '{if($2=='$min2') print $4-"'$eref'"}' $tsdirhl/MINs/SORTED/MINlist_sorted)
      printf "MIN %4s %10s TS %4s %10s MIN %4s %10s\n" $min1 $emin1 $ts $ets $min2 $emin2 >> tmp_plotdat.out
   fi
done

rm -f tmp_next_layer tmp_diagram_middle tmp_pr_ts
#sed 's/ + /+/g' tmp_plotdat.out >tmp_plotdat0.out
sed -i 's/ + /+/g' tmp_plotdat.out 
emin=$(awk 'BEGIN{min= 1e20};/MIN/{if($3<min) min=$3; if($NF<min) min=$NF};END{print min*1.1}' tmp_plotdat.out )
emax=$(awk 'BEGIN{max=-1e20};/MIN/{if($3>max) max=$3; if($NF>max) max=$NF; if($6>max) max=$6};END{print max*1.1}' tmp_plotdat.out )
echo $emax > tmp_ee
echo $emin >> tmp_ee
delta=$(awk '{e[NR]=$1};END{print 0.01*(e[1]-e[2])}' tmp_ee)

awk '/MIN/{if($2=='$smin') {
    ++cnt
    cnto2=cnt/2
    if(cnto2==(int(cnto2))) 
       p=1
    else
       p=-1
    if($7=="MIN") {++mm;pm[mm]=p;min[mm]=$8
    i=1
    while(i<=mm-1) {
      if($8==min[i]) p=pm[i] 
      i++
      }
    }
    print "set arrow from  ",p*2,",0 to ",p*6",",$6,"nohead lw 1"
    print "set arrow from  ",p*6",",$6" to ",p*10,",",$6,"nohead lw 1"
    print "set arrow from  ",p*10,",",$6,"to ",p*14,",",$NF,"nohead lw 1"
    if($7=="MIN") print "set arrow from  ",p*14",",$NF" to ",p*18,",",$NF,"nohead lw 1"
    if($7=="MIN") {
      print $8,p*18,$NF >> "tmp_next_layer"
     }
    if($7=="PRO") print "set arrow from  ",p*14",",$NF" to ",p*22,",",$NF,"nohead lw 1"
    print "set label \""$2"\" at -2,"'$delta'," font \"Arial-Bold,12\" "
    if(p==1)  print "set label \""$5"\" at",p*6","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
    if(p==-1) print "set label \""$5"\" at",p*10","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
    print $5 > "tmp_pr_ts"
    if(p==1  && $7=="MIN" ) print "set label \""$8"\" at",p*14","$NF+'$delta'," font \"Arial-Bold,12\" "
    if(p==-1 && $7=="MIN" ) print "set label \""$8"\" at",p*18","$NF+'$delta'," font \"Arial-Bold,12\" "
    if(p==1  && $7=="PRO" ) print "set label \""$8"\" at",p*14","$NF+'$delta'," font \"Arial-Bold,12\" "
    if(p==-1 && $7=="PRO" ) print "set label \""$8"\" at",p*22","$NF+'$delta'," font \"Arial-Bold,12\" "
    }

}' tmp_plotdat.out >> tmp_diagram_middle
#
cat tmp_pr_ts tmp_plotdat.out > tmp_plotdat1.out
#
# loop over the minima
for ibl in $(seq 1 100)
do
   if [ -f tmp_next_layer ]; then
      echo "Iteration" $ibl
   else
      echo "end"
      break
   fi
#reducing tmp_next_layer
   awk '{n[NR]=$1;tot[NR]=$0
   }
   END{
   i=1
   while(i<=NR){
     j=1
     skip=0
     while(j<=i-1){
       if(n[j]==n[i]) skip=1
       j++
       }
     if(skip==0) print tot[i]
     i++
     }
   }' tmp_next_layer >tmp_next_layer.out

   rm -f tmp_next_layer
   for i in $(awk '{print NR}' tmp_next_layer.out)
   do
     min=$(awk 'NR=='$i',NR=='$i'{print $1}' tmp_next_layer.out) 
     spox=$(awk 'NR=='$i',NR=='$i'{print $2}' tmp_next_layer.out) 
     spoy=$(awk 'NR=='$i',NR=='$i'{print $3}' tmp_next_layer.out) 
   ###
     p=$(awk 'NR=='$i',NR=='$i'{print $2/sqrt($2*$2)}' tmp_next_layer.out) 
     awk '{if(NF==1) {++i;ts[i]=$1};nts=i}
         /MIN/{ok=1
         for(i=1;i<=nts;i++) {if($5==ts[i]) ok=0}
         if(ok==1 && $2=='$min') {
         p='$p'
         print "set arrow from  ",'$spox',",",'$spoy'," to ",'$spox'+4*p,",",$6,"nohead lw 1"
         print "set arrow from  ",'$spox'+4*p,",",$6" to ",'$spox'+8*p,",",$6,"nohead lw 1"
         print "set arrow from  ",'$spox'+8*p,",",$6,"to ",'$spox'+12*p,",",$NF,"nohead lw 1"
         if($7=="MIN") print $8,'$spox'+16*p,$NF >> "tmp_next_layer"
         if($7=="MIN") print "set arrow from  ",'$spox'+12*p,",",$NF" to ",'$spox'+16*p,",",$NF,"nohead lw 1"
         if($7=="PRO") print "set arrow from  ",'$spox'+12*p,",",$NF" to ",'$spox'+20*p,",",$NF,"nohead lw 1"
         if(p==1)  print "set label \""$5"\" at",'$spox'+4*p,","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
         if(p==-1) print "set label \""$5"\" at",'$spox'+8*p,","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
         print $5 >> "tmp_pr_ts"
         if(p==1  && $7=="MIN" ) print "set label \""$8"\" at",'$spox'+12*p,","$NF+'$delta'," font \"Arial-Bold,12\" "
         if(p==-1 && $7=="MIN" ) print "set label \""$8"\" at",'$spox'+16*p,","$NF+'$delta'," font \"Arial-Bold,12\" "
         if(p==1  && $7=="PRO" ) print "set label \""$8"\" at",'$spox'+12*p,","$NF+'$delta'," font \"Arial-Bold,12\" "
         if(p==-1 && $7=="PRO" ) print "set label \""$8"\" at",'$spox'+20*p,","$NF+'$delta'," font \"Arial-Bold,12\" "
         }

         if(ok==1 && $8=='$min') {
         p='$p'
         print "set arrow from  ",'$spox',",",'$spoy'," to ",'$spox'+4*p,",",$6,"nohead lw 1"
         print "set arrow from  ",'$spox'+4*p,",",$6" to ",'$spox'+8*p,",",$6,"nohead lw 1"
         print "set arrow from  ",'$spox'+8*p,",",$6,"to ",'$spox'+12*p,",",$3,"nohead lw 1"
         if($1=="MIN") print $2,'$spox'+16*p,$3 >> "tmp_next_layer"
         if($1=="MIN") print "set arrow from  ",'$spox'+12*p,",",$3" to ",'$spox'+16*p,",",$3,"nohead lw 1"
         if(p==1)  print "set label \""$5"\" at",'$spox'+4*p,","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
         if(p==-1) print "set label \""$5"\" at",'$spox'+8*p,","$6+'$delta'," font \"Arial-Bold,12\" textcolor rgbcolor \"red\""
         print $5 >> "tmp_pr_ts"
         if(p==1  && $1=="MIN" ) print "set label \""$2"\" at",'$spox'+12*p,","$3+'$delta'," font \"Arial-Bold,12\" "
         if(p==-1 && $1=="MIN" ) print "set label \""$2"\" at",'$spox'+16*p,","$3+'$delta'," font \"Arial-Bold,12\" "
         }

     }' tmp_plotdat1.out >> tmp_diagram_middle
     cat tmp_pr_ts tmp_plotdat.out > tmp_plotdat1.out
###

   done

done

xmin=$(awk '/at/{print $5}' tmp_diagram_middle | sed 's/,/ /g' | awk '{print $1}' | awk 'BEGIN{max=-1e20;min=1d20}
{if($1<min) min=$1; if($1>max) max=$1}
END{print 1.05*min}')
xmax=$(awk '/at/{print $5}' tmp_diagram_middle | sed 's/,/ /g' | awk '{print $1}' | awk 'BEGIN{max=-1e20;min=1d20}
{if($1<min) min=$1;if($1>max) max=$1}
END{print 1.05*(max+8)}')


sed 's/ymin/'$emin'/g' $sharedir/diagram_template0 | sed 's/ymax/'$emax'/g' | sed 's/xmin/'$xmin'/g' | sed 's/xmax/'$xmax'/g' | sed 's/titulo/High-level profile/g' > diagram.gnu

cat tmp_diagram_middle $sharedir/diagram_template1 >>diagram.gnu
##
##
rm -rf tmp*
