#!/bin/bash
# default sbatch FT2
#SBATCH --output=min-%j.log
#SBATCH --time=04:00:00
# partition selection

#_remove_this_in_ft_SBATCH -p shared --qos=shared
#SBATCH -c 1 --mem-per-cpu=2048
#SBATCH -n 8

# SBATCH --partition=cola-corta,thinnodes
# SBATCH -c 1
# SBATCH -n 24

source utils.sh
#remove tmp files
tmp_files=(tmp* batch* min.xyz opt.xyz freq.molden mingeom ScalMat sprint.dat ConnMat fort.*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
sharedir=${AMK}/share
cwd=$PWD
exe="min.sh"

#check whether amk.dat has not been deleted
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

m=0
sqlite3 ${tsdirll}/IRC/inputs.db "drop table if exists mopac; create table mopac (id INTEGER PRIMARY KEY,name TEXT, unique(name));"
for name in $(ls $tsdirll/TSs/*_thermo.out | sed 's/_thermo.out//g' | sed 's/\// /g' | awk '{print $NF}')
do
  echo $name 
  if [ -f ${tsdirll}/IRC/minf_${name}.out ] && [ -f ${tsdirll}/IRC/minr_${name}.out ]; then
     calc1=$(awk 'BEGIN{calc=1};/DONE ==/{calc=0};END{print calc}' ${tsdirll}/IRC/minf_${name}.out)
     calc2=$(awk 'BEGIN{calc=1};/DONE ==/{calc=0};END{print calc}' ${tsdirll}/IRC/minr_${name}.out)
     if [ $calc1 -eq 0 ] && [ $calc2 -eq 0 ]; then
        calc=0 
     else
        calc=1
     fi
  else
     calc=1
  fi

  if [ $calc -eq 0 ]; then
    echo "Calcs completed for" $name
  else
     ((m=m+1))
     getminfminr.sh $name 
     echo -e "insert or ignore into mopac values (NULL,'$name');\n.quit" | sqlite3 ${tsdirll}/IRC/inputs.db
  fi
done
echo Performing a total of $m min calculations
#Perform m parallel calculations
if [ $m -gt 0 ]; then
#ft2 slurm
if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
  if (( $m < $SLURM_NTASKS )); then 
    echo "WARNING: Number of min calculations ($m) lower than allocated tasks ($SLURM_NTASKS)."
  fi
fi
   doparallel "runmin.sh {1} $tsdirll $program_opt" "$(seq $m)"
fi
