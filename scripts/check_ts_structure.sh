#!/bin/bash
source utils.sh
##Defining paths and names
cwd=$PWD
sharedir=${AMK}/share
exe=$(basename $0)
inputfile=amk.dat

file=ts.out
fileden=ts.den
npo=1
i=1
if [ ! -f $file ]; then
   echo $file does not exist
   exit 1
fi

#Reading input parameters
read_input
opt_start

fe="$(get_ts_properties.sh $file $prog $tight)"
fi="$(echo "$fe" | awk '{printf "%10.0f",$1}')"
ei="$(echo "$fe" | awk '{printf "%14.6f",$2}')"
if [[ ("$fi" -eq -1) ]]; then
   printf "     Pt%2s: failed-->Lowest real freq is negative\n" $npo
   exit    
elif [[ ("$fi" -eq -2) ]]; then
   printf "     Pt%2s: failed-->Sum of 2 lowest real freqs < 10cm-1\n" $npo
   exit    
elif [[ ("$fi" -eq -3) ]]; then
   printf "     Pt%2s: failed-->Stationary point is a minimum\n" $npo
   exit    
elif [[ ("$fi" -eq -4) ]]; then
   printf "     Pt%2s: failed-->EF algorithm was unable to optimize a TS\n" $npo
   exit    
elif (( $(echo "$ei > $emaxts" |bc -l) )); then
   printf "     Pt%2s: TS optimized but not added-->E=%20s > %20s \n" $npo $ei $emaxts
   exit    
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
         if [ "$program_opt" = "xtb" ]; then mv ts.molden $tsdirll/${name}.molden ; fi
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
      if [ "$program_opt" = "xtb" ]; then mv ts.molden $tsdirll/${name}.molden ; fi
      if [ "$program_opt" = "mopac" ]; then get_NM_mopac.sh $tsdirll/${name}.out $tsdirll/${name} ; fi
   fi
   ) 200>>${tslistll}.lock
else
   printf "     Pt%2s: TS optimized but not added-->imag=%4si cm-1 < %4si cm-1\n" $npo $fi $imag
fi

rm -rf fort.*
