#!/bin/bash
sharedir=${AMK}/share

source utils.sh
#On exit remove tmp files
tmp_files=(tmp_rel tmp_pop_data tmp_cols tmp_kmc0 tmp_kmc tmp_conn_proc tmp_RXNet tmp_RXNet.cg tmp_rxn tmp_ep tmp_geom tmp_pf tmp_pf_add tmp_rxn_barrless tmp_en tmp* RXNet0 RXNetcg0) 
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)

if [ -f amk.dat ];then
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
###Make rxyz of the prods
echo "Making rxyz of the PRODs"
makerxyz.sh
###

cwd=$PWD
###reading input file
read_input
###
if [ $rate -eq 0 ]; then
   postb="T$temperature"
   units="s"
elif [ $rate -eq 1 ]; then
   postb="E$energy"
   units="ps"
fi
##

final=FINAL_HL_${molecule}
####
rm -rf $final 
mkdir $final 
mdir=${final}/normal_modes
mkdir $mdir

##copy possible problem with fragments
if [ -f frag_warnings ]; then mv frag_warnings $final ; fi
##copy the products
rm -rf tmp_pf_add
cp ${tsdirhl}/PRODs/CALC/prodfhl.db $final
sqlite3 ${final}/prodfhl.db "alter table prodfhl rename to prod"
mv ${final}/prodfhl.db ${final}/prod.db
##put the right energy in RXN_barrless
if [ -f ${tsdirhl}/KMC/RXN_barrless0 ]; then
   for n in $(awk '{print NR}' ${tsdirhl}/KMC/RXN_barrless0)
   do
      if [ $n -eq 1 ]; then
         awk 'NR=='$n'{print $0}' ${tsdirhl}/KMC/RXN_barrless0 > ${tsdirhl}/KMC/RXN_barrless1 
      else
         id=$(awk 'NR=='$n'{print $NF}' ${tsdirhl}/KMC/RXN_barrless0)
         if [ $rate -eq 1 ]; then
            sqlite3 ${tsdirhl}/MINs/minhl.db "select energy,zpe from minhl where name='min0'" | sed 's@|@ @g' > tmp_en
            sqlite3 ${tsdirhl}/PRODs/CALC/prodfhl.db "select energy,zpe from prodfhl where id='$id'" | sed 's@|@ @g' >> tmp_en
            epro="$(awk '{e[NR]=$1;ezpe[NR]=$2};END{printf "%10.4f\n",(e[2]-e[1])*627.51+ezpe[2]-ezpe[1]}' tmp_en)"
         elif [ $rate -eq 0 ]; then
            sqlite3 ${tsdirhl}/MINs/minhl.db "select energy,g from minhl where name='min0'" | sed 's@|@ @g' > tmp_en
            sqlite3 ${tsdirhl}/PRODs/CALC/prodfhl.db "select energy,g from prodfhl where id='$id'" | sed 's@|@ @g' >> tmp_en
            epro="$(awk '{e[NR]=$1;ezpe[NR]=$2};END{printf "%10.4f\n",(e[2]-e[1]+ezpe[2]-ezpe[1])*627.51}' tmp_en)"
         fi
         awk 'NR=='$n'{$2='"$epro"'; print}' ${tsdirhl}/KMC/RXN_barrless0 >> ${tsdirhl}/KMC/RXN_barrless1
      fi
   done
fi
##put the right energy in RXN_barrless
rm -rf ${tsdirhl}/PRODs/PRlist_tags.log
sqlite3 ${final}/prod.db "select energy,formula from prod" | awk '{for (i=1;i<=NF;i++) printf "%s",$i;printf "\n"}' | sed 's@|@ @g' >tmp_pf
###
np=$(wc -l tmp_pf | awk '{print $1}')
if [ $np -gt 1 ]; then
   ##prods within 0.01 kcal/mol are considered the same
   echo "Grouping together products within 0.01 kcal/mol"
   for i in $(awk '{print NR}' tmp_pf)
   do
     echo Screening prod $i
     sqlite3 ${final}/prod.db "select natom,geom from prod where id='$i'" | sed 's@|@\n\n@g'  > tmp_geom
     tag_prod.py tmp_geom | sed 's@-0.000@0.000@g'  >> tmp_pf_add
   done
   paste tmp_pf tmp_pf_add >> ${tsdirhl}/PRODs/PRlist_tags.log
   awk '{for(i=1;i<=NF;i++) tag[NR,i]=$i}
   END{for(i=1;i<=NR;i++){np[i,0]=i
      for(j=i+1;j<=NR;j++){
        diff=sqrt((tag[i,1]-tag[j,1])^2)*627.51
        if(tag[i,1]==0 && tag[j,1]==0) diff=10
        err_tag=0; for(k=3;k<=NF;k++) err_tag+=(tag[i,k]-tag[j,k])^2
        if(diff<0.01 && tag[i,2]==tag[j,2] && err_tag==0) {n[i]+=1;np[i,n[i]]=j;p[j]=1} }
      if(p[i]!=1 && n[i]>=1) {for(k=0;k<n[i];k++) printf np[i,k] " ";print np[i,n[i]]} }
   }' ${tsdirhl}/PRODs/PRlist_tags.log > tmp_ep
fi
##Make sure there is an empty line
echo "" >> tmp_ep
##remove the same products
for i in $(awk '{for (i=2; i<=NF; i++) print $i}' tmp_ep)
do
   sqlite3 $final/prod.db "delete from prod where id=$i"
done
##correct barrless if exists
if [ -f ${tsdirhl}/KMC/RXN_barrless1 ]; then
   cat tmp_ep ${tsdirhl}/KMC/RXN_barrless1 > tmp_rxn
   awk 'BEGIN{lp=0;rep=0;for(i=1;i<=10e6;i++)p[i]=i}
   {if($1=="TS") lp=1}
   {
   if (lp==0) {
      for(i=2;i<=NF;i++) p[$i]=$1 }
   else {
      if($(NF-1)=="PROD") $NF=p[$NF];print }
   }' tmp_rxn > ${tsdirhl}/KMC/RXN_barrless2
   npr=0

#EMN hack
   awk 'NR>1{for(i=1;i<NF;i++) if(i!=3) printf $i " ";print $NF}' ${tsdirhl}/PRODs/PRlist_frag | sed 's/.q0//g;s/.qm1/-/g;s/.qm/-/g;s/.q1/+/g;s/.q/+/g;s/.m/ .m/g' | awk '{for(i=1;i<=NF;i++) if ($i !~/.m/) printf " %s",$i;print ""}' >> ${tsdirhl}/KMC/RXN_barrless2

#   for pr in $(awk '{print $2}' ${tsdirhl}/PRODs/PRlist_tags.log)
#   do
#      npr=$((npr+1))
#      form="$(echo $pr | sed 's@+@ + @g')"
#      echo "PROD $npr "$form"" >> ${tsdirhl}/KMC/RXN_barrless
#   done
#EMN hack
fi
##
cat tmp_ep > tmp_RXNet
cat tmp_ep > tmp_RXNet.cg
##Making final RXNet and RXNet.cg files
awk 'BEGIN{if('$rate'==0) fl="DG"; if('$rate'==1) fl="DE"}
NR==1{printf " TS #    %2s(kcal/mol)    -------Path info--------\n",fl}
NR>1{printf "%5.0f %12.3f       %4s %4s %4s %4s %4s\n",$2,$5,$7,$8,$9,$10,$11}' ${tsdirhl}/KMC/RXNet >> tmp_RXNet
if [ -f ${tsdirhl}/PRODs/PRlist_frag ]; then
   awk 'NR>1{for(i=1;i<NF;i++) if(i!=3) printf $i " ";print $NF}' ${tsdirhl}/PRODs/PRlist_frag | sed 's/.q0//g;s/.qm1/-/g;s/.qm/-/g;s/.q1/+/g;s/.q/+/g;s/.m/ .m/g' | awk '{for(i=1;i<=NF;i++) if ($i !~/.m/) printf " %s",$i;print ""}' >> tmp_RXNet
fi

awk 'BEGIN{np=0;fl=0}
{
if(fl==0) {
   ++jwiso
   niso[jwiso]=NF
   for(i=1;i<=NF;++i) {n[jwiso,i]=$i;niso2[$i]=NF}
   }
}
{if(NF==0) fl=1}
{
if(NF>1 && fl==1) {lp=0;lp1=0;lp2=0
 if($1 !="PROD" ) {lp=1}
 for(i=1;i<=jwiso;++i) {
   for(j=2;j<=niso[i];++j) {
       if($3 =="PROD" &&  $4==n[i,j]) {lp1=1;pr1=n[i,1];++np;pr[np]=pr1}
       if($6 =="PROD" &&  $7==n[i,j]) {lp2=1;pr2=n[i,1];++np;pr[np]=pr2}
       if($1 =="PROD" &&  $2==n[i,j]) {lp=1}
     }
   }
 if($3 =="PROD" && lp1==0) {++np;pr[np]=$4}
 if($6 =="PROD" && lp2==0) {++np;pr[np]=$7}
 if($1=="TS") print $0
 if($1!="PROD" && $1!="TS" && lp1==0 && lp2==0) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,$4,$5,$6,$7
 if($1!="PROD" && $1!="TS" && lp1==1 && lp2==0) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,pr1,$5,$6,$7
 if($1!="PROD" && $1!="TS" && lp1==0 && lp2==1) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,$4,$5,$6,pr2
 if($1!="PROD" && $1!="TS" && lp1==1 && lp2==1) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,pr1,$5,$6,pr2
 if(lp==0) {lpp=0
    for(i=1;i<=np;i++) {if($2==pr[i]) lpp=1}
    if(lpp==1) print $0}
 }
} ' tmp_RXNet  > RXNet0
cp RXNet0  ${final}/RXNet

awk 'BEGIN{if('$rate'==0) fl="DG"; if('$rate'==1) fl="DE"}
NR==1{printf " TS #    %2s(kcal/mol)    -------Path info--------\n",fl}
NR>2{printf "%5.0f %12.3f       %4s %4s %4s %4s %4s\n",$2,$5,$7,$8,$9,$10,$11}' ${tsdirhl}/KMC/RXNet.cg >> tmp_RXNet.cg
if [ -f ${tsdirhl}/PRODs/PRlist_frag ]; then
   awk 'NR>1{for(i=1;i<NF;i++) if(i!=3) printf $i " ";print $NF}' ${tsdirhl}/PRODs/PRlist_frag | sed 's/.q0//g;s/.qm1/-/g;s/.qm/-/g;s/.q1/+/g;s/.q/+/g;s/.m/ .m/g' | awk '{for(i=1;i<=NF;i++) if ($i !~/.m/) printf " %s",$i;print ""}' >> tmp_RXNet.cg
fi

awk 'BEGIN{np=0;fl=0}
{
if(fl==0) {
   ++jwiso
   niso[jwiso]=NF
   for(i=1;i<=NF;++i) {n[jwiso,i]=$i;niso2[$i]=NF}
   }
}
{if(NF==0) fl=1}
{
if(NF>1 && fl==1) {lp=0;lp1=0;lp2=0
 if($1 !="PROD" ) {lp=1}
 for(i=1;i<=jwiso;++i) {
   for(j=2;j<=niso[i];++j) {
       if($3 =="PROD" &&  $4==n[i,j]) {lp1=1;pr1=n[i,1];++np;pr[np]=pr1}
       if($6 =="PROD" &&  $7==n[i,j]) {lp2=1;pr2=n[i,1];++np;pr[np]=pr2}
       if($1 =="PROD" &&  $2==n[i,j]) {lp=1}
     }
   }
 if($3 =="PROD" && lp1==0) {++np;pr[np]=$4}
 if($6 =="PROD" && lp2==0) {++np;pr[np]=$7}
 if($1=="TS") print $0
 if($1!="PROD" && $1!="TS" && lp1==0 && lp2==0) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,$4,$5,$6,$7
 if($1!="PROD" && $1!="TS" && lp1==1 && lp2==0) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,pr1,$5,$6,$7
 if($1!="PROD" && $1!="TS" && lp1==0 && lp2==1) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,$4,$5,$6,pr2
 if($1!="PROD" && $1!="TS" && lp1==1 && lp2==1) printf "%5s %12s       %4s %4s %4s %4s %4s\n",$1,$2,$3,pr1,$5,$6,pr2
 if(lp==0) {lpp=0
    for(i=1;i<=np;i++) {if($2==pr[i]) lpp=1}
    if(lpp==1) print $0}
 }
} ' tmp_RXNet.cg  > ${final}/RXNet.cg

##Add CONN or DISCONN in the last column of RXNet.cg 
if [ -f ${tsdirhl}/KMC/RXNet_long.cg_groupedprods ]; then
   file=${final}/RXNet.cg
   awk '{if($1=="TS") print $1,$2}' ${tsdirhl}/KMC/RXNet_long.cg_groupedprods >tmp_conn_proc
   awk 'NR==FNR{++nts;a[nts]=$2}
   NR>FNR{
      if($3=="MIN") {
        ts=$1
        flag="   DISCONN"
        for(i=1;i<=nts;i++) if(ts==a[i]) flag="   CONN"
        print $0,flag
      }
     else
        print $0
   }' tmp_conn_proc $file> RXNetcg0
   cp RXNetcg0  ${final}/RXNet.cg
fi
###
##Add CONN or DISCONN in the last column of RXNet.cg 

##copy the minima 
cp ${tsdirhl}/MINs/SORTED/minshl.db $final
sqlite3 $final/minshl.db "alter table minshl rename to min"
mv $final/minshl.db $final/min.db

##copy the TSs 
cp ${tsdirhl}/TSs/SORTED/tsshl.db $final
sqlite3 $final/tsshl.db "alter table tsshl rename to ts"
mv $final/tsshl.db $final/ts.db

##Making final MINinfo file
awk 'BEGIN{if('$rate'==0) fl="DG"; if('$rate'==1) fl="DE"}
NR==1{printf "MIN #    %2s(kcal/mol)\n",fl}
NR>=1{printf "%5.0f %12.3f\n",$2,$4}' ${tsdirhl}/MINs/SORTED/MINlist_sorted > ${final}/MINinfo
if [ -f ${tsdirhl}/working/conf_isomer.out ];then
   echo "Conformational isomers are listed in the same line:" >> ${final}/MINinfo
   cat ${tsdirhl}/working/conf_isomer.out >> ${final}/MINinfo
fi

##Making final TSinfo file
awk 'BEGIN{if('$rate'==0) fl="DG"; if('$rate'==1) fl="DE"}
NR==1{printf "TS  #    %2s(kcal/mol)\n",fl}
NR>=1{printf "%5.0f %12.3f\n",$2,$4}' ${tsdirhl}/TSs/SORTED/TSlist_sorted > ${final}/TSinfo
if [ -f ${tsdirhl}/working/conf_isomer_ts.out ];then
   echo "Conformational isomers are listed in the same line:" >> ${final}/TSinfo
   cat ${tsdirhl}/working/conf_isomer_ts.out >> ${final}/TSinfo
fi

##Making molden files to visualize freqs of TSs
n=0
for file in $(awk '{print $3}' ${tsdirhl}/TSs/SORTED/TSlist_sorted) 
do
    f="$(basename $file .rxyz)"
    ((n=n+1)) 
    number="$(printf %04d ${n%})"
    if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
       get_NM_g09_molden.sh ${tsdirhl}/${f}.log  $mdir/TS$number
    elif [ "$program_hl" = "qcore" ] ; then
       cp ${tsdirhl}/freq_${f}.molden  $mdir/TS${number}.molden
    fi
done

##Making molden files to visualize freqs of MINs 
n=0
for file in $(sed 's/_min/ min/g;s/_0//' ${tsdirhl}/MINs/SORTED/MINlist_sorted | awk '{print $4}') 
do
    f="$(basename $file .rxyz)"
    ((n=n+1)) 
    number="$(printf %04d ${n%})"
    if [ "$f" == "min0" ]; then
       if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ] ; then
          get_NM_g09_molden.sh ${tsdirhl}/${f}.log  $mdir/MIN$number
       elif [ "$program_hl" = "qcore" ] ; then
          cp ${tsdirhl}/freq_${f}.molden  $mdir/MIN${number}.molden
       fi 
    else
       if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
          get_NM_g09_molden.sh ${tsdirhl}/IRC/${f}.log  $mdir/MIN${number}
       elif [ "$program_hl" = "qcore" ] ; then
          cp ${tsdirhl}/IRC/freq_${f}.molden  $mdir/MIN${number}.molden
       fi
    fi
done


## kinetics file
kmcfile=${tsdirhl}/KMC/kmc${postb}.out 
brafile=${tsdirhl}/KMC/branching${postb}.out 

if [ -f $kmcfile ]; then
   cat $brafile >$final/kinetics$postb
   echo "" >> $final/kinetics$postb
   echo "Population of each species as a function of time" >>$final/kinetics$postb
   echo "++++++++++++++++++++++++++++++++++++++++++++++++" >>$final/kinetics$postb
   awk '{line[NR]=$0};/Calculation number/{fdata=NR+1};/Population/{ldata=NR}
   END{for(i=fdata;i<ldata;i++) print line[i]}' $kmcfile >tmp_kmc
   npro=$(awk 'BEGIN{npro=0};NR>1{++npro};END{print npro}' $brafile)
   pro="$(awk 'NR>1{j=0;for(i=NF-'$npro'+1;i<=NF;i++) {++j;if($i>0) l[j]=1}};END{for(i=1;i<='$npro';i++) if(l[i]==1) printf "%8s ",i}' tmp_kmc)"
   min="$(awk 'NR>1{nmin=NF-'$npro'-1;j=0;for(i=2;i<=NF-'$npro';i++) {++j;if($i>0) l[j]=1}};END{for(i=1;i<=nmin;i++) if(l[i]==1) printf "%8s ",i}' tmp_kmc
   )"
   echo  $npro "$pro" > tmp_kmc0
   for i in $(echo "$pro")
   do
      tmp="$(awk 'NR>1{++npro};{if(npro=='$i') for(i=2;i<=NF;i++) print $i}' $brafile | sed 's@ + @+@' )"
      echo $tmp | sed 's@ + @+@g' >>tmp_kmc0
   done
   echo "$min" >> tmp_kmc0
   awk 'BEGIN{units="'$units'"}
   {if(FNR==NR) if(FNR==1) {ntpro=$1;for(i=2;i<=NF;i++) {++npro;ipro[npro]=$i}
   for(i=1;i<=npro;i++) {getline;pro[ipro[i]]=$0}
   getline;for(i=1;i<=NF;i++) {++nmin;imin[i]=$i}
   }
   }
   /Time/{n=FNR
   for(i=1;i<=nmin;i++) min[i]="MIN"imin[i]
   printf "  Time(%2s) ",units
   for(i=1;i<=nmin;i++) printf "%8s ",min[i]
   for(i=1;i<=npro;i++) {printf "%20s ",pro[ipro[i]]}
   print ""}
   {if(FNR>n && NR>FNR) {
   printf "%10s ",$1;for(i=1;i<=nmin;i++) printf "%8s ",$(imin[i]+1)
   for(i=1;i<=npro;i++) {printf "%20s ",$(NF-ntpro+ipro[i])}
   print ""
   }
   }' tmp_kmc0 tmp_kmc >> $final/kinetics$postb
   ###Making plot. A max of 1e5 lines in the file are allowed and only 20 intermediates/products are printed
   awk 'BEGIN{p=0};/Time/{p=1};{if($1!~/Time/ && p==1) print $0}' ${final}/kinetics$postb > tmp_pop_data
   np=$(awk 'NR==1{print NF-1;exit}' tmp_pop_data)
   npoints=20
   if [ $np -lt 20 ]; then npoints=$np ; fi
   awk 'BEGIN{for(i=1;i<='$np';i++) maxp[i]=0}
   {for(i=2;i<=NF;i++) if($i>maxp[i]) maxp[i]=$i}
   END{for(i=2;i<=NF;i++) print i,maxp[i]}' tmp_pop_data | sort -k 2nr | awk 'NR<=20{print $0}' > tmp_cols
   awk 'NR==FNR{col[NR]=$1}
   NR>FNR{
   printf "\n %s",$1
   for(i=1;i<='$npoints';i++) printf " %s ",$col[i]
   }' tmp_cols tmp_pop_data | awk 'NF>1{print $0}' > ${final}/pop_data_$postb
   xhigh=$(awk '{xhigh=$1};END{print xhigh}' ${final}/pop_data_$postb)
   yhigh=$(awk 'BEGIN{yhigh=0};NR==1{for(i=2;i<=NF;i++) if($i>yhigh) yhigh=$i;print yhigh;exit}' ${final}/pop_data_$postb)
   sed 's@xhigh@'$xhigh'@;s@yhigh@'$yhigh'@' ${sharedir}/pop_template.gnu > ${final}/population${postb}.gnu
   xtics=$(echo $xhigh | awk '{printf "%3.2e",$1/4}')
   echo set xtics $xtics >> ${final}/population${postb}.gnu
   echo "set xlabel 'Time ($units)' font 'Times-Roman, 18' " >> ${final}/population${postb}.gnu
   echo set key noreverse top  >> ${final}/population${postb}.gnu
   echo "set ylabel 'Population' font 'Times-Roman, 18'" >> ${final}/population${postb}.gnu
   echo "set multiplot" >> ${final}/population${postb}.gnu
   for i in $(seq $npoints)
   do
     title=$(awk 'NR==FNR{col[NR]=$1};NR>FNR{if($1~/Time/) print $(col['$i'])}' tmp_cols ${final}/kinetics$postb)
     if [ $i -gt 1 ]; then pre=re; fi
     ((j=i+1))
     echo "${pre}plot 'pop_data_$postb' u 1:$j w l title '$title'"  >>${final}/population${postb}.gnu
   done
   echo pause -1  >> ${final}/population${postb}.gnu
   #PLOT_RELEVANT.sh
   #if [ -f diagram.gnu ]; then
   #   mv diagram.gnu ${final}/Energy_profile.gnu
   #fi
fi
nx.sh HL
###Change format of RXNet and RXNet.cg
format_rxnet.sh RXNet0 RXNet0 > ${final}/RXNet
if [ -f RXNetcg0 ] ; then format_rxnet.sh RXNetcg0 RXNetcg0 > ${final}/RXNet.cg ; fi
###Adding barrless to rxn_all.txt
if [ -f ${tsdirhl}/KMC/RXN_barrless2 ]; then
   format_rxnet.sh ${tsdirhl}/KMC/RXN_barrless2 ${tsdirhl}/KMC/RXN_barrless2 > ${final}/RXNet.barrless
   #we now screen barrless file to ensure there is no corresponding channels with a barrier and that the min is connected
   rm -rf tmp_minprod tmp_rxnetbarrless_screened tmp_minprod.barrless tmp_rxnetbarrless_screened tmp_ref_barr
   sed 's@PR@PR @g;s@:@ @g' ${final}/RXNet.cg |awk '{if($6=="PR") print $4,$7}' >tmp_minprod
   n=0
   for p in $(awk '{print $2}' tmp_minprod)
   do
       n=$((n+1))
       m=$(awk 'NR=='$n'{print $1}' tmp_minprod)
       ptag="$(awk 'NR=='$p'{print $0}' ${tsdirhl}/PRODs/PRlist_tags.log)"
       echo $m "$ptag" >> tmp_ref_barr
   done

   for pb in $(awk '{print NR}' ${final}/RXNet.barrless)
   do 
       line="$(awk 'NR=='$pb'{print $0}' ${final}/RXNet.barrless)"  
       if [ $pb -le 2 ]; then
          echo "$line" >>tmp_rxnetbarrless_screened
       else
          echo "$line" | sed 's@PR@PR @g;s@:@ @g' |awk '{print $4,$7}' >tmp_minprod.barrless
          m=$(awk '{print $1}' tmp_minprod.barrless)
          p=$(awk '{print $2}' tmp_minprod.barrless)
          ptag="$(awk 'NR=='$p'{print $0}' ${tsdirhl}/PRODs/PRlist_tags.log)"
          echo $m "$ptag" > tmp_ref_barrless
          cat tmp_ref_barrless tmp_ref_barr > tmp_comp
          ok1=$(awk '{for(i=1;i<=NF;i++) tag[NR,i]=$i}
          END{for(i=2;i<=NR;i++) {diff=0
               if(tag[1,1] != tag[i,1]) continue 
               if(tag[1,3] != tag[i,3]) continue 
               for(j=4;j<=NF;j++) diff+=sqrt((tag[1,j]-tag[i,j])^2) 
               if(diff<=0.001) {print "0";exit} 
               }
               print "1"
          }' tmp_comp)
          #check now that the min is connected
          minn=$(echo "$line" | awk '{print $4}')
          ok2=$(awk 'BEGIN{min="'$minn'";ok=0};{if($4==min || $7==min) if($NF=="CONN") ok=1};END{print ok}' ${final}/RXNet.cg)
          if [ $ok1 -eq 1 ] && [ $ok2 -eq 1 ]; then echo "$line" >> tmp_rxnetbarrless_screened ; fi
       fi 
   done
   mv tmp_rxnetbarrless_screened ${final}/RXNet.barrless 
   rm -rf tmp_minprod tmp_rxnetbarrless_screened tmp_minprod.barrless tmp_ref_barr
   awk 'NR>2{$1="";$2="";$3="";$5="";$6="";print $0 }' ${final}/RXNet.barrless | sed 's@ + @+@g' | awk '{rf=$1" "$2;r[rf]+=1};END{for (key in r) {print key,r[key]} }' >> ${final}/rxn_all.txt
fi
#rxn.py HL ${molecule}
###
if [ -f ${tsdirhl}/KMC/RXNet.relevant ]; then
   awk '{if($1=="TS") print $1,$2}' ${tsdirhl}/KMC/RXNet.relevant > tmp_rel
###create RXNet.rel
   file=${final}/RXNet.cg
   awk 'NR==FNR{++nts;a[nts]=$2}
   NR>FNR{
      if($3=="MIN") {
        ts=$1
        p=0
        for(i=1;i<=nts;i++) if(ts==a[i]) p=1
        if(p==1) print $0
      }
     else
        print $0
   }' tmp_rel $file | sed 's@CONN@@g' > ${final}/RXNet.rel
fi
###
###Add report.pdf to the final folder
######################################################v
cd ${final}
######################################################v
if [ -f RXNet.rel ]; then
   gnuplot <population${postb}.gnu>population${postb}.pdf
   #gnuplot <Energy_profile.gnu>Energy_profile.pdf
fi

#####################################################^
rm -rf population${postb}.gnu 
#####################################################v
if ! [ -z "$AMK_REPORT" ]
then
   enscript -q --margins=60::: --header='$n|%W|Page $% of $=' -p MINinfo.ps MINinfo
   enscript -q --margins=60::: --header='$n|%W|Page $% of $=' -p TSinfo.ps TSinfo
   enscript -q --margins=60::: --header='$n|%W|Page $% of $=' -p RXNet.ps RXNet
   enscript -q --margins=60::: --header='$n|%W|Page $% of $=' -p RXNet.cg.ps RXNet.cg
   ps2pdf MINinfo.ps MINinfo.pdf
   ps2pdf TSinfo.ps TSinfo.pdf
   ps2pdf RXNet.ps RXNet.pdf
   ps2pdf RXNet.cg.ps RXNet.cg.pdf
   pdftk ${sharedir}/header.pdf MINinfo.pdf TSinfo.pdf RXNet.pdf RXNet.cg.pdf graph_all.pdf graph_kin.pdf population${postb}.pdf cat output report_in.pdf
   cpdf -scale-to-fit a4portrait report_in.pdf -o report.pdf
fi
#####################################################^
rm -rf MINinfo.* RXNet.cg.* RXNet.pdf RXNet.ps RXNet.rel.* TSinfo.* report_in.pdf
cd ..


