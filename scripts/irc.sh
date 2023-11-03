#!/bin/bash

# default sbatch FT2
#SBATCH --output=irc-%j.log
#SBATCH --time=04:00:00
# partition selection

#_remove_this_in_ft_SBATCH -p shared --qos=shared
#SBATCH -c 1 --mem-per-cpu=2048
#SBATCH -n 8

# SBATCH --partition=cola-corta,thinnodes
# SBATCH -c 1
# SBATCH -n 24


#exe=$(basename $0)
# under batchs systems the scripts are copied to a generic script (in slurm slurm_script)

exe="irc.sh"
cwd=$PWD
sharedir=${AMK}/share
source utils.sh
#check the arguments of the script
if [ $# -gt 0 ]; then
   ci=$1
else
   ci="proceed"
fi

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
if [ $ci != "screening" ] && [ $ci != "proceed" ]; then
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   echo "                  Wrong argument                        "
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   echo "To check what screening has done execute this script as:"
   echo "$exe screening"
   echo ""
   echo "To proceed with the irc execute this script as:"
   echo "$exe"
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   exit
fi
###Do screnning before anything else
screening.sh  $inputfile
if [ $ci == "screening" ]; then 
   echo ""
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   echo "    Please check redundant and fragmented structures indicated in screening.log     "
   echo " If they are not what you expected you might change MAPEmax, BAPEmax and/or eigLmax "
   echo "Then, you can carry on with the IRC calculations, run this script without argument  "
   echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
   echo ""
   exit
fi
###read input file
read_input
###
if [ ! -f ${tsdirll}/ts_mopac_failed ] && [ "$program_opt" = "g09" ]; then
   echo "TSs not optimized with mopac" >  ${tsdirll}/ts_mopac_failed
elif [ ! -f ${tsdirll}/ts_mopac_failed ] && [ "$program_opt" = "g16" ]; then
   echo "TSs not optimized with mopac" >  ${tsdirll}/ts_mopac_failed
fi
##
#remove tmp files
tmp_files=(fort.* tmp_geom tmp* bbfs.* *.arc *.mop coordir mopac.out ConnMat deg.out deg_form.out deg* mingeom ScalMat sprint.out $tsdirll/*_mop.mop $tsdirll/*_mop.arc)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

if [ ! -d "$tsdirll/MINs" ]; then
   mkdir $tsdirll/MINs
fi
##create table for min
sqlite3 ${tsdirll}/MINs/min.db "create table if not exists min (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT, sigma INTEGER,unique(name));"
sqlite3 ${tsdirll}/MINs/data.db "create table if not exists data (id INTEGER PRIMARY KEY,name TEXT,datas TEXT,unique(name));"

# First we copy min0 in MIN directory 
echo "Moving min0 to its final location"
if [ -f ${tsdirll}/MINs/min0.out ]; then
   echo "Calcs completed for min0"
else
   name=min0_0
   if [ "$program_opt" != "qcore" ]; then
      echo "$min_template"                       > ${molecule}_freq.mop
      awk 'NR>2{print $0}' ${molecule}_ref.xyz  >> ${molecule}_freq.mop
      mopac ${molecule}_freq.mop 2>/dev/null
      geom="$(get_geom_mopac.sh ${molecule}_freq.out | awk '{if(NF==4) print $0}')"
      sed 's/thermo/thermo('$temperature','$temperature')/;s/method/'"$method"' charge='$charge'/' $sharedir/thermo_template >  $tsdirll/MINs/min0.mop
      echo "$geom"  >> $tsdirll/MINs/min0.mop
      mopac $tsdirll/MINs/min0.mop 2>/dev/null
      e0=$(awk '/HEAT OF FORMATION =/{e=$5};END{print e}' $tsdirll/MINs/min0.out )
      zpe0=$(awk '/          ZERO POINT ENERGY/{zpe=$4};END{print zpe}' $tsdirll/MINs/min0.out )
      g_corr0=$(awk 'BEGIN{t='$temperature'}
         /          ZERO POINT ENERGY/{zpe=$4}
         /CALCULATED THERMODYNAMIC PROPERTIES/{ok=1}
      {if(ok==1 && $1 == '$temperature') {
      getline;getline;getline;getline;
      h=$3/1000;s=$5/1000;print zpe+h-t*s;exit}
      }' $tsdirll/MINs/min0.out )
      freq="$(get_freq_mopac.sh $tsdirll/MINs/min0.out)"
      sigma=$(awk '/SYMMETRY NUMBER/{print $NF;exit}' $tsdirll/MINs/min0.out)
   else
      cp ${molecule}_ref.xyz min.xyz
      sed 's/carga/'$charge'/' $sharedir/opt > ${molecule}_freq.dat
      entos.py ${molecule}_freq.dat > ${molecule}_freq.out
      if [ ! -f "min_opt.xyz" ]; then
         echo Initial structure could not been optimized
         exit 
      fi
      mv min_opt.xyz opt.xyz
      sed 's/temp_amk/'$temperature'/;s/carga/'$charge'/' $sharedir/opt_thermo > $tsdirll/MINs/min0.dat  
      entos.py $tsdirll/MINs/min0.dat > $tsdirll/MINs/min0.out
      mv freq.molden $tsdirll/MINs/min0.molden
      geom="$(awk 'NR>2{print $0}' opt.xyz)"
      e0=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/MINs/min0.out )
      zpe0=$(awk '/ZPE/{zpe=$2};END{print zpe*627.51}' $tsdirll/MINs/min0.out )
      g_corr0=$(awk '/Gibbs/{gibbs=$NF};END{print gibbs*627.51}' $tsdirll/MINs/min0.out )
      freq="$(awk '/Freq/{flag=1;next}/Lowest/{flag=0}flag' $tsdirll/MINs/min0.out)"
      sigma=1
   fi
   echo $natom > mingeom
   echo "" >> mingeom
   echo "$geom" >> mingeom
   createMat.py mingeom 3 $nA
   echo "1" $natom | cat - ConnMat |  sprint2.exe >sprint.out
   paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
   deg_form.sh > deg_form.out
   echo $e0 > ${tsdirll}/MINs/${name}_data
   format.sh $name ${tsdirll}/MINs ${nfrag_th}
   datas="$(cat ${tsdirll}/MINs/${name}_data)"
   sqlite3 ${tsdirll}/MINs/data.db "insert into data (name,datas) values ('$name','$datas');"
   sqlite3 ${tsdirll}/MINs/min.db "insert into min (natom,name,energy,zpe,g,geom,freq,sigma) values ($natom,'$name',$e0,$zpe0,$g_corr0,'$geom','$freq',$sigma);"
fi
# Now we do things specific of IRC 
if [ ! -d "$tsdirll/IRC" ]; then mkdir $tsdirll/IRC ; fi
if [ ! -d "$tsdirll/TSs" ]; then mkdir $tsdirll/TSs ; fi
m=0
sqlite3 ${tsdirll}/inputs.db "drop table if exists mopac; create table mopac (id INTEGER PRIMARY KEY,name TEXT, unique(name));"
for name in $(awk '{print $3}' $tslistll)
do
  if [ -f $tsdirll/TSs/${name}_thermo.out ] && [ -f $tsdirll/IRC/${name}_ircf.out ] && [ -f $tsdirll/IRC/${name}_ircr.out ]; then
     calc1=$(awk 'BEGIN{calc=1};/DONE ==/{calc=0};END{print calc}' $tsdirll/TSs/${name}_thermo.out)
     calc2=$(awk 'BEGIN{calc=1};/DONE ==/{calc=0};END{print calc}' $tsdirll/IRC/${name}_ircf.out)
     calc3=$(awk 'BEGIN{calc=1};/DONE ==/{calc=0};END{print calc}' $tsdirll/IRC/${name}_ircr.out)
     if [ $calc1 -eq 0 ] && [ $calc2 -eq 0 ] && [ $calc3 -eq 0 ]; then
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
     if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
        skip=$(awk 'BEGIN{skip=0};/'$name'/{skip=1};END{print skip}' ${tsdirll}/ts_mopac_failed)
        if [ $skip == 1 ]; then
           echo "TS $name has ben previously discarded-->(skip because mopac cannot optimize it)"
           continue
        else
           geom_TS="$(get_geom_g09.sh ${tsdirll}/${name}.out)"
           name_TS_inp=${tsdirll}/${name}_mop
           int_flag=0
           launch_mopac_TS
           fe="$(get_ts_properties.sh ${tsdirll}/${name}_mop.out 1 $tight)"
           fx="$(echo "$fe" | awk '{printf "%10.0f",$1}')"
           if [[ ("$fx" -gt "0") ]]; then
              get_geom_mopac.sh ${tsdirll}/${name}_mop.out | awk '{if(NF==4) print $0}' > tmp_geom
           else
              echo ${name}  >> ${tsdirll}/ts_mopac_failed
              rm ${tsdirll}/${name}_mop.out
              continue
           fi
        fi
     elif [ "$program_opt" = "qcore" ]; then
        echo $natom > $tsdirll/TSs/${name}_opt.xyz
        echo $natom > $tsdirll/IRC/${name}_opt.xyz
        echo "" >> $tsdirll/TSs/${name}_opt.xyz
        echo "" >> $tsdirll/IRC/${name}_opt.xyz
        awk '/Final structure/{flag=1; next} EOF{flag=0} flag' $tsdirll/${name}.out >> $tsdirll/TSs/${name}_opt.xyz 
        awk '/Final structure/{flag=1; next} EOF{flag=0} flag' $tsdirll/${name}.out >> $tsdirll/IRC/${name}_opt.xyz 
     else
        get_geom_mopac.sh $tsdirll/${name}.out | awk '{if(NF==4) print $0}' > tmp_geom
     fi
     ((m=m+1))
     if [ "$program_opt" != "qcore" ];then
        #thermo
        sed 's/thermo/thermo('$temperature','$temperature')/;s/method/'"$method"' charge='$charge' oldens/' $sharedir/thermo_template > $tsdirll/TSs/${name}_thermo.mop
        cat tmp_geom >> $tsdirll/TSs/${name}_thermo.mop 
        #IRC
        sed 's/method/'"$method"' charge='$charge' irc= 1 oldens/g' $sharedir/freq_template1 > $tsdirll/IRC/${name}_ircf.mop
        sed 's/method/'"$method"' charge='$charge' irc=-1 oldens/g' $sharedir/freq_template1 > $tsdirll/IRC/${name}_ircr.mop
        if [ -f ${tsdirll}/${name}.den ]; then
           cp ${tsdirll}/${name}.den ${tsdirll}/IRC/${name}_ircf.den
           cp ${tsdirll}/${name}.den ${tsdirll}/IRC/${name}_ircr.den
           cp ${tsdirll}/${name}.den ${tsdirll}/TSs/${name}_thermo.den
        elif [ -f ${tsdirll}/${name}_mop.den ]; then
           cp ${tsdirll}/${name}_mop.den ${tsdirll}/IRC/${name}_ircf.den
           cp ${tsdirll}/${name}_mop.den ${tsdirll}/IRC/${name}_ircr.den
           cp ${tsdirll}/${name}_mop.den ${tsdirll}/TSs/${name}_thermo.den
        fi
        cat tmp_geom >> $tsdirll/IRC/${name}_ircf.mop
        cat tmp_geom >> $tsdirll/IRC/${name}_ircr.mop
     else
        #thermo
        sed 's@temp_amk@'$temperature'@;s@opt.xyz@'$tsdirll'/TSs/'${name}'_opt.xyz@;s@carga@'$charge'@' $sharedir/opt_thermo > $tsdirll/TSs/${name}_thermo.dat  
        #IRC
        sed 's@temp_amk@'$temperature'@;s@opt.xyz@'$tsdirll'/IRC/'${name}'_opt.xyz@;s@carga@'$charge'@' $sharedir/opt_thermo > $tsdirll/IRC/${name}_thermo.dat  
        sed 's@grad.xyz@'$tsdirll'/IRC/'${name}'_grad.xyz@;s@carga@'$charge'@' $sharedir/grad > $tsdirll/IRC/${name}_grad.dat  
     fi 
     echo -e "insert or ignore into mopac values (NULL,'$name');\n.quit" | sqlite3 ${tsdirll}/inputs.db
  fi
done
echo Performing a total of $m irc calculations
#Perform m parallel calculations
if [ $m -gt 0 ]; then
#ft2 slurm
if [ ! -z $SLURM_JOB_ID ] && [ ! -z $SLURM_NTASKS ]; then
  if (( $m < $SLURM_NTASKS )); then 
    echo "WARNING: Number of irc calculations ($m) lower than allocated tasks ($SLURM_NTASKS)."
  fi
fi
   doparallel "runirc.sh {1} $tsdirll $program_opt" "$(seq $m)"
fi

