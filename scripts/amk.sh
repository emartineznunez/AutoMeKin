#!/bin/bash
source utils.sh
#On exit remove tmp files
tmp_files=(ConnMat tmp_gauss tmp* ScalMat *.arc *.mop fort.* partial_opt ts_opt *_dyn* *_backup rotate.dat minn black_list* bfgs.log none.out forces.xyz velocities.xyz restraints.xyz energies.txt freq.molden min.xyz ts_opt.xyz ts.xyz min_opt.xyz v0 grad.dat grad.*)
trap 'err_report2 $LINENO $gauss_line' ERR
trap cleanup EXIT INT

##Defining paths and names
cwd=$PWD
sharedir=${AMK}/share
exe=$(basename $0)
if [ $# -eq 0 ]; then usages "One argument is required" ; fi
inputfile=$1
# Printing the references of the method
print_ref
##Define input file and create symbolic link-->amk.dat
define_inputfile
###Reading stuff from inputfile
read_input
###keywords check
keywords_check
### check files and write some stuff 
xyzfiles_check
###Peforming some calcs for the various samplings
sampling_calcs
### print method and screening sections
amkscript=1
print_method_screening
#################################
##  Starting the calculations
#################################
echo ""
echo "CALCULATIONS START HERE"
#####for association and vdw get the association complexes
if [ $sampling -ge 30 ]; then exec_assoc ; fi
##select starting structure
sel_mol.sh $inputfile $multiple_minima
frag_check
##lift MD-constraint in subsequent iterations (diels_bias for instance)
if [ -f $kmcfilell ] && [ -f $minfilell ] && [ $mdc -ge 1 ] && [ $ndis -eq 1 ]; then mdc=0 ; fi
##template for the dynamics
generate_dynamics_template
##make temporary folders
make_temp_folders
###Opt the starting structure and get e0 and emaxts
opt_start
####
if [ $mdc -ge 1 ]; then itrajn=5 ; fi
###Loop over the trajectories
for i in $(seq 1 $itrajn) 
do 
  named=${molecule}_dyn${i}
  echo ""
##Empty temporary folders
  rm -rf partial_opt/* ts_opt/* 
####
#This is only for internal dynamics (MOPAC)
####
  if [ $mdc -ge 1 ] && [ $i -gt 1 ]; then
     echo "Searching for reactive events with:"
  else
     echo ""
     echo "+-+-+-+-+-+-+-+-+-          Trajectory ${i}          +-+-+-+-+-+-+-+-+-"
     if [ $md -eq 0 ]; then
       echo "Performing BXDE MD"
       if [ "$program_md" = "qcore" ]; then sed 's/carga/'$charge'/' ${sharedir}/grad > grad.dat ; fi
       bxde.py $inputfile &>  ${named}.log
       if [ ! -f traj.xyz ]; then
          echo "traj.xyz does not exist"
          continue 
       else
          mv traj.xyz coordir/${named}.xyz
          if [ $postp_alg -eq 2 ]; then mv bond_order.txt coordir/${named}.bo ; fi
       fi
     elif [ $md -eq 1 ]; then 
        echo "Performing standard MD"
        echo "$dytem1"     > ${named}.mop
        #We change the masses of Hs --> 4
        initialqv_mopac_samp1.sh ${molecule}_freq.out $seed $excite $nlms $lstnm | nm.exe | sed 's/H /H4.0/g' >> ${named}.mop
        mopac ${named}.mop &> ${named}.log 
        if [ ! -f ${named}.xyz ]; then
           echo "${named}.xyz does not exist"
           continue 
        else
           mv ${named}.xyz coordir
        fi
     elif [ $md -eq 2 ]; then
        echo "Performing standard MD"
        if [ "$program_md" = "mopac" ]; then
           echo "$dytem1"     > ${named}.mop
           #We do not change the masses of Hs if there are constraints. Otherwise masses ---> 4
           if [ $mdc -ge 1 ]; then
              initialqv_mopac_samp2.sh ${molecule}_freq.out $excite $nlms $lstnm $thmass | termo.exe | sed 's/ 1.d/1.d/g' >> ${named}.mop
           else
              initialqv_mopac_samp2.sh ${molecule}_freq.out $excite $nlms $lstnm $thmass | termo.exe | sed 's/ 1.d/1.d/g;s/H /H4.0/g' >> ${named}.mop
           fi
           mopac ${named}.mop &> ${named}.log
           if [ ! -f ${named}.xyz ]; then
              echo "${named}.xyz does not exist"
              continue 
           else
              mv ${named}.xyz coordir
           fi
        elif [ "$program_md" = "qcore" ]; then
           rm -rf traj.xyz
           sed 's/carga/'$charge'/' ${sharedir}/MD > ${named}.qcore
           awk 'NR!=2{print $0};NR==2{print ""};END{print '"$excite"'"\n0\n0"}' opt_start.xyz | termo.exe | awk 'BEGIN{c=4.5710047e-9;print '$natom'"\n"};NF==3{print $1*c,$2*c,$3*c}' >v0
           entos.py ${named}.qcore > ${named}.out 2>&1
           if [ ! -f traj.xyz ]; then
              echo "traj.xyz does not exist"
              continue 
           else
              mv traj.xyz coordir/${named}.xyz
           fi
        fi
     else
       echo "Reading external dynamics results from coordir"
     fi
  fi

  if [ $postp_alg -eq 0 ]; then
     echo "End of traj "$i
     echo "Only trajs. No post-processing algorithm applied to search for TSs"
     break
  elif [ $postp_alg -eq 1 ]; then
     postp_file=bbfs     
  elif [ $postp_alg -eq 2 ]; then
     postp_file=bots     
  fi
###########
#From here everything is common for internal and external dynamics
###########
  if [ $i -eq 1 ]; then
     echo "  *+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*"  > ${postp_file}.out
     echo "                $postp_file algorithm results          " >> ${postp_file}.out
     echo "  *+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*+*" >> ${postp_file}.out
     echo ""                                                        >> ${postp_file}.out
  fi
  echo "  Trajectory $i" >> ${postp_file}.out

  if [ $postp_alg -eq 1 ]; then
     if [ $mdc -eq 0 ]; then
        snapshots_mopac.sh coordir/${named}.xyz  $irange | bbfs.exe >> ${postp_file}.out
     elif [ $mdc -ge 1 ]; then
        namedc=${molecule}_dyn1
        irange=$((20-4*(i - 1) ))
        irangeo2=$(echo "scale=0; $irange/2" | bc )
        echo "Time window (fs) = $irange "
        snapshots_mopac.sh coordir/${namedc}.xyz  $irange | bbfs.exe >> ${postp_file}.out
     fi
  elif [ $postp_alg -eq 2 ]; then
     bots.py $natom $cutoff $stdf ${named} >> ${postp_file}.out
  fi

  path=$(awk '/Number of paths/{np=$4};END{print np}' ${postp_file}.out )
  if [ $path -eq 0 ]; then
     echo "This traj has no paths "
     continue
  fi

  echo "Npaths=" $path
  chapath[0]=0
  for ip in $(seq $path)
  do
# Find the highest energy point
    if [ $postp_alg -eq 1 ]; then
       ijc=$(awk '/Joint path=/{if($2=='$ip') ijc=$5};END{print ijc}' ${postp_file}.out)
    else
       ijc=0
    fi
    jp=$((ip - 1))
##If previous path was multiple, continue 
    chapath[$ip]=$ijc
    if [ ${chapath[$jp]} -eq 1 ]; then continue ; fi
##
    if [ $ijc -eq 0 ]; then
       echo "Path" $ip" (Single): $nppp attempt(s)  to locate the ts" 
       ll=$((wrkmode-1))
       dlt=$((wrkmode+1))
       ul=1
    elif [ $ijc -eq 1 ]; then 
       echo "Path" $ip" (Multiple): several attempts to locate the ts" 
       ll=$((1 - irangeo2))
       dlt=$(echo "scale=2; $irange/6" | bc | awk '{print int($1+0.5)}')
       ul=$irangeo2  
    fi
    npo=0
    for itspt in $(seq $ll $dlt $ul)
    do 
       npo=$((npo + 1))
       ctspt=$((100*ip + irangeo2 + itspt))
       echo "$min_template"         > partial_opt/pes$ctspt
       if [ $postp_alg -eq 1 ]; then
          cat partial_opt/fort.$ctspt >> partial_opt/pes$ctspt
       else
          cat partial_opt/fort.$ip >> partial_opt/pes$ctspt
       fi
       if [ "$program_md" = "mopac" ]; then
          mopac partial_opt/pes$ctspt  2> /dev/null
          geo_pes=$(get_geom_mopac.sh partial_opt/pes${ctspt}.out)
          if [ "$geo_pes" = "Error" ]; then continue ; fi
       elif [ "$program_md" = "qcore" ]; then
          echo $natom > min.xyz
          echo "" >> min.xyz
          if [ $postp_alg -eq 1 ]; then
             awk '{print $1,$2,$4,$6}' partial_opt/fort.$ctspt >> min.xyz
             labels=$(awk '{if($3=="0") {printf "%s%s",sep,NR; sep=","}};END{print ""}' partial_opt/fort.$ctspt)
          else
             awk '{print $1,$2,$4,$6}' partial_opt/fort.$ip >> min.xyz
             labels=$(awk '{if($3=="0") {printf "%s%s",sep,NR; sep=","}};END{print ""}' partial_opt/fort.$ip)
          fi 
          sed 's/labels/'"$labels"'/g;s/carga/'$charge'/' ${sharedir}/opt_frozen > partial_opt/pes_qcore
          entos.py partial_opt/pes_qcore > partial_opt/pes_qcore.out
          if [ ! -f min_opt.xyz ]; then 
             printf "     Pt%2s: failed-->Partial Opt failed\n" $npo
             continue
          fi
       fi
       name=ts${i}_${ip}_${ctspt}
       fileden=ts_opt/${name}.den
       if [ "$program_opt" = "mopac" ]; then
          geom_TS="$(echo "$geo_pes" | awk 'NF==4{print $0}')"
          name_TS_inp=ts_opt/${name}
          int_flag=0
          launch_mopac_TS
       elif [ "$program_opt" = "qcore" ]; then
          mv min_opt.xyz ts.xyz
          sed 's/carga/'$charge'/' ${sharedir}/optTS > ts_opt/ts.dat
          entos.py ts_opt/ts.dat > ts_opt/${name}.out
          if [ ! -f ts_opt.xyz ]; then 
             printf "     Pt%2s: failed-->No XYZ file found for the TS\n" $npo
             echo Error >> ts_opt/${name}.out
             continue 
          else
             cat ts_opt.xyz >> ts_opt/${name}.out
          fi
          file=ts_opt/${name}.out
       else
#construct g09 input file
          chkfile=ts_opt/ts$name
          calc=ts
          geo="$(echo "$geo_pes" | awk 'NF==4{print $0};END{print ""}')"
          level=ll
          g09_input
          echo -e "$inp_hl\n\n" > ts_opt/${name}.dat
	  if [ "$program_opt" = "g09" ]; then
             g09 <ts_opt/${name}.dat >ts_opt/${name}.log && gauss_line=$(echo $LINENO)
	  elif [ "$program_opt" = "g16" ]; then
             g16 <ts_opt/${name}.dat >ts_opt/${name}.log && gauss_line=$(echo $LINENO)
          fi
          file=ts_opt/${name}.log
          ok=$(awk 'BEGIN{fok=0;ok=0;err=0};/Frequencies/{++nfreq;if($3<0 && $4>0 && nfreq==1) fok=1};/Error termi/{++err};END{if(err==0 && fok==1) ok=1; print ok}' $file)
          if [ $ok -eq 1 ]; then
             get_energy_g09_${LLcalc}.sh $file 1   > tmp_gauss
             get_freq_g09.sh $file >> tmp_gauss
          else
             printf "     Pt%2s: failed-->EF algorithm was unable to optimize a TS\n" $npo
	     continue    
          fi
       fi
       fe="$(get_ts_properties.sh $file $prog $tight)"
       fi="$(echo "$fe" | awk '{printf "%10.0f",$1}')"
       ei="$(echo "$fe" | awk '{printf "%14.6f",$2}')"
       if [[ ("$fi" -eq -1) ]]; then
          printf "     Pt%2s: failed-->Lowest real freq is negative\n" $npo
          continue
       elif [[ ("$fi" -eq -2) ]]; then
          printf "     Pt%2s: failed-->Sum of 2 lowest real freqs < 10cm-1\n" $npo
          continue
       elif [[ ("$fi" -eq -3) ]]; then
          printf "     Pt%2s: failed-->Stationary point is a minimum\n" $npo
          continue
       elif [[ ("$fi" -eq -4) ]]; then
          printf "     Pt%2s: failed-->EF algorithm was unable to optimize a TS\n" $npo
          continue
       elif (( $(echo "$ei > $emaxts" |bc -l) )); then
          printf "     Pt%2s: TS optimized but not added-->E=%20s > %20s \n" $npo $ei $emaxts
          continue
       fi
       if [[ ("$fi" -ge "$imag") ]]; then
          string="$(echo "$fe" | awk '{printf "%10.0f %10.4f %10.0f %10.0f %10.0f %10.0f",$1,$2,$3,$4,$5,$6}')"
# GLB added lock to tslist so that duplicate numbers are not created
          (
          flock -x 200 || exit 1
          if [ -f "$tslistll" ]; then
             ok=$(diff.sh $string $tslistll $prog)
             if [[ ("$ok" -eq "-1") ]]; then
                nt=$(awk '{nt=$2};END{print nt + 1}' $tslistll )
                name=ts${nt}_${nb}
                printf "ts%5s%18s%70s traj= %4s Path= %10s\n" $nt $name "$string" $i $nb  >> $tslistll
                cp ${file} ${tsdirll}/${name}.out
                if [ -f ${fileden} ]; then cp ${fileden} ${tsdirll}/${name}.den ; fi
                printf "     Pt%2s: TS optimized and added to ts list\n" $npo
                if [ "$program_opt" = "qcore" ]; then mv freq.molden $tsdirll/${name}.molden ; fi
                if [ "$program_opt" = "mopac" ]; then get_NM_mopac.sh $tsdirll/${name}.out $tsdirll/${name} ; fi
             else
                printf "     Pt%2s: TS optimized but not added-->redundant with ts %4s\n" $npo $ok
             fi
          else
             nt=1
             name=ts${nt}_${nb}
             printf "ts%5s%18s%70s traj= %4s Path= %10s\n" $nt $name "$string" $i $nb  >> $tslistll
             cp ${file} ${tsdirll}/${name}.out
             if [ -f ${fileden} ]; then cp ${fileden} ${tsdirll}/${name}.den ; fi
             printf "     Pt%2s: TS optimized and added to ts list\n" $npo
             if [ "$program_opt" = "qcore" ]; then mv freq.molden $tsdirll/${name}.molden ; fi
             if [ "$program_opt" = "mopac" ]; then get_NM_mopac.sh $tsdirll/${name}.out $tsdirll/${name} ; fi
          fi
          ) 200>>${tslistll}.lock
          if [ $mdc -ge 1 ]; then exit ; fi
          break
       else
          imnu=$(date | awk '{print $3,$4}' | sed 's@ @@g;s@:@@g')
          cp ${file} ${tsdirll}/LOW_IMAG_TSs/LOW_IMAG${imnu}_${nb}.out
          printf "     Pt%2s: TS optimized but not added-->imag=%4si cm-1 < %4si cm-1\n" $npo $fi $imag
       fi
    done
  done
done


if [ $sampling -ne 30 ]; then 
   echo ""
   echo "END OF THE CALCULATIONS" 
   echo ""
fi

