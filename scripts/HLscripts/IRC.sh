#!/bin/bash
#default sbatch resources
#SBATCH --time=08:00:00
#SBATCH -n 4
#SBATCH --output=IRC-%j.log
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#

sharedir=${AMK}/share

cwd=$PWD
exe="IRC.sh"
source utils.sh
#On exit remove tmp files
tmp_files=(black* ConnMat deg* labels mingeom ScalMat sprint.out tmp* screening.log)
trap cleanup EXIT INT
#current working dir

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi

#####
read_input
##max values 0.001 and 1 
avgerr=$(echo $avgerr | awk '{avg=$1;if(avg>0.001) avg=0.001;print avg}' )
bigerr=$(echo $bigerr | awk '{big=$1;if(big>1) big=1;print big}' )

energy=$( awk 'BEGIN{e=0};{if($1=="Energy") e=$2};END{print e}'  $inputfile )
maxen=$(awk 'BEGIN{if('$rate'==0) en='$eft';if('$rate'==1) en='$energy'};{if($1=="MaxEn") en=$2};END{print en}' $inputfile )

min_name=${molecule}

###create table minhl.db
sqlite3 ${tsdirhl}/MINs/minhl.db "drop table if exists minhl; create table minhl (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT, sigma INTEGER, unique(name));"

echo "Molecule name" $min_name
echo "tsdirll is " $tsdirll

#
# First we copy min0 in MIN directory 
echo "Moving min0 to its final location"
name=min0
get_data_hl_output

sqlite3 ${tsdirhl}/MINs/minhl.db "insert into minhl (natom,name,energy,zpe,g,geom,freq,sigma) values ($natom,'$name',$energy,$zpe,$g,'$geom','$freq',$sigma);"

# Now we do things specific of IRC 
set_up_irc_stuff

en_min0=$(sqlite3 $tsdirhl/MINs/minhl.db "select energy,zpe from minhl where name='min0'" | sed 's@|@ @g' | awk '{printf "%20.10f\n",$1*627.51+$2}')
###tshl and tshldscnt tshlrep tshlhe table
sqlite3 ${tsdirhl}/TSs/tshl.db "drop table if exists tshl; create table tshl (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,number INTEGER,sigma INTEGER);"
sqlite3 ${tsdirhl}/TSs/tshldscnt.db "drop table if exists tshldscnt; create table tshldscnt (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,number INTEGER);"
sqlite3 ${tsdirhl}/TSs/tshlrep.db "drop table if exists tshlrep; create table tshlrep (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,number INTEGER);"
sqlite3 ${tsdirhl}/TSs/tshlhe.db "drop table if exists tshlhe; create table tshlhe (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT, energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,number INTEGER);"

#Loop over the ts's
ndi=0
nts=0
file=${tsdirll}/tslist
for name in $(awk '{print $3}' $file)
do
  echo "Checking $name"
  number=$(echo $name | sed 's@ts@@;s@_@ @' | awk '{print $1}')
  if [ -f $tsdirhl/${name}.log ]; then
    check_freq_ts
    if [ $ok -eq 1 ]; then
       ((nts=nts+1))
       #insert into tshl table
       get_data_hl_output 
       sqlite3 ${tsdirhl}/TSs/tshl.db "insert into tshl (natom,name,energy,zpe,g,geom,freq,number,sigma) values ($natom,'$name',$energy,$zpe,$g,'$geom','$freq',$number,$sigma);"
       #screen the list to remove duplicates
       screen_ts_hl
    else
       echo "failed to optimize $name"
       continue
    fi
  else
    echo $name "has been removed because of previous repetitions or it does not exist"
    continue
  fi
done 
#statistics
stats_hl_tss

##############################
##       Now run IRC        ##
##############################
echo "Now running the IRCs"
##
m=0
sqlite3 ${tsdirhl}/IRC/inputs.db "drop table if exists gaussian; create table gaussian (id INTEGER PRIMARY KEY,name TEXT, input TEXT, unique (name));"
for i in $(sqlite3 ${tsdirhl}/TSs/tshl.db "select name from tshl")
do
  en_ts=$(sqlite3 ${tsdirhl}/TSs/tshl.db "select energy,zpe from tshl where name='$i'" | sed 's@|@ @g' | awk '{printf "%20.10f\n",$1*627.51+$2}')
  deltg="$(echo "$en_min0" "$en_ts" | awk '{printf "%20.10f\n",$2-$1}')"
  res=$(echo "$deltg < $maxen" | bc )
  #if gaussian's irc is not complete, remove output 
  if [ -f ${tsdirhl}/IRC/ircf_${i}.log ] && [ -f ${tsdirhl}/IRC/ircr_${i}.log ]; then  
    if [ $(awk 'BEGIN{c=0};/Job /{c=1};END{print c}' ${tsdirhl}/IRC/ircf_${i}.log) -eq 0 ]; then rm -rf ${tsdirhl}/IRC/ircf_${i}.* ; fi
    if [ $(awk 'BEGIN{c=0};/Job /{c=1};END{print c}' ${tsdirhl}/IRC/ircr_${i}.log) -eq 0 ]; then rm -rf ${tsdirhl}/IRC/ircr_${i}.* ; fi
  fi
  if [ -f ${tsdirhl}/IRC/ircf_${i}.log ] && [ -f ${tsdirhl}/IRC/ircr_${i}.log ]; then
    echo "IRC completed for $i"
  elif [ -f ${tsdirhl}/IRC/irc_${i}.log ]; then
    echo "IRC completed for $i"
  elif [ $res -eq 0 ]; then
    echo "The energy of TS $i is: $deltg, which is greater than the threshold: $maxen" 
    sqlite3 "" "attach '${tsdirhl}/TSs/tshl.db' as tshl; attach '${tsdirhl}/TSs/tshlhe.db' as tshlhe;
    insert into tshlhe (natom,name,energy,zpe,g,geom,freq,number) select natom,name,energy,zpe,g,geom,freq,number from tshl where name='$i';delete from tshl where name='$i';"
  else
    ((m=m+1))
    echo "Submit IRC calc for" $i
    calc=irc
    if [ "$program_hl" = "g16" ]; then
       g09_input
    else
       ${program_hl}_input
    fi
  fi 
done
#Perform m parallel calculations
echo Performing a total of $m irc calculations
if [ $m -gt 0 ]; then
   doparallel "runIRC.sh {1} $tsdirhl $program_hl" "$(seq $m)"
fi

