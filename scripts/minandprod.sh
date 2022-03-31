#!/bin/bash
source utils.sh
sharedir=${AMK}/share
#remove tmp files
tmp_files=(mingeom deg* tmp tmp* black_list.out black_list* ConnMat sprint.* ScalMat fort.*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

cwd=$PWD
exe=$(basename $0)
inputfile=amk.dat
##reading input file
read_input
###
if [ ! -d "$tsdirll/MINs/norep" ]; then
   echo "MINs/norep does not exist. It will be created"
   mkdir $tsdirll/MINs/norep
else
   echo "MINs/norep already exists."
   rm -r $tsdirll/MINs/norep
   mkdir $tsdirll/MINs/norep
fi
##create norep table
sqlite3 ${tsdirll}/MINs/norep/minnr.db "drop table if exists minnr; create table minnr (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT, sigma INTEGER);"
#
echo "Nomenclature" > $tsdirll/MINs/names_of_minima
echo "Screening" > $tsdirll/MINs/minlist_screened
echo "PR list" > $tsdirll/PRODs/PRlist
nmin=0
npro=0
nrm=0
##Remove barrless dissociations from prod in case of previous calcs
sqlite3 ${tsdirll}/PRODs/prod.db "delete from prod where name like '%min_diss%'"
##
for name in $(sqlite3 ${tsdirll}/MINs/min.db "select name from min")
do 
   echo $name
   ((nmin=nmin+1))
   echo "min $nmin --> ${name}.rxyz" >> ${tsdirll}/MINs/names_of_minima
   echo "min$nmin data" >> $tsdirll/MINs/minlist_screened
   sqlite3 ${tsdirll}/MINs/data.db "select datas from data where name='$name'" >> ${tsdirll}/MINs/minlist_screened 
done
rm -rf ${tsdirll}/MINs/*_data

for name in $(sqlite3 ${tsdirll}/PRODs/prod.db "select name from prod")
do 
   ((npro=npro+1))
   names=$(echo $name | sed 's@_min@ min@g' | awk '{print $2}') 
   echo "Products=" $names 
   echo "PROD" $npro ${names}.rxyz >> $tsdirll/PRODs/PRlist
done 
echo "Total number of minima" $nmin
#reduce output
reduce.sh $tsdirll/MINs min
awk '{if($NF==1) print $0}' $tsdirll/MINs/minlist_screened.red >  $tsdirll/MINs/minlist_screened.redconn
awk '{if($NF> 1) print $0}' $tsdirll/MINs/minlist_screened.red >> $tsdirll/MINs/minlist_disconnected
diffGT.sh $tsdirll/MINs/minlist_screened.redconn $tsdirll/MINs min $avgerr $bigerr
#remove repeated structures in this dir and also in MINs
cp $tsdirll/MINs/names_of_minima $tsdirll/MINs/names_of_minima_norep
if [ -f "black_list.out" ]; then 
   for i in $(awk '{print $0}' black_list.out)
   do
     echo "Structure min"$i "repeated"
     ((nrm=nrm+1))
     awk '{if($2 != '$i') print $0}' $tsdirll/MINs/names_of_minima_norep > tmp 
     cp tmp $tsdirll/MINs/names_of_minima_norep 
   done
else
   echo "No repetitions"
fi
###
nn=0
for name in $(awk '{if(NR>1) print $4}' ${tsdirll}/MINs/names_of_minima_norep)
do
  ((nn=nn+1))
  namenrxyz=$(basename $name .rxyz)
  number=$(awk 'NR=='$nn'+1,NR=='$nn'+1{print $2}'  ${tsdirll}/MINs/names_of_minima_norep)
  namenr=$(basename min${number}_${name} .rxyz)
##for the moment we copy rxyz stuff
#  cp ${tsdirll}/MINs/${name} ${tsdirll}/MINs/norep/min${number}_${name}
##insert data into minnr.db and delete it from min.db
  sqlite3 "" "attach '${tsdirll}/MINs/min.db' as min; attach '${tsdirll}/MINs/norep/minnr.db' as minnr;
  insert into minnr (natom,name,energy,zpe,g,geom,freq,sigma) select natom,'$namenr',energy,zpe,g,geom,freq,sigma from min where name='$namenrxyz';"
done
###
((nfin=nmin-nrm))
echo $nmin "have been optimized, of which" $nrm "removed because of repetitions"
echo "Current number of MINs optimized =" $nfin
#
