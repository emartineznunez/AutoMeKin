#!/bin/bash
#default sbatch FT2 resources
#SBATCH --time=08:00:00
#SBATCH -n 4
#SBATCH --output=MIN-%j.log
#_remove_this_in_ft_SBATCH --partition=cola-corta,thinnodes
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#
# SBATCH -p shared --qos=shared
# SBATCH --ntasks-per-node=2
# SBATCH -c 10

sharedir=${AMK}/share

exe="MIN.sh"
source utils.sh
#exe=$(basename $0)
#current working dir
cwd=$PWD
#On exit remove tmp files
tmp_files=(ConnMat deg* labels ScalMat sprint*)
#trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

#check if the inputfile has not been deleted
if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi

###reading input file
read_input
###

##############################
##     Now opt the minima   ##
##############################
echo "now the Minima dir "
n=0
sqlite3 ${tsdirhl}/IRC/inputs.db "drop table if exists gaussian; create table gaussian (id INTEGER PRIMARY KEY,name TEXT, input TEXT, unique (name));"
for i in $(sqlite3 $tsdirhl/TSs/tshl.db "select name from tshl")
do
  #check is the min is already optimized
  check_min
  if [ $calc -eq 0 ]; then
    echo "Min opt completed for" $i
  else
    ((n=n+2))
    echo "Submit Mins opt calc for" $i
#gettting the minima structures from the IRC output files
    get_minfminr_g09.sh $i 
#set-up gaussin09 calculation for $i
#    names[$n]=$i
####
  fi 
done
#Perform n parallel calculations
echo Performing a total of $n opt calculations
if [ $n -gt 0 ]; then
   doparallel "runMIN.sh {1} ${tsdirhl}/IRC $program_hl" "$(seq $n)"
fi


