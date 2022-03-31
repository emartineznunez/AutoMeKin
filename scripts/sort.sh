#!/bin/bash
source utils.sh
#remove tmp files
tmp_files=(tmp_noe tmp* fort.*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
inputfile=amk.dat
cwd=$PWD
###reading input files
read_input
###
# rate=0 print DG
# rate=1 print DE
if [ $rate -eq 0 ] ; then
   echo "Sort Gibbs Free Energy differences"
   dum_min0=$(sqlite3 ${tsdirll}/MINs/norep/minnr.db "select energy,g from minnr where name like '%min0%'" | sed 's@|@ @g')
elif [ $rate -eq 1 ]; then
   echo "Sort Energy(+ZPE) differences"
   dum_min0=$(sqlite3 ${tsdirll}/MINs/norep/minnr.db "select energy,zpe from minnr where name like '%min0%'" | sed 's@|@ @g')
fi

# First of all, we sort the TSs
if [ ! -d "$tsdirll/TSs/SORTED" ]; then
   mkdir $tsdirll/TSs/SORTED
else
   rm -r $tsdirll/TSs/SORTED
   mkdir $tsdirll/TSs/SORTED
fi
if [ ! -d "$tsdirll/MINs/SORTED" ]; then
   mkdir $tsdirll/MINs/SORTED
else
   rm -r $tsdirll/MINs/SORTED
   mkdir $tsdirll/MINs/SORTED
fi
###create sorted tables
sqlite3 ${tsdirll}/TSs/SORTED/tss.db "drop table if exists tss; create table tss (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,lname TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT);"
sqlite3 ${tsdirll}/MINs/SORTED/mins.db "drop table if exists mins; create table mins (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,lname TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT);"

# We start with the TSs
if [ -f tmp_noe ]; then rm tmp_noe ; fi

echo "non-ordered energies"
for name in $(sqlite3 ${tsdirll}/TSs/ts.db "select name from ts")
do
  echo $name
  namer=${name}.rxyz
  if [ $rate -eq 1 ]; then
     dum_en=$(sqlite3 ${tsdirll}/TSs/ts.db "select energy,zpe from ts where name='$name'" | sed 's@|@ @g')
  elif [ $rate -eq 0 ]; then
     dum_en=$(sqlite3 ${tsdirll}/TSs/ts.db "select energy,g from ts where name='$name'" | sed 's@|@ @g')
  fi
  echo "$dum_min0
  $dum_en" | awk '{e[NR]=$1;ezpe[NR]=$2};END{printf "%10s %10.6f\n","'$namer'",e[2]-e[1]+ezpe[2]-ezpe[1]}' >> tmp_noe
done
echo "ordered energies"
echo "final energies"
sort -k 2n tmp_noe | awk '{print "TS",NR,$0}' > $tsdirll/TSs/SORTED/TSlist_sorted
for i in $(awk '{print $2}' $tsdirll/TSs/SORTED/TSlist_sorted)
do
    name=$(awk 'NR=='$i'{print $3}' $tsdirll/TSs/SORTED/TSlist_sorted)
    namenr=$(basename $name .rxyz)
    echo $i $name
##keep this for the moment
    name0=TS$i
    names=TS${i}_${name}
##insert data into tss 
    sqlite3 "" "attach '${tsdirll}/TSs/ts.db' as ts; attach '${tsdirll}/TSs/SORTED/tss.db' as tss;
    insert into tss (natom,name,lname,energy,zpe,g,geom,freq) select natom,'$name0','$names',energy,zpe,g,geom,freq from ts where name='$namenr';"
done

# We now go on with the MINs
if [ -f tmp_noe ]; then rm tmp_noe ; fi

echo "non-ordered energies"
for name in $(sqlite3 ${tsdirll}/MINs/norep/minnr.db "select name from minnr")
do
  echo $name
  namer=${name}.rxyz
  if [ $rate -eq 1 ]; then
     dum_en=$(sqlite3 ${tsdirll}/MINs/norep/minnr.db "select energy,zpe from minnr where name='$name'" | sed 's@|@ @g')
  elif [ $rate -eq 0 ]; then
     dum_en=$(sqlite3 ${tsdirll}/MINs/norep/minnr.db "select energy,g from minnr where name='$name'" | sed 's@|@ @g')
  fi
  echo "$dum_min0
  $dum_en" | awk '{e[NR]=$1;ezpe[NR]=$2};END{printf "%10s %10.6f\n","'$namer'",e[2]-e[1]+ezpe[2]-ezpe[1]}' >> tmp_noe
done
echo "ordered energies"
echo "final energies"
sort -k 2n tmp_noe | awk '{print "MIN",NR,$0}' > $tsdirll/MINs/SORTED/MINlist_sorted
for i in $(awk '{print $2}' $tsdirll/MINs/SORTED/MINlist_sorted)
do
    name=$(awk 'NR=='$i'{print $3}' $tsdirll/MINs/SORTED/MINlist_sorted)
    namenr=$(basename $name .rxyz)
    name2=$(sed 's/_min/ min/g' $tsdirll/MINs/SORTED/MINlist_sorted | awk 'NR=='$i'{print $4}')
    echo $i $name2
##keep this for the moment
    name0=MIN$i
    names=MIN${i}_${name2}
##insert data into mins 
    sqlite3 "" "attach '${tsdirll}/MINs/norep/minnr.db' as minnr; attach '${tsdirll}/MINs/SORTED/mins.db' as mins;
    insert into mins (natom,name,lname,energy,zpe,g,geom,freq) select natom,'$name0','$names',energy,zpe,g,geom,freq from minnr where name='$namenr';"
done

sed 's/_min/ min/g' $tsdirll/MINs/SORTED/MINlist_sorted | awk '{print $1,$2,$4,$5}' > $tsdirll/MINs/SORTED/MINlist_sorted.log

