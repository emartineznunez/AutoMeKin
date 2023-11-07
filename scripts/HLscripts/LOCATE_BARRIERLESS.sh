#!/bin/bash

source utils.sh
#On exit remove tmp files
tmp_files=(tmp_tag tmp_comp tmp_geom tmp* )
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
exe=$(basename $0)
cwd=$PWD
#tag is HL for high-level
tag=HL

if [ -f amk.dat ];then
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
#reading input
read_input
###We first create the file tsdirHL_molecule/MINs/SORTED/MIN_tags.log
echo Re-doing MIN_tags.log
rm -rf tsdir${tag}_${molecule}/MINs/SORTED/MIN_tags.log
for i in $(awk '{print $2}' tsdir${tag}_${molecule}/MINs/SORTED/MINlist_sorted)
do
   echo MIN $i
   sqlite3 tsdir${tag}_${molecule}/MINs/SORTED/minshl.db "select natom,geom from minshl where id='$i'" | sed 's@|@\n\n@g' > tmp_geom
   tag_prod.py tmp_geom | sed 's@-0.000@0.000@g' >> tsdir${tag}_${molecule}/MINs/SORTED/MIN_tags.log
done
###
if [ ! -d tsdir${tag}_${molecule}/IRC/DISS ]; then mkdir tsdir${tag}_${molecule}/IRC/DISS ; fi
sqlite3 tsdir${tag}_${molecule}/IRC/DISS/inputs.db "drop table if exists gaussian; create table gaussian (id INTEGER PRIMARY KEY,name TEXT, input TEXT, unique (name));"
###
nbl=0
calc=min_irc
diss=1
#set interactive mode to 0
inter=0
export inter
###
##Remove barrless dissociations from prod in case of previous calcs
sqlite3 tsdir${tag}_${molecule}/PRODs/prodhl.db "delete from prodhl where name like '%min_diss%'"
sed -i '/min_diss/d' tsdir${tag}_${molecule}/PRODs/PRlist
##
if [ ! -f tsdirLL_${molecule}/KMC/RXN_barrless ]; then exit ; fi
if [ $(awk 'BEGIN{n=0};NR>1{if($1!="PROD") ++n};END{print n}' tsdirLL_${molecule}/KMC/RXN_barrless) -eq 0 ]; then exit ; fi
if [ $rate -eq 0 ]; then 
   echo " TS #    DG(kcal/mol)    -------Path info--------" > tsdir${tag}_${molecule}/KMC/RXN_barrless0
elif [ $rate -eq 1 ]; then
   echo " TS #    DE(kcal/mol)    -------Path info--------" > tsdir${tag}_${molecule}/KMC/RXN_barrless0
fi
touch tsdir${tag}_${molecule}/MINs/SORTED/correspondence
for ii in $(awk 'NR>1{if($1!="PROD") print $1}' tsdirLL_${molecule}/KMC/RXN_barrless)
do
   echo Examining dissociation channel no. $ii
   imin=$(awk '{if($1=='$ii') print $4}' tsdirLL_${molecule}/KMC/RXN_barrless)
   sqlite3 tsdirLL_${molecule}/MINs/SORTED/mins.db "select natom,geom from mins where id='$imin'" | sed 's@|@\n\n@g' > tmp_geom
   tag_prod.py tmp_geom | sed 's@-0.000@0.000@g' > tmp_tag
   if [ $(awk 'BEGIN{f=0};{if($1=='$imin') f=1};END{print f}' tsdir${tag}_${molecule}/MINs/SORTED/correspondence) -eq 1 ]; then
      equal=$(awk '{if($1=='$imin') print $2}' tsdir${tag}_${molecule}/MINs/SORTED/correspondence) 
   else
      equal=$(cat tmp_tag tsdir${tag}_${molecule}/MINs/SORTED/MIN_tags.log | awk 'BEGIN{m=0};NR==1{ref=$0};NR>1{val=$0;if(val==ref) {m=NR-1;exit}};END{print m}')
      echo $imin $equal >> tsdir${tag}_${molecule}/MINs/SORTED/correspondence
   fi
   if [ $equal -gt 0 ]; then
      echo Low-Level minimum: $imin corresponds to High-Level minimum: $equal
      nbl=$((nbl+1))
      prn=$(awk '{if($1=='$ii') print $NF}' tsdirLL_${molecule}/KMC/RXN_barrless )
      sqlite3 tsdirLL_${molecule}/PRODs/prod.db "select natom,geom from prod where id='$prn'" | sed 's@|@\n\n@g' > tmp_geom
      formula0="$(sqlite3 tsdirLL_${molecule}/PRODs/prod.db "select formula from prod where id='$prn'")"
      formula=$(echo "$formula0" | sed 's@ + @+@g')
      id=$(sqlite3 tsdir${tag}_${molecule}/PRODs/prodhl.db "select max(id) from prodhl" | awk '{print $1+1}')
      name=PR${id}_min_diss_${nbl}
      named=min_diss_${nbl}
      geom="$(cat tmp_geom | awk 'NR>2{print $0}')"
      sqlite3 tsdir${tag}_${molecule}/PRODs/prodhl.db "insert into prodhl (natom,name,geom,formula) values ($natom,'$name','$geom','$formula0');"
      echo "PROD ${id} ${named}.rxyz" >> tsdir${tag}_${molecule}/PRODs/PRlist
      echo "$nbl energy_rel MIN $equal <-->  PROD ${id}" >> tsdir${tag}_${molecule}/KMC/RXN_barrless0
      chkfilef=diss_${nbl}
      chkfiler="nada"
      geof="$geom"
      geor="" 
      echo "$geof" > tmp_geomf_$nbl
      echo "$geor" > tmp_geomr_$nbl
      i=$nbl
      g09_input
   else
      echo Low-Level minimum: $imin does not correspond to any High-Level minimum 
   fi
done
##run the sp calcs
echo We now run the sp calcs
if [ $nbl -gt 0 ]; then
   doparallel "runMIN.sh {1} ${tsdirhl}/IRC/DISS $program_hl" "$(seq $nbl)"
fi

rm -rf tmp_geomf_* tmp_geomr_*

