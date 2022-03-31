#!/bin/bash
source utils.sh
#On exit remove tmp files
tmp_files=(ConnMat deg_bo deg* fort.* intern.dat intern.out intern* mingeom ScatMat ts_tors* ScalMat *_opt.* tors.* geomts_tors0 geomts_tors geom* tmp_gauss tmp* dihedrals tors_qcore.* ts.dat ts.xyz min.xyz freq.molden bond_order.txt bo.out bo.*)
trap 'err_report2 $LINENO $gauss_line' ERR
trap cleanup EXIT INT

#Paths and names
cwd=$PWD
sharedir=${AMK}/share
exe=$(basename $0)

###checking possible argument
if [ $# -eq 0 ]; then
   if [ -f amk.dat ];then
      inputfile=amk.dat
   else
      echo "Input file is missing."
      echo "Usage: tors.sh inputfile"
      exit 1
   fi
   do_di="all"
elif [ $# -eq 1 ]; then
   inputfile=$1
   do_di="all"
   ln -sf $inputfile amk.dat
elif [ $# -eq 2 ]; then
   inputfile=$1
   do_di=$2
   ln -sf $inputfile amk.dat
   if [ "$do_di" != "all" ] && [ "$do_di" != "file" ]; then
      echo Second argument: file or all 
      exit 1
   fi
fi
if [ "$do_di" = "file" ] && [ ! -f dihedrals ]; then
   echo dihedrals is missing
   exit 1
fi
###Reading stuff from inputfile
read_input
if [ $torsion -eq 0 ]; then
   echo "No torsion calculations"
   exit
fi
###
if [ $sampling -ge 30 ];then
   echo "No torsion calculations for this sampling"
   exit
fi
###Make tsdirll if not present
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
#################################
##  Starting the calculations
#################################
echo ""
echo "CALCULATIONS START HERE"
opt_start
###Print out some stuff
echo The value of e0=$e0
#echo The relative value of emaxts=$emaxts
#emaxts=$(echo "scale=6; $emaxts+$e0" | bc | awk '{printf "%14.6f",$1}')
echo The absolute value of emaxts=$emaxts
echo ""
echo ""
##select the initial minimum
flag="tors"
confilell=$tsdirll/working/conf_isomer.out
minrf=${tsdirll}/min_tors.inp
tmpti=${tsdirll}/tmp_tors.inp
minr0=${tsdirll}/min_refe.inp
mindb=${tsdirll}/MINs/SORTED/mins.db
if [ -f $minfilell ];then
   if [ -f $confilell ]; then
      awk 'NR==FNR{for(i=2;i<=NF;i++) {++nc;conf[nc]=$i}};NR>FNR{ok=1;for(i=1;i<=nc;i++) if($2==conf[i]) ok=0;if(ok==1) printf "%5.0f %8.2f\n",$2,$NF}' $confilell $minfilell > $minr0 
   else
      awk '{printf "%5.0f %8.2f\n",$2,$NF}' $minfilell > $minr0 
   fi
#compare minr0 and minrf
   awk 'NR==FNR{e[NR]=$2;++nmin};NR>FNR{ok=1;for(i=1;i<=nmin;i++) if($2 == e[i]) ok=0; if(ok==1) printf "%5s %8.2f\n",$1,$2 } ' $minrf $minr0 > $tmpti
   cat $minrf $tmpti > tmp && mv tmp $minrf   
else
   echo " min0     0.00" > $minrf
   echo " min0     0.00" > $tmpti
fi

if [ $(wc -l $tmpti | awk '{print $1}') -eq 0 ]; then
   echo No further min have been found
   exit 1
fi

for min in $(awk '{print $1}' $tmpti)
do
   printf "\n=====MIN: %4s =====\n" $min
   names="MIN"$min
   echo $natom > mingeom
   echo ""    >> mingeom
   if [ "$min" == "min0" ]; then
      if [ "$program_opt" = "qcore" ]; then
         awk '/Final structure/{flag=1; next} EOF{flag=0} flag' ${molecule}_freq.out >> mingeom
      else
         get_geom_mopac.sh ${molecule}_freq.out | awk 'NF==4{print $0}' >> mingeom
      fi
   else
      sqlite3 $tsdirll/MINs/SORTED/mins.db "select geom from mins where name='$names'" >> mingeom
   fi
   bond_order.py
   get_geom_mopac.sh bo.out  >mingeom 
   createMat.py mingeom 1 $nA
   if [ "$do_di" = "all" ]; then
      awk '{si=0;for(i=1;i<=NF;i++) {si+=$i;if(i==NF) print si,$0 }}' ConnMat > deg_bo
      awk '{for(i=1;i<=NF;i++) bo[i]=$i }
      END{k=0
      for(i=1;i<='$natom';i++) {
        for(j=i+1;j<='$natom';j++) {++k
          if(bo[k]>0.1 && bo[k]<2.0) print i,j
          }
        }
      }' bond_order.txt >> deg_bo
      awk '{
      if(NR<='$natom'){
        deg[NR]=$1
        l=0
        if(deg[NR]>1) {for(i=2;i<=NF;i++) {if($i==1) {++l;jatom[NR,l]=i-1 } }}
        }
      else {
        if(deg[$1]>1 && deg[$2]>1) {
          ok=0
          j=1
          while( j<=deg[$1] ){
            if(jatom[$1,j] != $2) k=jatom[$1,j]
            else ok=1
            ++j
            }
          j=1
          while( j<=deg[$2] ){
            if(jatom[$2,j] != $1) {l=jatom[$2,j];break}
            ++j
            }
          if(ok==1&& k>l) print k,$1,$2,l
          if(ok==1&& l>k) print l,$2,$1,k
          }
        }
      }' deg_bo  > dihedrals
   else
      echo "Dihedrals have not been computed again"
      echo "      Taken from file: dihedrals      "
   fi
   
   ntor=$(wc -l dihedrals | awk '{print $1}')
   echo "Number of torsions $ntor"
   if [ $ntor -eq 0 ]; then continue ; fi
   for itor in $(awk '{print NR}' dihedrals)
   do
      echo ""
      lr=$(awk 'NR=='$itor'{print $1;exit}' dihedrals )
      l1=$(awk 'NR=='$itor'{print $2;exit}' dihedrals )
      l2=$(awk 'NR=='$itor'{print $3;exit}' dihedrals )
      l3=$(awk 'NR=='$itor'{print $4;exit}' dihedrals )
      labels=$(echo "$lr $l1 $l2 $l3" | awk '{print $1","$2","$3","$4}')  
      echo "Running the TS search for tors $itor around bond: $l1"-"$l2"
      # check if the bond belong to a ring, in which case,skip
      if [ "$(cyclic_graph.py mingeom $l1 $l2)" = "True" ]; then 
         echo Rotation of a bond that belongs to a ring
         echo Skiping this dihedral...
         continue 
      fi
      if [ $l1 -gt $lr ]; then ((l1=l1-1)) ; fi
      if [ $l2 -gt $lr ]; then ((l2=l2-1)) ; fi
      if [ $l3 -gt $lr ]; then ((l3=l3-1)) ; fi
      cp mingeom intern.dat
      awk 'NR=='$itor'{print $0}' dihedrals >>intern.dat
      intern.exe <intern.dat>intern.out
      if [ $(awk 'BEGIN{fok=1};/Abort/{fok=0};END{print fok}' intern.out) -eq 0 ]; then 
         echo Angle close to 180 degrees
         echo Skiping this dihedral...
         continue 
      fi
      dihed0=$(awk '{print $6}' intern.out)
      if [ "$program_opt" = "qcore" ];then
         for idihed in $(seq 36)
         do
            if [ $idihed -eq 1 ]; then echo "POTENTIAL ENERGY SURFACE SCAN" > tors.out  ; fi
            rm -rf min_opt.xyz
            dihed=$(echo "scale=2; $dihed0+($idihed-1)*10" | bc)
            sed 's/labels/'"$labels"'/;s/carga/'$charge'/;s/value_dihed/'$dihed'/' ${sharedir}/scan_tors > tors_qcore.dat
            cp mingeom  min.xyz
            entos.py tors_qcore.dat > tors_qcore.out
            if [ -f min_opt.xyz ]; then
               echo "  VARIABLE        FUNCTION" >> tors.out 
               eopt="$(awk '/Energy=/{e=$2};END{printf "%10.1f - %13.3f\n",'$dihed',e*627.51}' tors_qcore.out)"
               echo "$eopt"  >> tors.out
               printf "\n\n\n" >> tors.out
               awk 'NR>2{print $0}' min_opt.xyz >> tors.out
            fi 
         done
      else
         internlastatom="$(awk '{print $1,$2,$3,$4," 0 ",$6,$7,'$l1','$l2','$l3'}' intern.out)"
         sed 's/method/'"$method"' charge='$charge'/g' $sharedir/path_template >tors.mop
         cat mingeom | awk 'NF==4{print $0}' | awk '{if(NR!= '$lr') print $0}' >> tors.mop 
         echo "$internlastatom" >> tors.mop
         mopac tors.mop 2>/dev/null
      fi
      awk '/VARIABLE        FUNCTION/{++i;getline
      e[i]=$3;getline;getline;getline
      for(j=1;j<='$natom';j++) {getline;l[i,j]=$0} }
      END{
      for(i0=2;i0<=i;i0++){
        if(e[i0]>e[i0-1] && e[i0]>e[i0+1]) {
           proc=1
           for(k=1;k<=nmax;k++){diff0=e[i0]-emax[k];diff=sqrt(diff0*diff0);if(diff<=0.01) proc=0}
           if(proc==0) continue
           ++nmax
           emax[nmax]=e[i0]  
           for(j=1;j<='$natom';j++) print l[i0,j]
           }
        } 
      }' tors.out | sed 's/+0/+1/g' > geomts_tors0
      nomax="$(awk 'END{print NR/'$natom'}' geomts_tors0)"
      echo "$nomax possible candidate(s):"
      for inmax in $(seq 1 $nomax)
      do
         awk 'BEGIN{nr0='$natom'*('$inmax'-1)+1;nrf='$natom'*'$inmax'};{if(NR>=nr0 && NR<=nrf) print $0}' geomts_tors0 >geomts_tors
         name="ts_tors"$itor
         fileden=${name}.den
         if [ "$program_opt" = "mopac" ]; then
            geom_TS="$(awk '$7="+1"' geomts_tors)"
            name_TS_inp=${name}
            int_flag=1
            launch_mopac_TS
         elif [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
            geom_TS="$(awk '$7="+1"' geomts_tors)"
            name_TS_inp=${name}
            int_flag=1
            launch_mopac_TS
#construct g09 input file
            chkfile=$name
            calc=ts
            geo="$(get_geom_mopac.sh ${name}.out | awk '{if(NF==4) print $0};END{print ""}')"
            level=ll
            g09_input
            echo -e "$inp_hl\n\n" > ${name}.dat
            if [ "$program_opt" = "g09" ] ; then
               g09 <${name}.dat >${name}.log && gauss_line=$(echo $LINENO)
            elif [ "$program_opt" = "g16" ] ; then
               g16 <${name}.dat >${name}.log && gauss_line=$(echo $LINENO)
            fi
            file=${name}.log
            ok=$(awk 'BEGIN{fok=0;ok=0;err=0};/Frequencies/{++nfreq;if($3<0 && $4>0 && nfreq==1) fok=1};/Error termi/{++err};END{if(err==0 && fok==1) ok=1; print ok}' $file)
            if [ $ok -eq 1 ]; then
               get_energy_g09_${LLcalc}.sh $file 1   > tmp_gauss
               get_freq_g09.sh $file >> tmp_gauss
            else
               printf "     Pt%2s: failed-->EF algorithm was unable to optimize a TS\n" $inmax
  	       continue    
            fi
         elif [ "$program_opt" = "qcore" ]; then
            echo $natom > ts.xyz
            echo ""     >> ts.xyz
            cat geomts_tors >> ts.xyz
            sed 's/carga/'$charge'/' ${sharedir}/optTS > ts.dat
            entos.py ts.dat > ${name}.out
            if [ ! -f ts_opt.xyz ]; then
               printf "     Pt%2s: failed-->No XYZ file found for the TS\n" $inmax
               continue
            else
               cat ts_opt.xyz >> ${name}.out
            fi
            file=${name}.out
         fi

   #check the ts
         fe="$(get_ts_properties.sh $file $prog 1)" 
         fi="$(echo "$fe" | awk '{printf "%10.0f",$1}')"
         ei="$(echo "$fe" | awk '{printf "%14.6f",$2}')"
         if [[ ("$fi" -eq -1) ]]; then
            printf "     Pt%2s: failed-->Lowest real freq is negative\n" $inmax
            continue
         elif [[ ("$fi" -eq -2) ]]; then
            printf "     Pt%2s: failed-->Sum of 2 lowest real freqs < 10cm-1\n" $inmax
            continue
         elif [[ ("$fi" -eq -3) ]]; then
            printf "     Pt%2s: failed-->Stationary point is a minimum\n" $inmax 
            continue
         elif [[ ("$fi" -eq -4) ]]; then
            printf "     Pt%2s: failed-->EF algorithm was unable to optimize a TS\n" $inmax 
            continue
         elif (( $(echo "$ei > $emaxts" |bc -l) )); then
            printf "     Pt%2s: TS optimized but not added-->E=%20s > %20s \n" $inmax $ei $emaxts
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
                  printf "ts%5s%18s%70s traj= %4s Path= %10s\n" $nt $name "$string" $flag $nb  >> $tslistll
                  cp ${file}  $tsdirll/${name}.out 
                  if [ -f ${fileden} ]; then cp ${fileden} ${tsdirll}/${name}.den ; fi
                  printf "     Pt%2s: TS optimized and added to ts list\n" $inmax
                  if [ "$program_opt" = "qcore" ]; then mv freq.molden $tsdirll/${name}.molden ; fi
                  if [ "$program_opt" = "mopac" ]; then get_NM_mopac.sh $tsdirll/${name}.out $tsdirll/${name} ; fi
               else
                  printf "     Pt%2s: TS optimized but not added-->redundant with ts %4s\n" $inmax $ok
               fi
            else
               nt=1
               name=ts${nt}_${nb}
               printf "ts%5s%18s%70s traj= %4s Path= %10s\n" $nt $name "$string" $flag $nb  >> $tslistll
               cp ${file}  $tsdirll/${name}.out
               if [ -f ${fileden} ]; then cp ${fileden} ${tsdirll}/${name}.den ; fi
               printf "     Pt%2s: TS optimized and added to ts list\n" $inmax
               if [ "$program_opt" = "qcore" ]; then mv freq.molden $tsdirll/${name}.molden ; fi
               if [ "$program_opt" = "mopac" ]; then get_NM_mopac.sh $tsdirll/${name}.out $tsdirll/${name} ; fi
            fi
            ) 200>>${tslistll}.lock
         else
            imnu=$(date | awk '{print $3,$4}' | sed 's@ @@g;s@:@@g')
            cp ${file} ${tsdirll}/LOW_IMAG_TSs/LOW_IMAG${imnu}_${nb}.out
            printf "     Pt%2s: TS optimized but not added-->imag=%4si cm-1, which is lower than %4si cm-1\n" $inmax $fi $imag
         fi
      done
   done
done

