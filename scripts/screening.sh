#!/bin/bash
source utils.sh

inputfile=$1
exe=$(basename $0)
cwd=$PWD
###reading the input file
read_input
###

#On exit remove tmp files
tmp_files=(${tsdirll}/tmp* ${tsdirll}/tslist_* fort.* tmp* black_list.dat black_list.out black_list* sprint.out deg.out deg_form.out deg* ConnMat ConnMat*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

tslistlog=${tsdirll}/tslistlog
screenlog=${tsdirll}/screening.log
##EMN
statint=${tsdirll}/stats_int
statlet=${tsdirll}/stats_let
n_int=0 ; n_let=0 ; n_intx=0 ; n_letx=0
for ba in $(ls -d */ | awk '/batch/')
do
   n_intb=0 ; n_letb=0 ; n_intbx=0 ; n_letbx=0
   if [ -f ${ba}stats_int ]; then n_intbx=$(awk '{print $1}' ${ba}stats_int) ; fi
   if [ -f ${ba}stats_let ]; then n_letbx=$(awk '{print $1}' ${ba}stats_let) ; fi
   if [ -f ${ba}stats_int ]; then n_intb=$(awk '{print $2}' ${ba}stats_int) ; fi
   if [ -f ${ba}stats_let ]; then n_letb=$(awk '{print $2}' ${ba}stats_let) ; fi
   n_intx=$(echo "scale=0; $n_intx + $n_intbx" | bc )
   n_letx=$(echo "scale=0; $n_letx + $n_letbx" | bc )
   n_int=$(echo "scale=0; $n_int + $n_intb" | bc )
   n_let=$(echo "scale=0; $n_let + $n_letb" | bc )
done
echo $n_intx / $n_int >> ${statint}
echo $n_letx / $n_let >> ${statlet}
##EMN
sqlite3 ${tsdirll}/data.db "create table if not exists data (id INTEGER PRIMARY KEY,name TEXT,datas TEXT,unique(name));"
##
if [ ! -d "$bu_ts" ]; then
   echo "Making a backup folder and saving tslist"
   mkdir $bu_ts 
   cp $tslistll $bu_ts
else
   echo "Removing backup folder content and saving tslist"
   rm $bu_ts/*
   cp $tslistll $bu_ts
fi

nrep=0
nerr=0
nfra=0
if [ -f ${screenlog} ]; then
   echo "" >> ${screenlog}
   nu=$(awk '/Summary/{nu=$6};END{print nu+1}' ${screenlog})
   echo "Summary of screening calculations. Execution $nu of $exe" >> ${screenlog}
else
   nu=1
   echo "Summary of screening calculations. Execution $nu of $exe" > ${screenlog}
fi

if [ -f "black_list.dat" ]; then rm black_list.dat; fi
if [ -f "black_list.out" ]; then rm black_list.out; fi
echo "Screening" > $tsdirll/tslist_screened
echo "List of disconnected (at least two fragments) TS structures" > $tsdirll/tslist_disconnected
for name in $(awk '{print $3}' $tslistll)
do
   file=${tsdirll}/${name}.out
   echo $file
   cp $file $bu_ts
   i=$(echo $name | sed 's@ts@@;s@_@ @' | awk '{print $1}')
   if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
      echo $natom > tmp_geom
      echo "" >> tmp_geom
      get_geom_g09.sh $file >> tmp_geom
   elif [ "$program_opt" = "qcore" ]; then
      awk '/Final structure/{flag=1; next} EOF{flag=0} flag{++n;a[n]=$0};END{print n"\n";for(i=1;i<=n;i++) print a[i]}' ${file} > tmp_geom
   else
      get_geom_mopac.sh $file > tmp_geom
   fi
   cherr=$(awk 'BEGIN{zero=0.0};/Error/{err=1};END{if(err==0) err=zero;print err}'  tmp_geom)
   if  [[ ("$cherr" -eq "1") ]] 
   then 
     ((nerr=nerr+1))
     echo "Structure ts$i removed-->opt failed"
     echo "Structure ts$i removed-->opt failed" >> ${screenlog}
     echo ts$i"_out Error">> $tsdirll/tslist_screened
### remove ouput files with errors
     rm -rf $file 
     sed -i '/'$name'/d' $tslistll
###
     continue 
   else
     echo ts$i"_out data">> $tsdirll/tslist_screened
   fi 
#we add the energy code (remove . and -) to the name
   if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
      tmp_e=$(get_energy_g09_${LLcalc}.sh $file 1)
   elif [ "$program_opt" = "qcore" ]; then
      tmp_e=$(awk '/Energy=/{e0=$2};END{print e0}' $file)
   else
      tmp_e=$(awk '/HEAT OF FORMATION =/{e=$5};END{printf "%9.3f\n",e}' $file)
   fi
   tag=$(echo $tmp_e | sed 's@\.@d@;s@-@m@')
   name_data=${name}_${tag}
   #Create _data file for ts${i} if it does not exist
   if [ -z $(sqlite3 ${tsdirll}/data.db "select id from data where name='$name_data'") ]; then
      createMat.py tmp_geom 2 $nA
      echo "1 $natom" | cat - ConnMat | sprint.exe >sprint.out
      paste <(awk 'NF==4{print $1}' tmp_geom) <(deg.sh) >deg.out
      deg_form.sh > deg_form.out
      echo $tmp_e > ${tsdirll}/${name}_data
      format.sh $name $tsdirll $thdiss 
      datas="$(cat ${tsdirll}/${name}_data)"
      sqlite3 ${tsdirll}/data.db "insert into data (name,datas) values ('$name_data','$datas');"
   else
      sqlite3 ${tsdirll}/data.db "select datas from data where name='$name_data'" > ${tsdirll}/${name}_data
   fi

   ndis=$(awk '{ndis=$1};END{print ndis}' ${tsdirll}/${name}_data )
### mv TSs where there is 2 or more fragments already formed
   if  [[ ("$ndis" -gt "1") ]]; then
     ((nfra=nfra+1))
     mv $file $tsdirll/DISCNT_ts$i.out
     if [ -f tmp_ELs ]; then els="$(cat tmp_ELs)" ; fi
     printf "Structure ts%-5s renamed as DISCNT_ts%-5s-->%2s fragments. Values of eigL: %-40s\n" $i $i $ndis "$els"
     printf "Structure ts%-5s renamed as DISCNT_ts%-5s-->%2s fragments. Values of eigL: %-40s\n" $i $i $ndis "$els" >> ${screenlog}
     sed -i '/'$name'/d' $tslistll
###remove from sqlite database
   fi
###
   cat ${tsdirll}/${name}_data >> $tsdirll/tslist_screened 
done
rm ${tsdirll}/ts*_data
reduce.sh $tsdirll ts
awk '{if($NF==1) print $0}' $tsdirll/tslist_screened.red > $tsdirll/tslist_screened.redconn
awk '{if($NF>1) print $0}' $tsdirll/tslist_screened.red >> $tsdirll/tslist_disconnected
diffGT.sh $tsdirll/tslist_screened.redconn $tsdirll ts $avgerr $bigerr
### mv repeated TSs
if [ -f "black_list.out" ]; then
   for i in $(awk '{print $0}' black_list.out)
   do 
     file=$tsdirll/ts${i}_*.out
     name=$(basename $file .out)
     mv $file $tsdirll/REPEAT_ts$i.out
###
     ((nrep=nrep+1))
     orig=$(awk '{if($2=='$i') {print $1;exit}}' $tsdirll/tslist_screened.lowdiffs)
     apes="$(awk '{if($2=='$i') {print $3,$4;exit}}' $tsdirll/tslist_screened.lowdiffs)"
     printf "Structure ts%-5s renamed as REPEAT_ts%-5s-->redundant with ts%-5s. Values of MAPE and BAPE: %-40s\n" $i $i $orig "$apes"
     printf "Structure ts%-5s renamed as REPEAT_ts%-5s-->redundant with ts%-5s. Values of MAPE and BAPE: %-40s\n" $i $i $orig "$apes" >> ${screenlog}
     sed -i '/'$name'/d' $tslistll
   done
fi
echo "$nrep repetitions"
echo "$nrep repetitions" >> ${screenlog}
echo "$nfra fragmented"
echo "$nfra fragmented" >> ${screenlog}
echo "$nerr opt failed"
echo "$nerr opt failed" >> ${screenlog}
###
if [ -f ${tsdirll}/track.db ]; then
   track_view.sh 
fi


