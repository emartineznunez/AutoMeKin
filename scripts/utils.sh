#!/bin/bash

#Function for usage of amk_parallel
function usage {
   echo $*
   echo "Execute this script as in this example:"
   if [ "$exe" == "slurm_script" ]; then exe="sbatch amk_parallel.sh";fi
   echo ""
   echo " $exe FA.dat 100"
   echo ""
   echo " where FA.dat is the inputfile and 100 is the total number of tasks"
   echo ""
   exit 1
}

#Function for usage of amk
function usages {
   echo $*
   echo "Execute this script as in this example:"
   echo "  $exe amk.dat "
   echo "where amk.dat is the inputfile "
   exit 1
}

#Function for usage of llcalcs
function usagell {
   echo $*
   echo "Execute this script as in this example:"
   echo "  $exe amk.dat nbatches niter"
   echo "where amk.dat is the inputfile"
   echo "nbatches is the number of batches"
   echo "and niter the number of interactions"
   exit 1
}

#Function to printout the references
function print_ref {
   build="$(awk '{print $1}' ${AMK}/share/amk_build)"
   echo "==================================="
   echo "                                   "
   echo "           AutoMeKin2021           "
   echo "                                   "
   echo "        revision number ${build}   "
   echo "                                   "
   echo "==================================="
}

#Function to select dialog engine (zenity/yad)
function dialog {
	if yad --help-gtk &>/dev/null; then DIALOG="yad";fi
	if zenity --help-gtk &>/dev/null; then DIALOG="zenity";fi
	if [ -z "$DIALOG" ]
      then
      echo "Please install zenity (https://gitlab.gnome.org/GNOME/zenity) or yad (https://github.com/v1cont/yad)"
      if [ -z $inter ] && [ -z $iter ]; then exit 1 ; fi
    else
      export DIALOG
    fi
}

dialog

#Function to submit jobs using slurm
function slurm {
#lets the user specify memory
#$SLURM_MEM_PER_CPU defined when option --mem-per-cpu= is used
#$SLURM_MEM_PER_NODE defined when option --mem= is used
   MEMPERCORE=$(sinfo -e -n $SLURM_NODELIST  -N -o "%m %c" -h | awk '{if(NR==1){min=$1/$2}else{new=$1/$2;if(new<min)min=new}}END{print min}')
   corespertask=${SLURM_CPUS_PER_TASK=1}
   if [ ! -z $SLURM_MEM_PER_NODE ]
   then
     #--ntasks-per-node= compulsory
     if [ ! -z $SLURM_NTASKS_PER_NODE ]
     then
       MEMPERCORE=$(( $SLURM_MEM_PER_NODE/ ($SLURM_NTASKS_PER_NODE * $corespertask) ))
     else
       echo "Please specify --ntasks-per-node= at the sbatch invocation"
       echo "or use --mem-per-cpu= option"
       exit 1
     fi
   fi
   if [ ! -z $SLURM_MEM_PER_CPU ]
   then
     MEMPERCORE=$SLURM_MEM_PER_CPU
   fi

#  SRUN="srun --exclusive -N1 -n1 --mem-per-cpu=$MEMPERCORE"
   SRUN="srun -N1 -n1 --mem=$(( $MEMPERCORE*$corespertask )) -c $corespertask --cpu_bind=none"
   runningtasks=$SLURM_NTASKS
}


#Function to submit jobs in parallel
function doparallel {
if [ ! -d amk_parallel-logs ];then mkdir amk_parallel-logs;fi

#slurm job?
if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]
then
  slurm
else
# use as many concurrent tasks as number of cores-1 (if it is not defined or ill-defined)
  if [ -z $runningtasks ] || [ $runningtasks -gt $(nproc --ignore=1) ]; then
     runningtasks=$(nproc --ignore=1)
  fi
fi

# --delay 0.2 prevents overloading the controlling node
# -j is the number of tasks parallel runs
# --joblog makes parallel create a log of tasks that it has already run
# --resume-failed makes parallel use the joblog to resume from where it has left off
# the combination of --joblog and --resume allow jobs to be resubmitted if
# necessary and continue from where they left off

#progress bar only in interactive mode
if [ -z $inter ] && [ -z "$SRUN" ]; then
   parallel="parallel --bar --delay 0.2 -j $runningtasks --joblog amk_parallel-logs/${exe}-${iter}-tasks.log"
else
   parallel="parallel --delay 0.2 -j $runningtasks --joblog amk_parallel-logs/${exe}-${iter}-task.log"
fi
# this runs the parallel command we want
# in this case, we are running a script named runGP.sh
# parallel uses ::: to separate options. Here {0..99} is a shell expansion
# so parallel will run the command passing the numbers 0 through 99
# via argument {1}
COMMAND=$1
TASKS=$2
#$parallel "runGP.sh {1} $molecule" ::: $(seq $noj1 $nojf)
if [ -z "$SRUN" ]; then
   if [ -z $inter ]; then
      if [ -z $iter ]; then
         $parallel $COMMAND ::: $TASKS 2> >(${DIALOG} --progress --auto-close --no-cancel --title="parallel progress bar $exe" --width=500 --height=100 2> /dev/null) &
      else
         $parallel $COMMAND ::: $TASKS 2> >(${DIALOG} --progress --auto-close --no-cancel --title="parallel progress bar $exe iter=$iter" --width=500 --height=100 2> /dev/null)  &
      fi
   else
      nohup $parallel $COMMAND ::: $TASKS  >/dev/null 2>&1 & 
      echo $! > .parallel.pid
      wait
   fi
   echo $! > .parallel.pid
else
   $parallel $SRUN $COMMAND ::: $TASKS
fi
}

#function to printout the line in which the error occurred
function err_report {
    echo "Error on line $1 of $exe"
    rm -rf ${tmp_files[@]} 
    exit 1
}

function err_report2 {
    if [[ $exe == "amk.sh" ]]; then
       if [[ $1 != $2 ]]; then
          echo "Error on line $1 of $exe"
          rm -rf ${tmp_files[@]}
          exit 1
       fi
    else
          echo "Error on line $1 of $exe"
          rm -rf ${tmp_files[@]}
          exit 1
    fi
}

#function to cleanup on exit
function cleanup {
    rm -rf ${tmp_files[@]} 
    echo ""
    echo "Cleaning up tmp files and exiting $exe"
}

function cleanup2 {
    rm -rf ${tmp_files[@]} 
}


function read_input {
   mdc=0
   sharedir=${AMK}/share
   nb=$(basename $cwd | awk '{if(length($1)>8) print "wrkdir" ;else print $1}')
   srandseed=$(echo $nb | awk '/batch/{print $0}' | sed 's@batch@@' | awk '{print $1+100}')
   molecule=$(awk '{if($1=="molecule") print $2}'  $inputfile)
   if [ -f ${molecule}.xyz ]; then
      natom=$(awk 'NR==1{print $1}' ${molecule}.xyz)
   fi
#   fragments=$(awk 'BEGIN{f=0};{if($1=="fragments" && $2=="yes") f=1};{if($1=="fragments" && $2=="no") f=0};END{print f}' $inputfile)
   charge=$(awk 'BEGIN{ch=0};{if($1=="charge") ch=$2};END{print ch}' $inputfile)
   multiple_minima=$(awk 'BEGIN{mm=1};{if($1=="multiple_minima" && $2=="yes") mm=1};{if($1=="multiple_minima" && $2=="no") mm=0};END{print mm}' $inputfile)
   barrierless=$(awk 'BEGIN{bl="no"};{if($1=="barrierless" && $2=="yes") bl="yes"};{if($1=="barrierless" && $2=="no") bl="no"};END{print bl}' $inputfile)
   mult=$(awk 'BEGIN{mult=1};{if($1=="mult") mult=$2};END{print mult}' $inputfile)
# sampling:			md:	
# 0  ---> BXDE			0
# 1  ---> MD-micro		1
# 2  ---> MD			2
# 3  ---> ChemKnow		Not defined
# 4  ---> external	       -1	
# 30 ---> association	       -1
# 31 ---> vdW			0
   sampling=$(awk 'BEGIN{sa=2};{if($1=="sampling" && $2=="BXDE") sa=0; if($1=="sampling" && $2=="MD-micro") sa=1;if($1=="sampling" && $2=="MD") sa=2;if($1=="sampling" && $2=="ChemKnow") sa=3;if($1=="sampling" && $2=="association") sa=30;if($1=="sampling" && $2=="vdW") sa=31; if($1=="sampling" && $2=="external") sa=4};END{print sa}'  $inputfile)
   tight=$(awk 'BEGIN{ti=1};{if($1=="tight_ts" && $2=="no") ti=0 };END{print ti}' $inputfile)
   torsion=$(awk 'BEGIN{torsion=1};{if($1=="torsion" && $2=="no") torsion=0};END{print torsion}' $inputfile)
   md=$(awk 'BEGIN{md=2};{if($1=="sampling" && $2=="BXDE") md=0; if($1=="sampling" && $2=="MD-micro") md=1;if($1=="sampling" && $2=="MD") md=2;if($1=="sampling" && $2=="association") md=-1;if($1=="sampling" && $2=="vdW") md=0; if($1=="sampling" && $2=="external") md=-1};END{print md}'  $inputfile)
   rate=$(awk 'BEGIN{rate=-1};{if ($1=="Temperature") rate=0;if($1=="Energy") rate=1};END{print rate}' $inputfile)
   tread=$(awk 'BEGIN{t=298};{if($1=="Temperature") t=$2};END{printf "%d",t+0.5}' $inputfile)
   ck_minima=$(awk 'BEGIN{ck=0};{if($1=="CK_minima" && $2=="all") ck=0;if($1=="CK_minima" && $2=="cg") ck=1};END{print ck}' $inputfile)
   if (( $(echo "$tread >= 10000" |bc -l) )); then 
      temperature=9999  
      echo ""
      echo "WARNING: Temperature >= 10000 K"
      echo Temperature set to 9999 K
      echo ""
   elif (( $(echo "$tread < 100" |bc -l) )); then 
      temperature=100  
      echo ""
      echo WARNING: Temperature < 100 K
      echo Temperature set to 100 K
      echo ""
   else
      temperature=$tread
   fi
   energy=$(awk 'BEGIN{e=0};{if($1=="Energy") e=$2};END{printf "%d",e+0.5}'  $inputfile) 
   method=$(awk 'BEGIN{llcalc="pm7 threads=1"};{if($1=="LowLevel" && $2=="mopac") {$1="";$2="";llcalc=$0" threads=1"}; if($1=="LowLevel" && $2=="qcore") llcalc="xtb"};END{print llcalc}' $inputfile)
   tsdirhl=$(awk '{if($1 == "tsdirhl") {print $2;nend=1}};END{if(nend==0) print "'$cwd'/tsdirHL_'$molecule'"}' $inputfile)
   wrkmode=$(awk 'BEGIN{mode=1};{if($1=="post_proc" && $2=="bbfs" && NF==4) mode=$4};END{if(mode!=1) mode=0;print mode}' $inputfile)
##templates for mopac calcs
   min_template="$(cat $sharedir/freq_template1 | sed 's/method/'"$method"' charge='$charge'/g')"
   freq_template="$(cat $sharedir/freq_template2 | sed 's/method/'"$method"' charge='$charge'/g')"
##
   nforces=$(awk 'BEGIN{nf=4};{if($1=="nforces") nf=$2};END{print nf}' $inputfile)
   itrajn=$(awk 'BEGIN{tr=1};{if($1=="ntraj") tr=$2};END{print tr}'  $inputfile)
   nfs=$(awk 'BEGIN{time=500};{if($1=="fs") time=$2};END{print time}'  $inputfile)
   use_nfs=$(awk 'BEGIN{u=0};{if($1=="fs") u=1};END{print u}'  $inputfile)
   imag=$(awk 'BEGIN{imag=0};{if($1=="imagmin") imag=$2};END{print imag}'  $inputfile )
   tsdirll=$(awk '{if($1 == "tsdirll") {print $2;nend=1}};END{if(nend==0) print "'$cwd'/tsdirLL_'$molecule'"}' $inputfile)
   kmcfilell=${tsdirll}/KMC/RXNet_long.cg_groupedprods
   minfilell=${tsdirll}/MINs/SORTED/MINlist_sorted
   postp_alg=$(awk 'BEGIN{p=1};{if($1=="post_proc" && $2=="bbfs") p=1};{if($1=="post_proc" && $2 =="bots") p=2};{if($1=="post_proc" && $2=="no") p=0};END{if('$sampling'==30) p=0;if('$sampling' >=1 && '$sampling' <=3) p=1; print p}' $inputfile)
   irange=$(awk 'BEGIN{irange=20};{if($1=="post_proc" && $2=="bbfs" && NF>=3) irange=$3};END{print irange}'  $inputfile)
   irangeo2=$(echo "scale=0; $irange/2" | bc )
   cutoff=$(awk 'BEGIN{co=200};{if($1=="post_proc" && $2=="bots" && NF>=3) co=$3};END{print co}' $inputfile)
   stdf=$(awk 'BEGIN{stdf=2.5};{if($1=="post_proc" && $2=="bots" && NF==4) stdf=$4};END{print stdf}' $inputfile)
   tslistll=${tsdirll}/tslist
   working=${tsdirll}/working
   workinghl=${tsdirhl}/working
   bu_ts=${tsdirll}/backup
   avgerr=$(awk 'BEGIN{a=0.001};{if($1=="MAPEmax") a=$2};END{print a}' $inputfile)
   bigerr=$(awk 'BEGIN{b=0.001};{if($1=="BAPEmax") b=$2};END{print b}' $inputfile)
   thdiss=$(awk 'BEGIN{t=0.001};{if($1=="eigLmax") t=$2};END{print t}' $inputfile)
   nmol=$(awk 'BEGIN{nmol=1000};{if($1=="nmol") nmol=$2};END{print nmol}'  $inputfile)
   imin=$(awk 'BEGIN{imin="min0"};{if($1=="imin") imin=$2};END{print imin}'  $inputfile)
   step=$(awk 'BEGIN{step=10};{if ($1=="Stepsize") step=$2};END{printf "%8.0f",step}'  $inputfile)
   if [ $rate -eq 0 ] && [ -z $temperature ]; then 
      echo Temperature has not been provided
      exit 
   fi
   if [ -z $temperature ]; then temperature=300 ; fi
   eft=$(emax_from_temp.py $temperature) 
   emaxts=$(awk 'BEGIN{if('$rate'==0) en='$eft';if('$rate'==1) en='$energy'};{if($1=="MaxEn") en=$2};END{print 1.5*en}' $inputfile)
   recalc=$(awk 'BEGIN{rec=-1};{if($1=="recalc" && NF>1) rec=$2};END{print rec}' $inputfile)
   ts_let=$(awk 'BEGIN{if('$sampling' != 3)tl=0;if('$sampling' == 3)tl=1};{if($1=="Use_LET" && $2=="yes") tl=1};{if($1=="Use_LET" && $2=="no") tl=0};END{print tl}' $inputfile)
   if [ $recalc -eq 0 ] || [ $recalc -lt -1 ]; then
      echo invalid value for recalc keyword
      exit 
   fi
   frA=$(awk '{if($1=="fragmentA") {print $2;exit}}' $inputfile)
   frB=$(awk '{if($1=="fragmentB") {print $2;exit}}' $inputfile)
   hessianmethod=$(awk 'BEGIN{m="analytic"};{if($1 == "hessianmethod") m=$2};END{print m}' $inputfile)
   if [ $sampling -ge 30 ];then
      if [ -f ${frA}.xyz ]; then
         nA=$(awk 'NR==1{print $1}' ${frA}.xyz)
      fi
      if [ -f ${frB}.xyz ]; then
         nB=$(awk 'NR==1{print $1}' ${frB}.xyz)
      fi
   else
      nA=$natom
      nB=0
   fi
   nassoc=$(awk 'BEGIN{n=100};{if($1=="Nassoc") n=$2};END{print n}' $inputfile)
   ptgr=$(awk 'BEGIN{impa=0};{if($1=="ImpPaths") impa=$2};END{print impa}' $inputfile)
   program_md=$(awk 'BEGIN{pmd="mopac"};{if($1=="LowLevel") {pmd=$2}};END{print tolower(pmd)}' $inputfile)
###check qcore is installed
   if [ "$program_md" = "qcore" ];then
      if ! command -v qcore &> /dev/null
      then
         echo ""
         echo "Entos Qcore does not seem to be installed"
         echo "Aborting..."
         exit
      fi
   fi
   program_opt=$(awk 'BEGIN{popt="'$program_md'"};{if($1=="LowLevel_TSopt") {popt=$2}};END{print tolower(popt)}' $inputfile)
###check g09 is installed
   if [ "$program_opt" = "g09" ];then
      if ! command -v g09 &> /dev/null
      then
         echo ""
         echo "g09 does not seem to be installed"
         echo "Aborting..."
         exit
      fi
   elif [ "$program_opt" = "g16" ];then
      if ! command -v g16 &> /dev/null
      then
         echo ""
         echo "g16 does not seem to be installed"
         echo "Aborting..."
         exit
      fi
   fi
   if [ $wrkmode -eq 0 ]; then 
      if [ "$program_opt" = "qcore" ];then
         ts_template="$(cat $sharedir/ts_templateslow | sed 's/method/pm7 charge='$charge'/g')" 
      else
         ts_template="$(cat $sharedir/ts_templateslow | sed 's/method/'"$method"' charge='$charge'/g')" 
      fi
      nppp=3
   elif [ $wrkmode -eq 1 ]; then 
      if [ "$program_opt" = "qcore" ];then
         ts_template="$(cat $sharedir/ts_templatefast | sed 's/method/pm7 charge='$charge'/g')" 
      else
         ts_template="$(cat $sharedir/ts_templatefast | sed 's/method/'"$method"' charge='$charge'/g')" 
      fi
      nppp=1
   fi
   if [ "$program_opt" = "qcore" ];then
      bo_template="$(sed 's/method/pm7 charge='$charge' BONDS INT/g' $sharedir/freq_template1)"
   else
      bo_template="$(sed 's/method/'"$method"' charge='$charge' BONDS INT/g' $sharedir/freq_template1)"
   fi
   prog=$(awk '{if("'$program_opt'"=="xtb") prog=-1;if("'$program_opt'"=="qcore") prog=0;if("'$program_opt'"=="mopac") prog=1; if("'$program_opt'"~/g[01][96]/) prog=2};END{print prog}' $inputfile)
   method_opt=$(awk 'BEGIN{llcalc="pm7"};{if($1=="LowLevel_TSopt") {llcalc=$3}};END{print tolower(llcalc)}' $inputfile)
   LLcalc=$(echo "$method_opt" | sed 's@/@ @g;s@u@@g' | awk 'BEGIN{IGNORECASE=1};{if($1=="hf") m="HF";else if($1=="mp2") m="MP2"; else if($1=="ccsd(t)") m="CCSDT";else m="DFT"};END{print m}' )
   atom1rot=$(awk 'BEGIN{ff=-1};{if($1=="rotate") ff=$2;if(ff=="com") ff=-1};END{print ff}' $inputfile)
   atom2rot=$(awk 'BEGIN{ff=-1};{if($1=="rotate") ff=$3;if(ff=="com") ff=-1};END{print ff}' $inputfile)
   dist=$( awk 'BEGIN{d=4.0};{if($1=="rotate") d=$4};END{print d}' $inputfile)
   distm=$(awk 'BEGIN{d=1.5};{if($1=="rotate") d=$5};END{print d}' $inputfile)
   factorflipv=$( awk '{if($1=="factorflipv") factor=$2};END{print factor}'  $inputfile )
   nbondsfrozen=$( awk 'BEGIN{nbf=0};{if($1=="nbondsfrozen") nbf=$2};END{print nbf}'  $inputfile ) 
   if [ $nbondsfrozen -gt 0 ]; then
      rm -rf fort.67 
      for i in $(seq 1 $nbondsfrozen)
      do
         bf="$(awk '{if($1=="nbondsfrozen") {i=1;while(i<='$i'){getline;if(i=='$i') print $1,$2;++i}}}' $inputfile)"
         echo "$bf" >> fort.67
      done
   fi
   nbondsbreak=$( awk 'BEGIN{nbb=0};{if($1=="nbondsbreak") nbb=$2};END{print nbb}'  $inputfile )
   if [ $nbondsbreak -gt 0 ]; then
      mdc=1
      awk '{if($1=="nbondsbreak") {nbb=$2;for(i=1;i<=nbb;i++) {getline;print $0}}}' $inputfile > fort.68
   fi
   nbondsform=$( awk 'BEGIN{nbfo=0};{if($1=="nbondsform") nbfo=$2};END{print nbfo}'  $inputfile )
   if [ $nbondsform -gt 0 ]; then
      mdc=1
      awk '{if($1=="nbondsform") {nbb=$2;for(i=1;i<=nbb;i++) {getline;print $0}}}' $inputfile > fort.69
   fi 
#HL stuff
   program_hl="$(awk '{if($1=="HighLevel") print $2}' $inputfile)"
   if [ -z "$program_hl" ]; then
      if [ $sampling -ne 30 ]; then
         echo HighLevel keyword has not been defined
         exit 1
      fi
   elif [ "$program_hl" = "qcore" ]; then
      HLstring0="qcore_template"
   elif [ "$program_hl" = "g09" ]; then
      HLstring0="$(awk '{if($1=="HighLevel") print $3}' $inputfile)"
   elif [ "$program_hl" = "g16" ]; then
      HLstring0="$(awk '{if($1=="HighLevel") print $3}' $inputfile)"
   else
      echo HighLevel value is $program_hl , and it should be qcore ,g09 or g16
      exit 1
   fi
   HLstring="$(echo "$HLstring0" | sed 's@//@ @')"
   reduce=$(awk 'BEGIN{red=-1};{if($1=="HL_rxn_network") {if($2=="complete") red=0;if($2=="reduced" && NF==3) red=$3}};END{print red}' $inputfile)
   noHLcalc=$(echo $HLstring | awk 'BEGIN{nc=0};{nc=NF};END{print nc}')
   IRCpoints=$(awk 'BEGIN{if("'$program_hl'"~/g[01][96]/)np=100;if("'$program_hl'"=="qcore")np=500};{if($1=="IRCpoints") np=$2};END{print np}' $inputfile)
   iop=$(awk '{if($1=="iop") {$1="";print $0}}' $inputfile)
   mem=$(awk 'BEGIN{mem=1};{if($1=="Memory") mem=$2};END{print mem}' $inputfile)
   pseudo=$(awk '{if($1=="pseudo") print "pseudo=read" }' $inputfile)
   pseudo_metal=$(awk '{if($1 == "pseudo") print $2}' $inputfile)
   pseudo_method=$(awk '{if($1 == "pseudo") print $3}' $inputfile)
   pseudo_atoms="$(awk '{if($1 == "pseudo") {for(i=4;i<NF;i++) printf "%s ",$i;print "0"}}' $inputfile)"
   pseudo_basis="$(awk '{if($1 == "pseudo") print $NF}' $inputfile)"
###
   if [ -z $pseudo ]; then
       pseudo_end=""
   else
       pseudo_end="$(echo -e "$pseudo_atoms"'\n'"$pseudo_basis"'\n'"****"'\n'$pseudo_metal 0'\n'$pseudo_method'\n'"****"'\n''\n'$pseudo_metal'\n'$pseudo_method'\n'" ")"
   fi
###
   level1=$(echo $HLstring | awk '{print $NF}')
   HLcalc1=$(echo "$level1" | sed 's@/@ @g;s@u@@g' | awk 'BEGIN{IGNORECASE=1};{if($1=="hf") m="HF";else if($1=="mp2") m="MP2"; else if($1=="ccsd(t)") m="CCSDT";else m="DFT"};END{print m}' )
#   echo High level calculations: "$HLstring0"
   if [ $noHLcalc -eq 1 ]; then
      HLcalc=$HLcalc1
   elif [ $noHLcalc -eq 2 ]; then
     level2=$(echo $HLstring | awk '{print $1}')
     HLcalc2=$(echo "$level2" | sed 's@/@ @g;s@u@@g' | awk 'BEGIN{IGNORECASE=1};{if($1=="hf") m="HF";else if($1=="mp2") m="MP2"; else if($1=="ccsd(t)") m="CCSDT";else m="DFT"};END{print m}' )
     HLcalc=$HLcalc2
   fi
###some few constants
   nfrag_th=0.005
}

##Function to run the association complexes 
function exec_assoc {
   if [ ${xyz_exists} -eq 0 ]; then
      echo "Selecting a ${frA}-${frB} structure"
      assocdir=${cwd}/assoc_${frA}_${frB}
      if [ ! -d "$assocdir" ]; then mkdir $assocdir ; fi
###
      n="$(echo $nA $nB | awk '{print $1+$2}')"
      echo $n $nA $dist $distm > rotate.dat
      echo $atom1rot $atom2rot >> rotate.dat
      awk '{if(NF==4) print $0}' ${frA}.xyz >>rotate.dat
      awk '{if(NF==4) print $0}' ${frB}.xyz >>rotate.dat
      rm -rf ${assocdir}/structures
      for i in $(seq 1 $nassoc)
      do
         if [ "$program_opt" = "mopac" ];then
            sed 's/method/'"$method"' charge='$charge' bonds/g' $sharedir/freq_template1 > ${assocdir}/assoc${i}.mop
            rotate.exe <rotate.dat>>${assocdir}/assoc${i}.mop
            sed 's/method/'"$method"' charge='$charge'/g' $sharedir/freq_template2 >>${assocdir}/assoc${i}.mop
         elif [ "$program_opt" = "qcore" ];then
            echo $n >  ${assocdir}/assoc${i}.xyz
            echo '' >> ${assocdir}/assoc${i}.xyz
            rotate.exe <rotate.dat>>${assocdir}/assoc${i}.xyz
            sed 's@min@'${assocdir}'/assoc'${i}'@;s@carga@'$charge'@' ${sharedir}/opt > ${assocdir}/assoc${i}.qcore
         fi
         echo $n >> ${assocdir}/structures
         echo '' >> ${assocdir}/structures
         rotate.exe <rotate.dat>>${assocdir}/structures
      done
      inter=0
      echo "Running $nassoc optimizations"
      doparallel "runAS.sh {1} $assocdir $program_opt" "$(seq 1 $nassoc)"
      echo "Screening the structures"
      screening_assoc.sh $inputfile
      rm -rf black_list* rotate.* tmp_*
      if [ ! -f ${molecule}.xyz ]; then
         echo "A structure for the ${frA}-${frB} complex could not be found"
         exit 1
      fi
   else
      echo "${frA}-${frB} structure detected in the working directory"
   fi
###for association stop here
   if [ $sampling -eq 30 ]; then
      echo ""
      echo "END OF THE CALCULATIONS"
      echo "Check your ${frA}-${frB} structure in file ${molecule}.xyz"
      echo ""
      exit
   fi
}

function keywords_check {
###molecule keyword must be always present
   if [ -z $molecule ]; then
      echo " Your molecule keyword is missing in the input file"
      exit 1
   fi
##Kinetics section (except for association) and frA frB checks (association and vdw)
   if [ $sampling -ne 30 ]; then
      if [ $rate -eq -1 ]; then echo "Please provide a value for keywords Energy or Temperature in the Kinetics section"; exit; fi
      if [ $rate -eq 1 ] && [ $energy -eq 0  ] ; then
            echo "Please provide a value for the Energy"
            exit 1
      fi
   fi
   if [ $sampling -ge 30 ]; then
      if [ -z $frA ]; then
         echo keyword fragmentA is mandatory with association sampling
         exit 1
      fi
      if [ -z $frB ]; then
         echo keyword fragmentB is mandatory with association sampling
         exit 1 
      fi
   fi
###warning
###Incompatibilities of Entos Qcore
   if [ "$program_opt" = "qcore" ] && [ $sampling -eq 1 ]; then
      echo MD-micro has not been implemented for qcore 
      exit 1
   fi
   if [ "$program_opt" = "qcore" ] && [ $sampling -eq 3 ]; then
      echo ChemKnow has not been implemented for qcore 
      exit 1
   fi
}

function hl_print {
##check qcore is installed
if [ "$program_hl" = "qcore" ];then
   if ! command -v qcore &> /dev/null
   then
      echo ""
      echo "Entos Qcore does not seem to be installed"
      echo "Aborting..."
      exit
   fi
###check g09 is installed
elif [ "$program_hl" = "g09" ];then
   if ! command -v g09 &> /dev/null
   then
      echo ""
      echo "g09 does not seem to be installed"
      echo "Aborting..."
      exit
   fi
elif [ "$program_hl" = "g16" ];then
   if ! command -v g16 &> /dev/null
   then
      echo ""
      echo "g16 does not seem to be installed"
      echo "Aborting..."
      exit
   fi
fi

echo ""
echo "GENERAL    "
echo "Name of the system    =" $molecule
echo "Charge                =" $charge
echo "Multiplicity          =" $mult 
echo "High-level method     =" "$HLstring0"
echo "Number of IRC pts     =" $IRCpoints
echo ""
}


function xyzfiles_check  {
echo "GENERAL    "
echo "Name of the system    =" $molecule
echo "Charge                =" $charge
if [ $sampling -lt 30 ]; then
##check that xyz file is present
   if [ ! -f ${molecule}.xyz ]; then
      echo "${molecule}.xyz file does not exist"
      xyz_exists=0
      exit 1
   else
      xyz_exists=1
##remove second line if it exists
      awk 'NR==1{natom=$1;print natom"\n";getline
           for(i=1;i<=natom;i++) {getline; print $1,$2,$3,$4} }' ${molecule}.xyz > tmp && mv tmp ${molecule}.xyz 
##create reference distances : cov
   fi
else
   if [ ! -f ${frA}.xyz ]; then
      echo $frA".xyz does not exist"
      exit 1
   else
##remove second line if it exists
      awk 'NR==1{natom=$1;print natom"\n";getline
           for(i=1;i<=natom;i++) {getline; print $1,$2,$3,$4} }' ${frA}.xyz > tmp && mv tmp ${frA}.xyz 
  fi
   if [ ! -f ${frB}.xyz ]; then
      echo $frB".xyz does not exist"
      exit 1
   else
##remove second line if it exists
      awk 'NR==1{natom=$1;print natom"\n";getline
           for(i=1;i<=natom;i++) {getline; print $1,$2,$3,$4} }' ${frB}.xyz > tmp && mv tmp ${frB}.xyz 
   fi
   if [ -f ${molecule}.xyz ]; then
      xyz_exists=1
      xyzfile=${molecule}
      natom=$(awk 'NR==1{print $1}' ${molecule}.xyz)
   else
      xyz_exists=0
      cat ${frA}.xyz ${frB}.xyz | awk '{if(NF==4) print $0}' > tmp_ABe 
      natom=$(wc -l tmp_ABe | awk '{print $1}' )
      echo $natom > tmp_AB.xyz
      echo "" >> tmp_AB.xyz
      cat tmp_ABe >> tmp_AB.xyz
      xyzfile=tmp_AB
   fi
##check_vdw_atoms
   ok=$(check_vdw_atoms.py $xyzfile)
   if [ $ok -eq 0 ];then
      echo Some of the atoms in your structure cannot be treated with this sampling
      exit
   fi
fi
echo "Number of atoms       =" $natom
met=$(echo $method | sed 's/threads=1//')
if [ $md -ge 0 ]; then
   echo "Low-level MD simul.   = $program_md" $met
fi
if [ $sampling -ne 30 ]; then
   if [ "$program_opt" != "g09" ] && [ "$program_opt" != "g16" ]; then
      echo "Low-level TS optim.   =" $program_opt $met
   else
      echo "Low-level TS optim.   =" $program_opt "$method_opt"
   fi
else
   echo "Low-level A-B optim.  = $program_md" $met
fi
}

function generate_dynamics_template {
deltat=1
dnc=2
ncycles=$(echo "scale=0; $dnc*$nfs" | bc)
##template for MD simulations
dynamics_template="$(cat $sharedir/dynamics_template)"
##This is stuff for biased dynamics*********************************
if [ ! -z $factorflipv ]; then
   echo "MD constraint: a factor of $factorflipv is employed to flip velocities"
   tmp0="$(echo "$dynamics_template" | sed 's/itry=100/itry=100 debug vflip='$factorflipv'/')"
   dynamics_template="$tmp0"
fi
if [ $nbondsfrozen -gt 0 ]; then
   echo "MD constraint: $nbondsfrozen bonds are constrained using AXD"
   tmp0="$(echo "$dynamics_template" | sed 's/itry=100/itry=100 debug nbondsfrozen='$nbondsfrozen'/')"
   dynamics_template="$tmp0"
fi
if [ $nbondsbreak -gt 0 ] && [ $mdc -ge 1 ]; then
   echo "MD constraint: a force is applied to $nbondsbreak bonds to promote their breakage"
   tmp1="$(echo "$dynamics_template" | sed 's/itry=100/itry=100 debug nbondsbreak_ase='$nbondsbreak'/')"
   dynamics_template="$tmp1"
fi
if [ $nbondsform -gt 0 ] && [ $mdc -ge 1 ]; then
   echo "MD constraint: a force is applied to $nbondsform pairs of atoms to promote bond formation"
   tmp2="$(echo "$dynamics_template" | sed 's/itry=100/itry=100 debug nbondsform_ase='$nbondsform'/')"
   dynamics_template="$tmp2"
fi
echo ""
dytem0="$(echo "$dynamics_template" | sed 's/method/'"$method"' charge='$charge'/g')"
dytem1="$(echo "$dytem0" | sed 's/ncycles/'$ncycles'/;s/deltat/'$deltat'/')"
}

function sampling_calcs {
if [ $md -eq 1 ]; then
###Energy can be a single value or a range of values
   erange="$(awk '{if($1=="etraj") {for(i=2;i<=NF;i++) printf "%s ",$i}}'  $inputfile | sed 's/-/ /')"
   nf="$(echo "$erange" | awk '{print NF}')"
   if [ $nf -eq 1 ]; then
      excite="$(echo $erange | awk '{print $1}')"
   elif [ $nf -eq 2 ]; then
      data="$(echo "$erange" | awk 'BEGIN{steps=3;srand('$srandseed');n=steps+1;rn=int(n*rand())}
      {le=$1;he=$2;range=he-le}
      END{
      delta=range/steps
      printf "%8.2f %8.0f",le+rn*delta,rn
      }')" 
      excite=$(echo "$data" | awk '{printf "%8.2f",$1}' )
      irange=$(echo "$data" | awk '{rn=$2};END{print 20-rn*2}' )
      irangeo2=$(echo "scale=0; $irange/2" | bc )
   elif [ $nf -eq 0 ]; then
      s=$(echo "3*$natom-6" | bc )
      emin0=$(echo "16.25*($s-1)" | bc -l | awk '{e=$1;if(e>400) e=400;printf "%8.2f",e}')
      emax0=$(echo "46.25*($s-1)" | bc -l | awk '{e=$1;if(e>1200) e=1200;printf "%8.2f",e}')
      data="$(echo $emin0 $emax0 | awk 'BEGIN{steps=3;srand('$srandseed');n=steps+1;rn=int(n*rand())}
      {le=$1;he=$2;range=he-le}
      END{
      delta=range/steps
      printf "%8.2f %8.0f",le+rn*delta,rn
      }')" 
      excite=$(echo "$data" | awk '{printf "%8.2f",$1}' )
      irange=$(echo "$data" | awk '{rn=$2};END{print 20-rn*2}' )
      irangeo2=$(echo "scale=0; $irange/2" | bc )
   else
      echo "Check the value of etraj"
      exit
   fi
###
   if [ -z "$excite" ]; then
      echo "Please provide an energy for the trajectories using keyword etraj"
      exit
   fi 
   lstnm=$(awk 'BEGIN{lstnm=0};{if($1=="modes" && NF==3) {lstnm=$3}};END{print lstnm}' $inputfile )
   nlms=$(awk 'BEGIN{modes=0};{if($1=="modes" && $2!="all") modes=$2;if($1=="modes" && $2=="all") modes=0};END{print modes}' $inputfile )
   seed=$(awk 'BEGIN{seed=0};/seed/{seed=$2};END{print seed}' $inputfile )
elif [ $md -eq 2 ]; then
   lstnm=$(awk 'BEGIN{lstnm=0};{if($1=="atoms" && NF==3) {lstnm=$3}};END{print lstnm}' $inputfile )
   thmass=$(awk 'BEGIN{thmass=0};{if($1=="thmass") {thmass=$2}};END{print thmass}' $inputfile )
   nlms=$(awk 'BEGIN{atoms=0};{if($1=="atoms" && $2!="all") atoms=$2;if($1=="atoms" && $2=="all") atoms=0};END{print atoms}' $inputfile )

   awk '{print $0}
   END{
   print "100"
   print '$nlms'
   if('$nlms'>0) print '$lstnm'
   print '$thmass'
   }' ${molecule}.xyz | termo.exe > /dev/null

   natefin=$(awk '/Number of atoms to be excited/{print $NF}' fort.66)
   rm -rf fort.66
   trange="$(awk '{if($1=="temp") {for(i=2;i<=NF;i++) printf "%s ",$i}}'  $inputfile | sed 's/-/ /')"
   nf="$(echo "$trange" | awk '{print NF}')"
   if [ $nf -eq 1 ]; then
      excite="$(echo $trange | awk '{print $1}')"
   elif [ $nf -eq 2 ]; then
      data="$(echo "$trange" | awk 'BEGIN{steps=3;srand('$srandseed');n=steps+1;rn=int(n*rand())}
      {le=$1;he=$2;range=he-le}
      END{
      delta=range/steps
      printf "%8.2f %8.0f",le+rn*delta,rn
      }')"
      excite=$(echo "$data" | awk '{printf "%8.2f",$1}' )
      irange=$(echo "$data" | awk '{rn=$2};END{print 20-rn*2}' )
      irangeo2=$(echo "scale=0; $irange/2" | bc )
   elif [ $nf -eq 0 ]; then
      s=$(echo "3*$natom-6" | bc )
      emin0=$(echo "16.25*($s-1)" | bc -l | awk '{e=$1;if(e>400) e=400;printf "%8.2f",e}')
      emax0=$(echo "46.25*($s-1)" | bc -l | awk '{e=$1;if(e>1200) e=1200;printf "%8.2f",e}')
      tmin0=$(echo "335.51*$emin0/$natefin" | bc -l | awk '{printf "%8.2f",$1}')
      tmax0=$(echo "335.51*$emax0/$natefin" | bc -l | awk '{printf "%8.2f",$1}')
      data="$(echo $tmin0 $tmax0 | awk 'BEGIN{steps=3;srand('$srandseed');n=steps+1;rn=int(n*rand())}
      {le=$1;he=$2;range=he-le}
      END{
      delta=range/steps
      printf "%8.2f %8.0f",le+rn*delta,rn
      }')"
      excite=$(echo "$data" | awk '{printf "%8.2f",$1}' )
      irange=$(echo "$data" | awk '{rn=$2};END{print 20-rn*2}' )
      irangeo2=$(echo "scale=0; $irange/2" | bc )
   else
      echo "Check the value of temp"
      exit
   fi
   if [ -z "$excite" ]; then
      echo "Please provide a temperature for the trajectories using keyword temp"
      exit
   fi 
fi
}

function print_method_screening {
echo ""
echo "METHOD     "
if [ $sampling -eq 0 ]; then
   echo "BXDE sampling" 
   if [ $postp_alg -eq 1 ];then
      printf "BBFS algorithm details:\nTime window (fs)      = $irange \nAttempts/single path  = $nppp \n" 
   elif [ $postp_alg -eq 2 ];then
      printf "BOTS algorithm details:\nCutoff freq (cm-1)    = $cutoff \nNumber of std devs.   = $stdf \n" 
   fi
elif [ $sampling -eq 1 ]; then
   echo "MD-micro sampling" 
   if [ $amkscript -eq 1 ]; then
      printf "BBFS algorithm details:\nTime window (fs)      = $irange \nAttempts/single path  = $nppp \n" 
   else
      printf "BBFS algorithm details:\nAttempts/single path  = $nppp \n" 
   fi
   eprint="$(awk '{if($1=="etraj") {for(i=2;i<=NF;i++) printf "%s ",$i}}'  $inputfile)"
   if [ -z "$eprint" ];then
      eprint="Automatically selected"
   fi
   if [ $nlms -gt 0 ]; then
      echo "# of modes excited    =" $nlms 
      echo "Modes excited:" $lstnm 
   else
      echo "All normal modes are excited "
   fi
   if [ $amkscript -eq 1 ]; then
      echo "Energy (kcal/mol)     =" $excite 
   else
      echo "Energy (kcal/mol)     =" $eprint
   fi
elif [ $sampling -eq 2 ] || [ $sampling -eq 3 ]; then
   if [ $sampling -eq 2 ]; then
      echo "MD sampling" 
   elif [ $sampling -eq 3 ]; then
      echo "ChemKnow sampling" 
   fi
   if [ $amkscript -eq 1 ]; then
      printf "BBFS algorithm details:\nTime window (fs)      = $irange \nAttempts/single path  = $nppp \n" 
   else
      printf "BBFS algorithm details:\nAttempts/single path  = $nppp \n" 
   fi
   tprint="$(awk '{if($1=="temp") {for(i=2;i<=NF;i++) printf "%s ",$i}}'  $inputfile)"
   if [ -z "$tprint" ];then
      tprint="Automatically selected"
   fi
   if [ $nlms -gt 0 ]; then
      echo "# of atoms excited    =" $nlms 
      echo "Atoms excited:" $lstnm 
      echo "Atoms with masses greater than" $thmass "will receive kinetic energy"
   else
      echo "All atoms are excited "
   fi
   if [ $amkscript -eq 1 ]; then
      echo "Temperature (K)       =" $excite 
   else
      echo "Temperature (K)       =" $tprint
   fi
elif [ $sampling -eq 30 ]; then
   echo "Association sampling"
   echo ""
elif [ $sampling -eq 31 ]; then
   echo "vdW sampling"
   if [ $postp_alg -eq 1 ];then
      printf "BBFS algorithm details:\nTime window (fs)      = $irange \nAttempts/single path  = $nppp \n" 
   elif [ $postp_alg -eq 2 ];then
      printf "BOTS algorithm details:\nCutoff freq (cm-1)    = $cutoff \nNumber of std devs.   = $stdf \n" 
   fi
elif [ $sampling -eq 4 ]; then
   echo "external sampling"
   if [ $postp_alg -eq 1 ];then
      printf "BBFS algorithm details:\nTime window (fs)      = $irange \nAttempts/single path  = $nppp \n" 
   elif [ $postp_alg -eq 2 ];then
      printf "BOTS algorithm details:\nCutoff freq (cm-1)    = $cutoff \nNumber of std devs.   = $stdf \n" 
   fi
   echo ""
else
   echo "No sampling provided. Please check your inputfile"
   echo ""
   exit
fi
if [ $md -ge 0 ]; then
   echo "Number of trajs       =" $itrajn
## BXDE with its own totaltime
   if [ $md -ne 0 ]; then
      echo "Total time (fs)       =" $nfs
   else
      if [ $use_nfs -eq 0 ]; then
         echo "Total time (fs)       = 5000" 
      else
         echo "Total time (fs)       =" $nfs
      fi
   fi
fi
echo ""
echo "SCREENING   "
if [ $postp_alg -ge 1 ]; then
   echo "Min imag freq (cm-1)  =" $imag
   echo "Max energy (kcal/mol) =" $emaxts
   if [ ! -d "$tsdirll" ]; then
      mkdir $tsdirll 2>tmp_err
      if [ -s tmp_err ]; then
         echo "check the path of tsdirll folder"
         exit
      else
         rm -rf tmp_err
      fi
      mkdir ${tsdirll}/LOW_IMAG_TSs
   fi
fi
echo "Max value of MAPE     =" $avgerr
echo "Max value of BAPE     =" $bigerr
echo ""
}

function frag_check {
   createMat.py ${molecule}.xyz 1 $nA
###
   ndis=$(echo "1 $natom" | cat - ConnMat | sprint.exe | awk '/Results for the Laplacian/{getline; nconn=0
   for(i=6;i<=NF;i++) if($i<='${nfrag_th}') {++nconn} ; print nconn}' )
   if [ $ndis -gt 1 ]; then
      echo ""
      echo "========================================================================"
      echo "Warning:                                                                "
      echo "Your input structure (file ${molecule}.xyz) contains $ndis fragments    "
      echo "The Kinetics results (if available) are meaningless                     "
      echo "========================================================================"
   fi
}

function make_temp_folders {
rm -rf partial_opt  && mkdir partial_opt
rm -rf ts_opt   && mkdir ts_opt
if [ $sampling -ne 4 ]; then
   rm -rf coordir && mkdir coordir
fi
}

function opt_start {
echo "Optimizing the starting structure"
if [ ! -f ${molecule}_freq.out ]; then
   if [ "$program_md" = "mopac" ]; then
      echo "$min_template"                    > ${molecule}_freq.mop
      awk  'NF==4{print $0}' ${molecule}.xyz >> ${molecule}_freq.mop
      if [ $md -eq 1 ]; then
         echo "In MD-micro, a frequency calculation is performed as well"
         echo "$freq_template" >> ${molecule}_freq.mop
      fi
      mopac ${molecule}_freq.mop 2>/dev/null
###Check the optimization
      geo_min=$(get_geom_mopac.sh ${molecule}_freq.out)
      if [ "$geo_min" = "Error" ];then
         echo "The input structure could not be optimized. Check your XYZ file"
         exit
      else
         echo "$geo_min"  > opt_start.xyz
      fi
   elif [ "$program_md" = "qcore" ]; then
      cp ${molecule}.xyz min.xyz
      sed 's/carga/'$charge'/' $sharedir/opt > ${molecule}_freq.dat
      entos.py ${molecule}_freq.dat > ${molecule}_freq.out
      geo_min=$(awk '/Error/{print "Error"}' ${molecule}_freq.out)
      if [ "$geo_min" = "Error" ]; then
         echo "The input structure could not be optimized. Check your XYZ file"
         exit
      else
         awk 'NR!=2{print $0};NR==2{print ""}' min_opt.xyz> opt_start.xyz
         cat opt_start.xyz >> ${molecule}_freq.out
      fi
   elif [ "$program_md" = "xtb" ]; then
      cp react.xyz opt_start.xyz
   fi
   cp opt_start.xyz ${molecule}.xyz
fi
##Obtain e0 and emaxts
#if [ $postp_alg -ge 1 ]; then
###########min0 is the reference minimum. If it exists, take its energy
if [ -f $tsdirll/MINs/min.db ]; then
   if [ "$program_opt" = "mopac" ] || [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ] ; then
      e0=$(sqlite3 ${tsdirll}/MINs/min.db "select energy from min where name='min0_0'")
   elif [ "$program_opt" = "qcore" ]; then
      e0=$(sqlite3 ${tsdirll}/MINs/min.db "select energy from min where name='min0_0'")
      e0=$(echo "scale=6; $e0/627.51" | bc | awk '{printf "%14.6f",$1}')
   elif [ "$program_opt" = "xtb" ]; then
      e0=$(sqlite3 ${tsdirll}/MINs/min.db "select energy from min where name='min0_0'")
      e0=$(echo "scale=6; $e0*23.06" | bc | awk '{printf "%14.6f",$1}')
   fi 
else
   if [ "$program_opt" = "mopac" ]; then
      e0=$(awk '/FINAL HEAT OF FORMATION =/{e0=$6};END{print e0}' ${molecule}_freq.out )
   elif [ "$program_opt" = "qcore" ]; then
      e0=$(awk '/Energy=/{e0=$2};END{print e0}' ${molecule}_freq.out )
      emaxts=$(echo "scale=6; $emaxts/627.51" | bc | awk '{printf "%14.6f",$1}')
   elif [ "$program_opt" = "xtb" ]; then
      e0=$(awk '/Energy=/{e0=$2};END{print e0}' ${molecule}_freq.out )
      emaxts=$(echo "scale=6; $emaxts*23.06" | bc | awk '{printf "%14.6f",$1}')
   elif [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ] ; then
###if LL program is gaussian, perform frequency with gaussian to get e0
      nameg=${molecule}_freq_gauss
      chkfile=$nameg
      calc=min
      geo="$(awk 'NF==4{print $0};END{print ""}' ${molecule}.xyz)"
      level=ll
      g09_input
      echo -e "$inp_hl\n\n" > ${nameg}.dat
      if [ "$program_opt" = "g09" ]; then  
         g09 <${nameg}.dat >${nameg}.log
      elif [ "$program_opt" = "g16" ]; then  
         g16 <${nameg}.dat >${nameg}.log
      fi
      ok=$(awk 'BEGIN{ok=0};/Frequencies/{++nfreq;if($3>0 && $4>0 && nfreq==1) ok=1};END{print ok}' ${nameg}.log)
      if [ $ok -eq 0 ];then
         echo "The input structure could not been optimized with gaussian. Check your XYZ file"
         exit
      fi
      e0=$(get_energy_g09_${LLcalc}.sh ${nameg}.log 1)
      emaxts=$(echo "scale=6; $emaxts/627.51" | bc | awk '{printf "%14.6f",$1}')
   fi
fi
###########3
   emaxts=$(echo "scale=6; $emaxts+$e0" | bc | awk '{printf "%14.6f",$1}')
#fi
}

function define_inputfile {
if [ ! -f $inputfile ]; then
   echo "The file $inputfile does not exist"
   exit
fi
if [ "$inputfile" == "amk.dat" ]; then
   echo ""
   echo "READING amk.dat"
   echo ""
else
   echo ""
   echo "READING $inputfile"
   echo ""
   ln -sf $inputfile amk.dat
fi
}
function amk_parallel_check {
if [ $md -lt 0 ]; then
   echo "  =================================================================="
   echo "   $exe can only be employed for samplings involving MD:          "
   echo "                   MD, MD-micro and BXDE                          "
   echo "  =================================================================="
   exit 1
fi
}

function amk_parallel_setup {
if [ ! -f ${molecule}_ref.xyz ]; then cp ${molecule}.xyz ${molecule}_ref.xyz ; fi
###
if [ -f $kmcfilell ] && [ -f $minfilell ] && [ $mdc -ge 1 ]; then
   awk '{if($1!="temp") print $0}' $inputfile > tmp && mv tmp $inputfile
fi
###Create tsdirll folder
#if [ ! -d "$tsdirll" ]; then mkdir $tsdirll ; fi
###
sqlite3 ${tsdirll}/track.db "create table if not exists track (id INTEGER PRIMARY KEY,nts  INTEGER, noj1 INTEGER, nojf INTEGER, ntraj INTEGER, emin REAL, emax REAL, permin INTEGER, permax INTEGER);"
if [ $md -eq 0 ]; then
   et="temperatures"
   uet="K"
   flag="temp"
elif [ $md -eq 1 ]; then
   et="energies"
   uet="kcal/mol"
   flag="etraj"
else
   et="temperatures"
   uet="K"
   flag="temp"
fi
erange="$(awk '{if($1=="'$flag'") {for(i=2;i<=NF;i++) printf "%s ",$i}}'  $inputfile | sed 's/-/ /')"
nf="$(echo "$erange" | awk '{print NF}')"
echo ""
if [ $nf -eq 1 ]; then
   emin0="$(echo $erange | awk '{printf "%8.2f",$1}')"
   emax0="$(echo $erange | awk '{printf "%8.2f",$1}')"
elif [ $nf -eq 2 ]; then
   emin0="$(echo $erange | awk '{printf "%8.2f",$1}')"
   emax0="$(echo $erange | awk '{printf "%8.2f",$2}')"
elif [ $nf -eq 0 ]; then
   s=$(echo "3*$natom-6" | bc )
   emin0=$(echo "16.25*($s-1)" | bc -l | awk '{e=$1;if(e>400) e=400;printf "%8.2f",e}')
   emax0=$(echo "46.25*($s-1)" | bc -l | awk '{e=$1;if(e>1200) e=1200;printf "%8.2f",e}')
   if [ $md -eq 2 ]; then
      lstnm=$(awk 'BEGIN{lstnm=0};{if($1=="atoms" && NF==3) {lstnm=$3}};END{print lstnm}' $inputfile )
      thmass=$(awk 'BEGIN{thmass=0};{if($1=="thmass") {thmass=$2}};END{print thmass}' $inputfile )
      nlms=$(awk 'BEGIN{atoms=0};{if($1=="atoms" && $2!="all") atoms=$2;if($1=="atoms" && $2=="all") atoms=0};END{print atoms}' $inputfile )
      awk '{print $0}
      END{
      print "100"
      print '$nlms'
      if('$nlms'>0) print '$lstnm'
      print '$thmass'
      }' ${molecule}.xyz | termo.exe > /dev/null

      natefin=$(awk '/Number of atoms to be excited/{print $NF}' fort.66)
      rm -rf fort.66
      emin0=$(echo "335.51*$emin0/$natefin" | bc -l | awk '{printf "%8.2f",$1}')
      emax0=$(echo "335.51*$emax0/$natefin" | bc -l | awk '{printf "%8.2f",$1}')
   fi
else
   echo Check the value of $flag in $inputfile
   exit 1
fi
#set value of factor
id=$(sqlite3 ${tsdirll}/track.db "select max(id) from track" | awk '{print $1+1-1}')
factormin=1
factormax=1
if [ $id -eq 1 ]; then
   permin=$(sqlite3 ${tsdirll}/track.db "select permin from track where id='$id'" | awk '{print $1+1-1}')
   permax=$(sqlite3 ${tsdirll}/track.db "select permax from track where id='$id'" | awk '{print $1+1-1}')
   if [ $permin -gt 60 ]; then
      factormin=0.9
   elif [ $permin -ge 0 ] && [ $permin -le 60 ];then
      factormin=$(echo "10/9" | bc -l)
   fi
   if [ $permax -gt 60 ]; then
      factormax=$(echo "10/9" | bc -l)
   elif [ $permax -ge 0 ] && [ $permax -le 60 ];then
      factormax=0.9
   fi
elif [ $id -gt 1 ]; then
   permin_0=$(sqlite3 ${tsdirll}/track.db "select permin from track where id='$((id-1))'" | awk '{print $1+1-1}')
   permax_0=$(sqlite3 ${tsdirll}/track.db "select permax from track where id='$((id-1))'" | awk '{print $1+1-1}')
   emin_0=$(sqlite3 ${tsdirll}/track.db "select emin from track where id='$((id-1))'" | awk '{print $1+1-1}')
   emax_0=$(sqlite3 ${tsdirll}/track.db "select emax from track where id='$((id-1))'" | awk '{print $1+1-1}')
   permin_1=$(sqlite3 ${tsdirll}/track.db "select permin from track where id='$id'" | awk '{print $1+1-1}')
   permax_1=$(sqlite3 ${tsdirll}/track.db "select permax from track where id='$id'" | awk '{print $1+1-1}')
   emin_1=$(sqlite3 ${tsdirll}/track.db "select emin from track where id='$id'" | awk '{print $1+1-1}')
   emax_1=$(sqlite3 ${tsdirll}/track.db "select emax from track where id='$id'" | awk '{print $1+1-1}')
   if [ $permin_1 -gt 60 ]; then
      factormin=0.9
   elif [ $permin_1 -ge 0 ] && [ $permin_1 -le 60 ];then
      if (( $(echo "$permin_1 > $permin_0" | bc -l) )); then
         factormin=$(echo "$emin_1/$emin_0" | bc -l)
      else
         factormin=$(echo "$emin_0/$emin_1" | bc -l)
      fi
   fi 
   if [ $permax_1 -gt 60 ]; then
      factormax=$(echo "10/9" | bc -l)
   elif [ $permax_1 -ge 0 ] && [ $permax_1 -le 60 ];then
      factormax=0.9
   fi
fi
emin=$(echo "$emin0*$factormin" | bc -l | awk '{printf "%8.2f",$1}')
emax=$(echo "$emax0*$factormax" | bc -l | awk '{printf "%8.2f",$1}')
#faf is employed to avoid emin>emax situations
faf=$(echo "$emax-$emin" | bc -l | awk 'BEGIN{faf=1};{if($1<0) faf=0};END{print faf}')
if [ $faf -eq 0 ]; then
   s=$(echo "3*$natom-6" | bc )
   emin_sug=$(echo "16.25*($s-1)" | bc -l | awk '{e=$1;if(e>400) e=400;printf "%8.2f",e}')
   emax_sug=$(echo "46.25*($s-1)" | bc -l | awk '{e=$1;if(e>1200) e=1200;printf "%8.2f",e}')
   if [ $md -eq 2 ]; then
      emin_sug=$(echo "335.51*$emin_sug/$natom" | bc -l | awk '{printf "%8.2f",$1}')
      emax_sug=$(echo "335.51*$emax_sug/$natom" | bc -l | awk '{printf "%8.2f",$1}')
   fi
   echo You may consider changing the values of $flag in $inputfile
   echo Suggested range of ${et}: ${emin_sug}-${emax_sug}
   emin=$emin0
   emax=$emax0
fi

if [ $md -eq 0 ]; then
   sqlite3 ${tsdirll}/track.db "insert into track (noj1,nojf,emin,emax,permin,permax) values ($noj1,$nojf,$emin,$emax,-1,-1);"
else
   if [ $sampling -ne 3 ]; then  echo Range of ${et}: ${emin}-${emax} ${uet} ; fi
   sqlite3 ${tsdirll}/track.db "insert into track (noj1,nojf,emin,emax,permin,permax) values ($noj1,$nojf,$emin,$emax,-1,-1);"
   tmpinp="$(awk '{if($1=="sampling")
      {print $0
      print "'$flag' erange"}
   else if($1!="'$flag'") print $0}' $inputfile)"
   if [[ "$emin" == "$emax" ]]; then
      if [ $sampling -ne 3 ]; then echo "$tmpinp" | sed 's/erange/'"$emin"'/' >$inputfile ; fi
   else
      if [ $sampling -ne 3 ]; then echo "$tmpinp" | sed 's/erange/'"$emin"'-'"$emax"'/' >$inputfile ; fi
   fi
fi
}

function g09_input {
   chk="$(echo %chk=$chkfile)"
   chkfilef=ircf_$i
   chkfiler=ircr_$i
   chkf="$(echo %chk=$chkfilef)"
   chkr="$(echo %chk=$chkfiler)"
   if [ "$level" = "ll" ] ; then
      levelc=$method_opt
   elif [ "$level" = "hl" ] ; then
      levelc=$level1
   fi
   if [ "$calc" = "ts" ] ; then
      cal="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/tkmc/'$temperature'/;s@calcall,noraman)@calcfc,noraman) freq=noraman@;s@iop@'"$iop"'@;s@level1@'$levelc'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/hl_input_template)"
   elif [ "$calc" = "min" ]; then
      cal="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/ts,noeigentest,//;s/tkmc/'$temperature'/;s@level1@'$levelc'@;s/charge/'$charge'/;s/mult/'$mult'/;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
   elif [ "$calc" = "irc" ]; then
      cp ${tsdirhl}/${i}.chk ${tsdirhl}/IRC/ircf_${i}.chk
      cp ${tsdirhl}/${i}.chk ${tsdirhl}/IRC/ircr_${i}.chk
      #if imag <100 then stepsize=30
      imag=$(awk 'BEGIN{fl=0};/Frequencies/{f0=$3;f=sqrt(f0*f0);if(f<100)fl=1;print fl ;exit}' $tsdirhl/$i.log )
      if [ $imag -eq 1 ] ; then
         echo "ts $i has an imaginary freq lower than 100 cm-1"
         step_irc=30
      else
###EMN WARNING: step_irc=5 has been used to run the glycolonitrile calcs
         #step_irc=10
         step_irc=5
      fi
      if [ $noHLcalc -eq 1 ]; then
         fcc="rcfc"
      elif [ $noHLcalc -eq 2 ]; then
         fcc="calcfc"
      fi
      calf="$(sed  's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s@iop@'"$iop"'@;s/opt=(ts,noeigentest,calcall,noraman)/guess=read geom=check irc=(forward,maxpoints='$IRCpoints','$fcc',recalc=10,stepsize='$step_irc') iop(1\/108=-1)/;s@level1@'$level1'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/hl_input_template_notemp)"
      calr="$(sed  's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s@iop@'"$iop"'@;s/opt=(ts,noeigentest,calcall,noraman)/guess=read geom=check irc=(reverse,maxpoints='$IRCpoints','$fcc',recalc=10,stepsize='$step_irc') iop(1\/108=-1)/;s@level1@'$level1'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/hl_input_template_notemp)"
      inp_hlf="$(echo -e "$chkf"'\n'"$calf"'\n'" "'\n'"$pseudo_end")"
      inp_hlr="$(echo -e "$chkr"'\n'"$calr"'\n'" "'\n'"$pseudo_end")"
      echo -e "insert or ignore into gaussian values (NULL,'ircf_$i','$inp_hlf');\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
      ((m=m+1))
      echo -e "insert or ignore into gaussian values (NULL,'ircr_$i','$inp_hlr');\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
   elif [ "$calc" = "min_irc" ]; then
      if [ -f $tsdirhl"/IRC/"$chkfilef".chk" ]; then
         calmf="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/ts,noeigentest,//;s/tkmc/'$temperature'/;s@level1@'$level1' pop=(mk,nbo) guess=read@;s/charge/'$charge'/;s/mult/'$mult'/;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
      else 
         calmf="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/ts,noeigentest,//;s/tkmc/'$temperature'/;s@level1@'$level1' pop=(mk,nbo)@;s/charge/'$charge'/;s/mult/'$mult'/;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
      fi
      if [ -f $tsdirhl"/IRC/"$chkfiler".chk" ]; then
         calmr="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/ts,noeigentest,//;s/tkmc/'$temperature'/;s@level1@'$level1' pop=(mk,nbo) guess=read@;s/charge/'$charge'/;s/mult/'$mult'/;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
      else 
         calmr="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/ts,noeigentest,//;s/tkmc/'$temperature'/;s@level1@'$level1' pop=(mk,nbo)@;s/charge/'$charge'/;s/mult/'$mult'/;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
      fi
      calsnoiop="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s@level1@'$level1' sp pop=(mk,nbo)@;s/charge/'$charge'/;s/mult/'$mult'/;/opt/,/temp/d' $sharedir/hl_input_template)"
      calsiop="$(sed 's@Mem@'$mem'@;s@pseudo@'$pseudo'@;s/opt=(ts,noeigentest,calcall,noraman)//;s@level1@'$level1' sp pop=(mk,nbo)@;s/charge/'$charge'/;s/mult/'$mult'/;/temp/d;s@iop@'"$iop"'@' $sharedir/hl_input_template)"
      if [ $(nfrag.sh tmp_geomf_$i ${nfrag_th} $nA) -eq 1 ]; then
         calf="$calmf"
      else
         if [ -z "$iop" ]; then
            calf="$calsnoiop"
         else
            calf="$calsiop"
         fi
         if [ ! -z $diss ]; then 
            calfxqc="$(echo "$calf" | sed 's@sp@sp scf=xqc@')"
            calf="$calfxqc"
         fi
      fi

      if [ -z $diss ]; then
         if [ $(nfrag.sh tmp_geomr_$i ${nfrag_th} $nA) -eq 1 ]; then
            calr="$calmr"
         else
            if [ -z "$iop" ]; then
               calr="$calsnoiop"
            else
               calr="$calsiop"
            fi
         fi
      fi

      inp_hlminf="$(echo -e "$chkf"'\n'"$calf"'\n'"$geof"'\n'" "'\n'"$pseudo_end")"
      inp_hlminr="$(echo -e "$chkr"'\n'"$calr"'\n'"$geor"'\n'" "'\n'"$pseudo_end")"

      if [ $noHLcalc -eq 2 ]; then
         spcf="$(sed 's/chk=/chk='$chkfilef'/;s@level2@'$level2'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/sp_template)"
         if [ ! -z $diss ]; then 
            spcfxqc="$(echo "$spcf" | sed 's@guess=read@guess=read scf=xqc@')"
            spcf="$spcfxqc"
         fi
         spcr="$(sed 's/chk=/chk='$chkfiler'/;s@level2@'$level2'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/sp_template)"
         inp_hlminf="$(echo -e "$chkf"'\n'"$calf"'\n'"$geof"'\n\n'"$spcf")"
         inp_hlminr="$(echo -e "$chkr"'\n'"$calr"'\n'"$geor"'\n\n'"$spcr")"
      fi

      if [ -z $diss ] ; then
         echo -e "insert or ignore into gaussian values (NULL,'minf_$i','$inp_hlminf');\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
         echo -e "insert or ignore into gaussian values (NULL,'minr_$i','$inp_hlminr');\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
      else
         echo -e "insert or ignore into gaussian values (NULL,'min_diss_$i','$inp_hlminf');\n.quit" | sqlite3 ${tsdirhl}/IRC/DISS/inputs.db
      fi
   fi
   inp_hl="$(echo -e "$chk"'\n'"$cal"'\n'"$geo"'\n'" "'\n'"$pseudo_end")"
   if [ $noHLcalc -eq 2 ] && [ "$level" = "hl" ]; then
      spc="$(sed 's/chk=/chk='$chkfile'/;s@level2@'$level2'@;s/charge/'$charge'/;s/mult/'$mult'/' $sharedir/sp_template)"
      inp_hl="$(echo -e "$chk"'\n'"$cal"'\n'"$geo"'\n\n'"$spc")"
   fi
}


function qcore_input {
   if [ "$calc" = "min" ] || [ "$calc" = "ts" ]; then
      inp_hl="$(sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/opt${calc}_hl | sed "s/hessianmethod/$hessianmethod/;s/carga/$charge/;s/tag/$chkfile/;s/temp_amk/$temperature/;s/'/''/g")" 
      printf "$natom\n\n$geo" > ${tsdirhl}/${chkfile}.xyz
   elif [ "$calc" = "prod" ]; then
      inp_hl="$(sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/optmin_hl | sed "s/hessianmethod/$hessianmethod/;s/carga/$charge/;s/tag/$chkfile/;s/temp_amk/$temperature/;s/'/''/g")" 
      naf=$(echo "$geo" | wc -l)
      printf "$naf\n\n$geo" > ${tsdirhl}/PRODs/CALC/${chkfile}.xyz
   elif [ "$calc" = "irc" ]; then
      echo -e "insert or ignore into gaussian values (NULL,'$i',NULL);\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
      cp ${tsdirhl}/${i}_opt.xyz ${tsdirhl}/IRC/${i}_grad.xyz
      sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/grad_hl | sed "s/carga/$charge/;s/tag/${i}_grad/"  > ${tsdirhl}/IRC/${i}_grad.dat
   elif [ "$calc" = "min_irc" ]; then
      echo -e "insert or ignore into gaussian values (NULL,'minf_$i',NULL);\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
      echo -e "insert or ignore into gaussian values (NULL,'minr_$i',NULL);\n.quit" | sqlite3 ${tsdirhl}/IRC/inputs.db
      printf "$natom\n\n$geof" > ${tsdirhl}/IRC/minf_${i}.xyz
      printf "$natom\n\n$geor" > ${tsdirhl}/IRC/minr_${i}.xyz
      if [ $(nfrag.sh tmp_geomf_$i ${nfrag_th} $nA) -eq 1 ]; then
         sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/optmin_hl | sed "s/hessianmethod/$hessianmethod/;s/carga/$charge/;s/tag/minf_$i/;s/temp_amk/$temperature/" > ${tsdirhl}/IRC/minf_${i}.dat
      else
         sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/prod_hl | sed "s/carga/$charge/;s/tag/minf_$i/" > ${tsdirhl}/IRC/minf_${i}.dat
      fi

      if [ $(nfrag.sh tmp_geomr_$i ${nfrag_th} $nA) -eq 1 ]; then
         sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/optmin_hl | sed "s/hessianmethod/$hessianmethod/;s/carga/$charge/;s/tag/minr_$i/;s/temp_amk/$temperature/" > ${tsdirhl}/IRC/minr_${i}.dat
      else
         sed -e '/dft/ {' -e 'r qcore_template' -e 'd' -e '}' $sharedir/prod_hl | sed "s/carga/$charge/;s/tag/minr_$i/" > ${tsdirhl}/IRC/minr_${i}.dat
      fi
   fi
}


function check_g09 {
if [ "program_hl" = "g09" ]; then
   if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
     t=$(srun -N 1 -n 1 g09<${sharedir}/g09_test.dat | awk 'BEGIN{t=0};/Normal ter/{t=1};END{print t}')
   else
     if ! command -v g09 &> /dev/null
     then
       echo ""
       echo "g09 does not seem to be installed"
       echo "Aborting..."
       exit
     fi
     t=$(g09<${sharedir}/g09_test.dat | awk 'BEGIN{t=0};/Normal ter/{t=1};END{print t}')
   fi

   if [ $t -eq 0 ]; then
      echo "Please check that gaussian09 is installed in your computer and it can be invoked as g09"
      exit 1
   fi
elif [ "program_hl" = "g16" ]; then
   if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
     t=$(srun -N 1 -n 1 g16<${sharedir}/g09_test.dat | awk 'BEGIN{t=0};/Normal ter/{t=1};END{print t}')
   else
     if ! command -v g16 &> /dev/null
     then
       echo ""
       echo "g16 does not seem to be installed"
       echo "Aborting..."
       exit
     fi
     t=$(g16<${sharedir}/g16_test.dat | awk 'BEGIN{t=0};/Normal ter/{t=1};END{print t}')
   fi

   if [ $t -eq 0 ]; then
      echo "Please check that gaussian16 is installed in your computer and it can be invoked as g16"
      exit 1
   fi
fi
}

function get_data_hl_output {
if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
   energy=$(get_energy_g09_$HLcalc.sh $tsdirhl/${name}.log $noHLcalc)
   zpe=$(get_ZPE_g09.sh $tsdirhl/${name}.log)
   g=$(get_G_g09.sh $tsdirhl/${name}.log)
   geom="$(get_geom_g09.sh $tsdirhl/${name}.log)"
   freq="$(get_freq_g09.sh $tsdirhl/${name}.log)"
   sigma=$(awk 'BEGIN{IGNORECASE=1};/SYMMETRY NUMBER/{print $NF;exit}' $tsdirhl/${name}.log | sed 's@\.@@' )
elif [ "$program_hl" = "qcore" ];then
   energy=$(awk 'NR==1{print $2}' $tsdirhl/${name}.log)
   zpe=$(awk '/ZPE/{printf "%12.2f",$2*627.51}' $tsdirhl/${name}.log)
   g=$(awk '/Gibbs free energy/{print $4}' $tsdirhl/${name}.log)
   geom="$(awk 'NR>2{print $0}' $tsdirhl/${name}_opt.xyz)"
   freq="$(awk '/Freq/{for(i=1;i<=1000;i++) {getline;if(NF>1) exit;print $1}}' $tsdirhl/${name}.log)"
   sigma=1
fi
}

function get_data_hl_output_mins {
if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ] ;then
   energy=$(get_energy_g09_$HLcalc.sh $i $noHLcalc)
   geom="$(get_geom_g09.sh $i)"
   if [ $name != "min0" ]; then
      zpe=$(get_ZPE_g09.sh $i)
      g=$(get_G_g09.sh $i)
      freq="$(get_freq_g09.sh $i)"
# insert all minima except min0
      sqlite3 ${tsdirhl}/MINs/minhl.db "insert or ignore into minhl (natom,name,energy,zpe,g,geom,freq) values ($natom,'$name',$energy,$zpe,$g,'$geom','$freq');"
   fi
elif [ "$program_hl" = "qcore" ];then
   energy=$(awk 'NR==1{print $2}' $i)
   if [ -f ${tsdirhl}/IRC/${name}_opt.xyz ]; then
      xyz=${tsdirhl}/IRC/${name}_opt.xyz
   else
      xyz=${tsdirhl}/IRC/${name}.xyz
   fi
   geom="$(awk 'NR>2{print $0}' $xyz )"
   if [ $name != "min0" ]; then
      zpe=$(awk '/ZPE/{printf "%12.2f",$2*627.51}' $i)
      g=$(awk '/Gibbs free energy/{print $4}' $i)
      freq="$(awk '/Freq/{for(i=1;i<=1000;i++) {getline;if(NF>1) exit;print $1}}' $i)"
      sqlite3 ${tsdirhl}/MINs/minhl.db "insert or ignore into minhl (natom,name,energy,zpe,g,geom,freq) values ($natom,'$name',$energy,$zpe,$g,'$geom','$freq');"
   fi
fi
}

function set_up_irc_stuff {
if [ ! -d "$tsdirhl/IRC" ]; then
   echo "$tsdirhl/IRC does not exist. It will be created"
   mkdir $tsdirhl/IRC
else
   echo "$tsdirhl/IRC already exists."
fi
if [ ! -d "$tsdirhl/TSs" ]; then
   echo "$tsdirhl/TSs does not exist. It will be created"
   mkdir $tsdirhl/TSs
else
   echo "$tsdirhl/TSs already exists"
fi
#if [ "$program_hl" = "g09" ];then  cp $tsdirhl/ts*.chk $tsdirhl/IRC ; fi
#if [ "$program_hl" = "g16" ];then  cp $tsdirhl/ts*.chk $tsdirhl/IRC ; fi
if [ -f "black_list.dat" ]; then rm black_list.dat; fi
if [ -f "black_list.out" ]; then rm black_list.out; fi
echo "List of disconnected (at least two fragments) TS structures" > $tsdirhl/TSs/tslist_disconnected
echo "Screening" > $tsdirhl/TSs/tslist_screened
}


function screen_ts_hl {
echo ts$number"_out data"> ${tsdirhl}/TSs/${name}_data
echo $natom >mingeom
echo '' >>mingeom
echo "$geom" >> mingeom
createMat.py mingeom 2 $nA
echo "1 $natom" | cat - ConnMat | sprint.exe >sprint.out

paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
deg_form.sh > deg_form.out
##
echo $energy >> ${tsdirhl}/TSs/${name}_data
##
format.sh $name $tsdirhl/TSs $thdiss
ndis=$(awk '{ndis=$1};END{print ndis}' ${tsdirhl}/TSs/${name}_data )
### mv TSs where there is 2 or more fragments already formed
if  [[ ("$ndis" -gt "1") ]]
then
  ((ndi=ndi+1))
  echo "Structure $name removed-->fragmented TS"
  sqlite3 "" "attach '${tsdirhl}/TSs/tshl.db' as tshl; attach '${tsdirhl}/TSs/tshldscnt.db' as tshldscnt;
  insert into tshldscnt (natom,name,energy,zpe,g,geom,freq,number) select natom,name,energy,zpe,g,geom,freq,number from tshl where name='$name';delete from tshl where name='$name';"
fi

cat ${tsdirhl}/TSs/${name}_data >> $tsdirhl/TSs/tslist_screened
}

function screen_min_hl {
echo  $natom > mingeom
echo '' >> mingeom
echo "$geom" >> mingeom
echo "1" $natom > sprint.dat
createMat.py mingeom 3 $nA
cat ConnMat >> sprint.dat
sprint2.exe <sprint.dat >sprint.out

paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
deg_form.sh > deg_form.out
##use absolute energy instead of relative one
echo $energy >> $tsdirhl/MINs/${name}_data
##
format.sh $name $tsdirhl/MINs ${nfrag_th}
ndis=$(awk '{ndis=$1};END{print ndis}' $tsdirhl/MINs/${name}_data )
### mv MINs where there is 2 or more fragments already formed
if  [[ ("$ndis" -gt "1") ]] && [[ $name != "min0" ]]
then
   ((npro=npro+1))
   echo "Products=" $ndis $name
   namepr=PR${npro}_${name}
###remove this later on
   sqlite3 "" "attach '${tsdirhl}/MINs/minhl.db' as minhl; attach '${tsdirhl}/PRODs/prodhl.db' as prodhl; insert into prodhl (natom,name,energy,zpe,g,geom,freq) select natom,'$namepr',energy,zpe,g,geom,freq from minhl where name='$name';delete from minhl where name='$name'"
   echo "PROD" $npro $name.rxyz >> $tsdirhl/PRODs/PRlist
else
   ((nmin=nmin+1))
   echo "min" $nmin "-->" $name.rxyz >> $tsdirhl/MINs/names_of_minima
   echo "min"$nmin "data" >> $tsdirhl/MINs/minlist_screened
   cat $tsdirhl/MINs/${name}_data >> $tsdirhl/MINs/minlist_screened
fi
}

function stats_hl_tss {
rm -rf ${tsdirhl}/TSs/*_data
ntot=$(awk 'END{print NR}' $file)
reduce.sh $tsdirhl/TSs ts
awk '{if($NF==1) print $0}' $tsdirhl/TSs/tslist_screened.red >  $tsdirhl/TSs/tslist_screened.redconn
awk '{if($NF> 1) print $0}' $tsdirhl/TSs/tslist_screened.red >> $tsdirhl/TSs/tslist_disconnected
diffGT.sh $tsdirhl/TSs/tslist_screened.redconn $tsdirhl/TSs ts  $avgerr $bigerr
#remove repeated structures in this dir and also in TSs
if [ -f "black_list.out" ]; then
   for i in $(awk '{print $0}' black_list.out)
   do
     orig=$(awk '{if($2=='$i') {print $1;exit}}' $tsdirhl/TSs/tslist_screened.lowdiffs)
     echo "Structure ts"$i "removed-->redundant with ts$orig"
     sqlite3 "" "attach '${tsdirhl}/TSs/tshl.db' as tshl; attach '${tsdirhl}/TSs/tshlrep.db' as tshlrep;
     insert into tshlrep (natom,name,energy,zpe,g,geom,freq,number) select natom,name,energy,zpe,g,geom,freq,number from tshl where number='$i';delete from tshl where number='$i';"
     ((nrm=nrm+1))
   done
else
   echo "No repetitions"
fi
((nfin=nts-nrm-ndi))
echo "Of the total" $ntot "TSs optimized at the LL, a total of" $nts "have been optimized at the HL"
echo "$nrm removed because of repetitions"
echo "$ndi removed because they are fragmented TSs"
echo "Current number of TSs optimized at the HL=" $nfin

if [ $nfin -eq 0 ]; then
   echo "No TS optimized at the high-level. Check the output files"
   exit
fi
}

function stats_hl_mins {
echo "Total number of minima" $nmin
rm -rf ${tsdirhl}/MINs/*_data
reduce.sh $tsdirhl/MINs min
awk '{if($NF==1) print $0}' $tsdirhl/MINs/minlist_screened.red >  $tsdirhl/MINs/minlist_screened.redconn
awk '{if($NF> 1) print $0}' $tsdirhl/MINs/minlist_screened.red >> $tsdirhl/MINs/minlist_disconnected
diffGT.sh $tsdirhl/MINs/minlist_screened.redconn $tsdirhl/MINs min $avgerr $bigerr
#remove repeated structures in this dir and also in MINs
cp $tsdirhl/MINs/names_of_minima $tsdirhl/MINs/names_of_minima_norep
if [ -f "black_list.out" ]; then
   for i in $(awk '{print $0}' black_list.out)
   do
     echo "Structure min"$i "repeated"
     ((nrm=nrm+1))
     nomnr="$(awk '{if($2 != '$i') print $0}' $tsdirhl/MINs/names_of_minima_norep)"
     echo "$nomnr" > $tsdirhl/MINs/names_of_minima_norep
   done
else
   echo "No repetitions"
fi
###
nn=0
for name in $(awk '{if(NR>1) print $4}' ${tsdirhl}/MINs/names_of_minima_norep)
do
  ((nn=nn+1))
  namenrxyz=$(basename $name .rxyz)
  number=$(awk 'NR=='$nn'+1,NR=='$nn'+1{print $2}'  ${tsdirhl}/MINs/names_of_minima_norep)
  namenr=$(basename min${number}_${name} .rxyz)
##insert data into minnrhl.db from minhl.db
#  cp ${tsdirhl}/MINs/${name} ${tsdirhl}/MINs/norep/min${number}_${name}
##
  sqlite3 "" "attach '${tsdirhl}/MINs/minhl.db' as minhl; attach '${tsdirhl}/MINs/norep/minnrhl.db' as minnrhl; insert into minnrhl (natom,name,energy,zpe,g,geom,freq,sigma) select natom,'$namenr',energy,zpe,g,geom,freq,sigma from minhl where name='$namenrxyz';"
done
###
((nfin=nmin-nrm))
echo $nmin "have been optimized at the HL, of which" $nrm "removed because of repetitions"
echo "Current number of MINs optimized at the HL=" $nfin
}

function check_freq_ts {
if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
   ok=$(awk 'BEGIN{fok=0;ok=0;nt=0};/Frequencies/{++nfreq;if($3<0 && $4>0 && nfreq==1) fok=1};/Normal termi/{++nt};END{if(nt==('$noHLcalc'+1) && fok==1) ok=1; print ok}' $tsdirhl/${name}.log)
elif [ "$program_hl" = "qcore" ]; then
   ok=$(awk 'BEGIN{ok=0};/Freq/{getline;f1=$1;getline;f2=$1;if(f1<0 && f2>0) ok=1};END{print ok}' $tsdirhl/${name}.log)
fi
}

function check_ts {
if [ -f ${tsdirhl}/${name}.log ]; then
   if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
      calc=$(awk 'BEGIN{calc=1;nt=0};/Normal termi/{++nt};/Error termi/{calc=0};END{if(nt==('$noHLcalc'+1)) calc=0;print calc}' $tsdirhl/${name}.log)
   elif [ "$program_hl" = "qcore" ];then
      calc=$(awk 'BEGIN{calc=1;ncheck=0};/Energy=/{if(NF==2) ncheck+=1};/Lowest/{ncheck+=1};/Error/{calc=0};END{if(ncheck==2) calc=0;print calc}' $tsdirhl/${name}.log)
   fi
else
   calc=1
fi
}

function check_freq_min {
if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
# See if it did not crashed and grab geometires
  ok=$(awk 'BEGIN{fok=0;ok=0;nt=0};/Frequencies/{++nfreq;if($3>0 && $4>0 && nfreq==1) fok=1};/Normal termi/{++nt};END{if('$noHLcalc' == nt && fok==1) ok=1; print ok}' $i)
elif [ "$program_hl" = "qcore" ]; then
   ok=$(awk 'BEGIN{ok=0};/Freq/{getline;f1=$1;getline;f2=$1;if(f1>0 && f2>0) ok=1};END{print ok}' $i)
fi
#Force min0 to be ok
if [ $ok -eq 0 ] && [ $name = "min0" ]; then ok=1 ; fi
}

function check_min {
if [ -f $tsdirhl/IRC/minf_$i.log ] && [ -f $tsdirhl/IRC/minr_$i.log ]; then
   if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
      calc1=$(awk 'BEGIN{calc=1;nt=0};/Normal termi/{++nt};/Error termi/{calc=0};END{if(nt=='$noHLcalc') calc=0;print calc}' $tsdirhl/IRC/minf_$i.log)
      calc2=$(awk 'BEGIN{calc=1;nt=0};/Normal termi/{++nt};/Error termi/{calc=0};END{if(nt=='$noHLcalc') calc=0;print calc}' $tsdirhl/IRC/minr_$i.log)
   elif [ "$program_hl" = "qcore" ]; then
      calc1=$(awk 'BEGIN{calc=1};/Energy=/{if(NF==2) calc=0};END{print calc}' $tsdirhl/IRC/minf_$i.log)
      calc2=$(awk 'BEGIN{calc=1};/Energy=/{if(NF==2) calc=0};END{print calc}' $tsdirhl/IRC/minr_$i.log)
   fi
   if [ $calc1 -eq 0 ] && [ $calc2 -eq 0 ]; then
      calc=0
   else
      calc=1
   fi
else
   calc=1
fi
}

function get_geom_irc {
chkfilef=ircf_$i
chkfiler=ircr_$i
if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
   frm1=$(awk 'BEGIN{npt=0};/Pt /{npt=$2};END{print npt}' $tsdirhl/IRC/ircf_$i.log )
   frm2=$(awk 'BEGIN{npt=0};/Pt /{npt=$2};END{print npt}' $tsdirhl/IRC/ircr_$i.log )
   if [ $frm1 -le 2 ] || [ $frm2 -le 2 ]; then
      mode=1
   else
      mode=2
   fi
   if [ $mode -eq 1 ]; then
      get_NM_g09.sh $tsdirhl/$i.log  1 > tmp_geomf_$i
      get_NM_g09.sh $tsdirhl/$i.log -1 > tmp_geomr_$i
   else
      get_geom_irc_g09.sh $tsdirhl/IRC/ircf_$i.log > tmp_geomf_$i
      get_geom_irc_g09.sh $tsdirhl/IRC/ircr_$i.log > tmp_geomr_$i
   fi
elif [ "$program_hl" = "qcore" ]; then
   awk 'NR>2{print $0}' ${tsdirhl}/IRC/${i}_forward_last.xyz > tmp_geomf_$i
   awk 'NR>2{print $0}' ${tsdirhl}/IRC/${i}_reverse_last.xyz > tmp_geomr_$i
fi
geof="$(cat tmp_geomf_$i)"
geor="$(cat tmp_geomr_$i)"
}

function launch_mopac_TS {
   if [ $int_flag -eq 0 ]; then
      echo "$ts_template"                                 > ${name_TS_inp} 
   elif [ $int_flag -eq 1 ]; then
      echo "int $ts_template"                             > ${name_TS_inp} 
   fi
   echo "$geom_TS"                                       >> ${name_TS_inp} 
   echo "$freq_template" | sed 's/oldgeo/oldgeo oldens/' >> ${name_TS_inp} 
   mopac ${name_TS_inp} 2> /dev/null
   #nwmopext=$(basename ${name_TS_inp} .mop)
   file=${name_TS_inp}.out
#If LET DDMIN=0.0, run ts again with these keywords
   if [ $(awk 'BEGIN{f=0};/LET DDMIN=/{f=1};END{print f}' $file) -eq 1 ]; then
      sed -i 's/ts /ts let ddmin=0.0/g' ${name_TS_inp}
      mopac ${name_TS_inp} 2> /dev/null
   fi
#If too many variables, run ts int
   if [ $int_flag -eq 0 ] && [ $(awk 'BEGIN{f=0};/Too many variables/{f=1};END{print f}' $file) -eq 1 ]; then
      sed -i 's/ts /ts int /g' ${name_TS_inp}
      mopac ${name_TS_inp} 2> /dev/null
      add=$(get_ts_properties.sh $file 1 $tight | awk '{if($1>0) print "1"; else print "0"}')
      if [ -f stats_int ]; then
         awk '{print $1+'$add',$2+1;exit}' stats_int > dum_st && mv dum_st stats_int
      else
         echo "$add 1" > stats_int
      fi
   fi
#Numerical problems in bracking lamda, run ts let
   if [ $(awk 'BEGIN{f=0};/NUMERICAL PROBLEMS IN BRACKETING LAMDA/{f=1};/Error/{++f};END{print f}' $file) -eq 2 ] && [ $ts_let -eq 1 ]; then
      sed -i 's/ts /ts let /g' ${name_TS_inp}
      mopac ${name_TS_inp} 2> /dev/null
      add=$(get_ts_properties.sh $file 1 $tight | awk '{if($1>0) print "1"; else print "0"}')
      if [ -f stats_let ]; then
         awk '{print $1+'$add',$2+1;exit}' stats_let > dum_st && mv dum_st stats_let
      else
         echo "$add 1" > stats_let
      fi
   fi
###
}
