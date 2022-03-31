#!/bin/bash
source utils.sh

inputfile=$1
exe=$(basename $0)
cwd=$PWD
###reading the input file
read_input
###

assocdir=${cwd}/assoc_${frA}_${frB}
assoclist=${assocdir}/assoclist
screenlog=${assocdir}/screening.log

#On exit remove tmp files
tmp_files=($assocdir/*.mop $assocdir/*.arc $assocdir/*.den $assocdir/*.res fort.* sprint.out deg.out deg_form.out deg* ConnMat ConnMat* mingeom*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

##
nrep=0
nerr=0
nfra=0
echo "Summary of screening calculations." > ${screenlog}
##
ls $assocdir/assoc*.out > $assoclist
if [ -f "black_list.dat" ]; then rm black_list.dat; fi
if [ -f "black_list.out" ]; then rm black_list.out; fi
echo "Screening" > $assocdir/assoclist_screened
echo "List of errors in the optimizations" > $assocdir/assoclist_opt_err
echo "List of disconnected (at least two fragments) structures" > $assocdir/assoclist_disconnected
for i in $(awk '{print $1}' $assoclist)
do
   file=$i
   name=$(basename $file .out)
   if [ "$program_opt" = "mopac" ]; then 
      get_geom_mopac.sh $file > tmp_geom
   elif [ "$program_opt" = "qcore" ]; then 
      awk '/Error/;/Final structure/{flag=1; next} EOF{flag=0} flag{++n;a[n]=$0};END{print n"\n";for(i=1;i<=n;i++) print a[i]}' ${file} > tmp_geom
   fi

   cherr=$(awk 'BEGIN{zero=0.0};/Error/{err=1};END{if(err==0) err=zero;print err}'  tmp_geom)
   if  [[ ("$cherr" -eq "1") ]] 
   then 
     ((nerr=nerr+1))
     echo $name" Error">> $assocdir/assoclist_screened
     echo $name" Error">> $assocdir/assoclist_opt_err
     echo $name" Error" >> ${screenlog}
#     echo $name" Error" 
### mv ouput files with errors
     mv $file $assocdir/OPTERR_$name
###
     continue 
   else
     echo $name" data">> $assocdir/assoclist_screened
   fi 

   createMat.py tmp_geom 2 $nA

   natom=$(awk 'NR==1{print $1}' tmp_geom )
   echo "1 $natom" | cat - ConnMat | sprint.exe >sprint.out
 
   paste <(awk 'NF==4{print $1}' tmp_geom) <(deg.sh) >deg.out

   deg_form.sh > deg_form.out

   if [ "$program_opt" = "mopac" ]; then
      awk '/HEAT OF FORMATION =/{e=$5};END{printf "%8.2f\n",e}' $file > $assocdir/${name}_data
   elif [ "$program_opt" = "qcore" ]; then
      awk '/Energy=/{e0=$2};END{print e0}' $file > $assocdir/${name}_data
   fi
   format.sh $name $assocdir $thdiss 
   ndis=$(awk '{ndis=$1};END{print ndis}' $assocdir/${name}_data )
### mv structures where there is 2 or more fragments already formed
   if  [[ ("$ndis" -gt "1") ]]; then
     ((nfra=nfra+1))
     mv $file $assocdir/DISCNT_$name
     els="$(cat tmp_ELs)"
     printf "Structure %-10s --> %2s fragments. Values of eigL: %-40s\n" $name $ndis "$els" >> ${screenlog}
   fi
###
   cat $assocdir/${name}_data >> $assocdir/assoclist_screened 
done
rm $assocdir/*_data
reduce.sh $assocdir assoc
awk '{if($NF==1) print $0}' $assocdir/assoclist_screened.red > $assocdir/assoclist_screened.redconn
awk '{if($NF>1) print $0}' $assocdir/assoclist_screened.red >> $assocdir/assoclist_disconnected
diffGT.sh $assocdir/assoclist_screened.redconn $assocdir assoc $avgerr $bigerr
### mv repeated structures
if [ -f "black_list.out" ]; then
   for i in $(awk '{print $0}' black_list.out)
   do 
     mv $assocdir/assoc$i.out $assocdir/REPEAT_assoc$i.out
     ((nrep=nrep+1))
     orig=$(awk '{if($2=='$i') {print $1;exit}}' $assocdir/assoclist_screened.lowdiffs)
     apes="$(awk '{if($2=='$i') {print $3,$4;exit}}' $assocdir/assoclist_screened.lowdiffs)"
     printf "Structure assoc%-5s --> redundant with assoc%-5s. Values of MAPE and BAPE: %-40s\n" $i $orig "$apes" >> ${screenlog}
   done
fi
###
#echo "$nrep repetitions"
echo "$nrep repetitions" >> ${screenlog}
#echo "$nfra fragmented"
echo "$nfra fragmented" >> ${screenlog}
#echo "$nerr opt failed"
echo "$nerr opt failed" >> ${screenlog}


sort_assoc.sh $inputfile $program_opt

select_assoc.sh $inputfile
###
