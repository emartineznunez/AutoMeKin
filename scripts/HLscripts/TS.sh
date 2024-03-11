#!/bin/bash
#default sbatch resources
#SBATCH --time=04:00:00
#SBATCH -n 4
#SBATCH --output=TS-%j.log
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#

sharedir=${AMK}/share

#exe=$(basename $0)
exe="TS.sh"
cwd=$PWD
source utils.sh
#On exit remove tmp files
tmp_files=(tmp*)
#trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

#current working dir

# Printing the references of the method
print_ref
#Make sure the script is run with one argument
if [ $# -eq 0 ]; then 
   echo "One argument is required" 
   exit 1
else
   inputfile=$1
fi
#Make sure the inputfile has not been deleted 
define_inputfile
###Do screnning before anything else (just in case)
screening.sh  $inputfile
##Reading High Level stuff
read_input
##checking that the HL stuff is read
if [ $noHLcalc -eq 0 ]; then echo Please, provide HighLevel keyword ; exit ; fi

#Make sure g09 is installed 
check_g09

min0=${molecule}
###Make $tsdirhl folder
if [ ! -d "$tsdirhl" ]; then
   echo "$tsdirhl does not exist. It will be created"
   mkdir $tsdirhl 2>tmp_err
   if [ -s tmp_err ]; then
      echo "check the path of tsdirll folder"
      exit
   fi
else
   echo "$tsdirhl already exists."
fi
###Make $tsdirhl/MINs folder
if [ ! -d "$tsdirhl/MINs" ]; then
   echo "$tsdirhl/MINs does not exist. It will be created"
   mkdir $tsdirhl/MINs
else
   echo "$tsdirhl/MINs already exists."
fi
##if using gaussian for low-level, path is complete
if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then reduce=0 ; fi
if [ -z "$reduce" ]; then
   echo Keyword HL_rxn_network has not been specified
   exit 1
else
   if [ $reduce -lt 0 ]; then
      echo "Running the HL calculations for a subset of the TSs (bimolecular channels excluded)"
      reduce_RXNet.py $molecule 
   elif [ $reduce -gt 0 ]; then
      echo "Running the HL calculations for a subset of the TSs (bimolecular channels excluded)"
      reduce_RXNet.py $molecule $reduce
   else
      echo "Running the HL calculations for the whole reaction network"
   fi
fi
echo "Molecule name" $min0
echo "tsdirll is " $tsdirll

m=0
file=${tsdirll}/tslist
sqlite3 ${tsdirhl}/inputs.db "drop table if exists gaussian; create table gaussian (id INTEGER PRIMARY KEY,name TEXT, input TEXT, unique(name));"
for name in $(awk '{print $3}' $file)
do
  check_ts 
  if [ $calc -eq 0 ]; then
    echo $tsdirhl/$name "already optimized"
  else
    ((m=m+1))
    echo $name "not optimized"
#construct g09 input file
    chkfile=$name
    calc=ts
    level=hl
    if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
       geo="$(get_geom_g09.sh $tsdirll/$name.out | awk '{if(NF==4) print $0};END{print ""}')"
    elif [ "$program_opt" = "mopac" ]; then
       geo="$(get_geom_mopac.sh $tsdirll/$name.out | awk '{if(NF==4) print $0};END{print ""}')"
    elif [ "$program_opt" = "qcore" ]; then
       geo="$(awk '/Final structure/{flag=1; next} EOF{flag=0} flag;END{print ""}' $tsdirll/$name.out )"
    fi
    if [ "$program_hl" = "g16" ]; then
       g09_input
    else
       ${program_hl}_input
    fi
    echo -e "insert or ignore into gaussian values (NULL,'$name','$inp_hl');\n.quit" | sqlite3 ${tsdirhl}/inputs.db
  fi
done 
echo "$m TS opt calculations"

#now the initial minimum
if [ -f $tsdirhl/min0.log ]; then
   if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
      calc=$(awk 'BEGIN{calc=1;nt=0};/Normal termi/{++nt};/Error termi/{calc=0};END{if(nt=='$noHLcalc') calc=0;print calc}' $tsdirhl/min0.log)
   elif [ "$program_hl" = "qcore" ];then
      calc=$(awk 'BEGIN{calc=1;ncheck=0};/Energy=/{if(NF==2) ncheck+=1};/Lowest/{ncheck+=1};/Error/{calc=0};END{if(ncheck==2) calc=0;print calc}' $tsdirhl/min0.log)
   fi
else
   calc=1
fi

if [ $calc -eq 0 ]; then
   echo "min0 already optimized"
else
   ((m=m+1))
   echo "min0 not optimized"
#construct g09 input file
   chkfile=min0 
   calc=min
   level=hl
   geo="$(awk '{if(NF==4) print $0};END{print ""}' ${min0}_ref.xyz)"
   if [ "$program_hl" = "g16" ]; then
      g09_input
   else
      ${program_hl}_input
   fi
   echo -e "insert or ignore into gaussian values (NULL,'min0','$inp_hl');\n.quit" | sqlite3 ${tsdirhl}/inputs.db
fi
#Perform m parallel calculations
echo Performing a total of $m ts opt calculations
if [ $m -gt 0 ]; then
   doparallel "runTS.sh {1} $tsdirhl $program_hl" "$(seq $m)"
fi

