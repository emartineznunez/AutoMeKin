#!/bin/bash
source utils.sh
sharedir=${AMK}/share
name=$1
inputfile=amk.dat
cwd=$PWD
###reading input
read_input
###
if [ "$program_opt" != "qcore" ]; then
##ndis forward
   awk '/Pro/{n=0};NF==4{++n;a[n]=$0};END{print '$natom';print "";for(i=1;i<=n;i++) print a[i]}' $tsdirll/IRC/${name}_ircf.xyz > mingeom
   createMat.py mingeom 3 $nA
   echo "1" $natom > sprint.dat
   cat ConnMat    >> sprint.dat
   if [ $(sprint2.exe<sprint.dat | awk '/Results for the Laplacian/{getline;n=0;for(i=6;i<=NF;i++) {if($i<='$nfrag_th')++n}};END{print n}') -gt  1 ]; then
      sed 's@method@1scf '"$method"' denout charge='$charge'@;s@precise cycles=5000@@' $sharedir/freq_template1 > $tsdirll/IRC/minf_${name}.mop
   else
      if [ $recalc -eq -1 ]; then
         sed 's@method@'"$method"' denout charge='$charge'@;s@precise@@' $sharedir/freq_template1 > $tsdirll/IRC/minf_${name}.mop
      else
         sed 's@method@'"$method"' denout recalc='$recalc' charge='$charge'@;s@precise@@' $sharedir/freq_template1 > $tsdirll/IRC/minf_${name}.mop
      fi
   fi
   awk '/Pro/{n=0};NF==4{++n;a[n]=$0};END{for(i=1;i<=n;i++) print a[i];print ""}' $tsdirll/IRC/${name}_ircf.xyz >> $tsdirll/IRC/minf_${name}.mop
#thermo calc on top of the previous calc
   sed 's/thermo/thermo('$temperature','$temperature')/;s/method/'"$method"' oldens oldgeo charge='$charge'/' $sharedir/thermo_template >>  $tsdirll/IRC/minf_${name}.mop
##ndis reverse 
   awk '/Pro/{n=0};NF==4{++n;a[n]=$0};END{print '$natom';print "";for(i=1;i<=n;i++) print a[i]}' $tsdirll/IRC/${name}_ircr.xyz > mingeom
   createMat.py mingeom 3 $nA
   echo "1" $natom > sprint.dat
   cat ConnMat    >> sprint.dat
   if [ $(sprint2.exe<sprint.dat | awk '/Results for the Laplacian/{getline;n=0;for(i=6;i<=NF;i++) {if($i<='$nfrag_th')++n}};END{print n}') -gt  1 ]; then
      sed 's@method@1scf '"$method"' denout charge='$charge'@;s@precise cycles=5000@@' $sharedir/freq_template1 > $tsdirll/IRC/minr_${name}.mop
   else
      if [ $recalc -eq -1 ]; then
         sed 's@method@'"$method"' denout charge='$charge'@;s@precise@@' $sharedir/freq_template1 > $tsdirll/IRC/minr_${name}.mop
      else
         sed 's@method@'"$method"' denout recalc='$recalc' charge='$charge'@;s@precise@@' $sharedir/freq_template1 > $tsdirll/IRC/minr_${name}.mop
      fi
   fi
   awk '/Pro/{n=0};NF==4{++n;a[n]=$0};END{for(i=1;i<=n;i++) print a[i];print ""}' $tsdirll/IRC/${name}_ircr.xyz >> $tsdirll/IRC/minr_${name}.mop
#thermo calc on top of the previous calc
   sed 's/thermo/thermo('$temperature','$temperature')/;s/method/'"$method"' oldens oldgeo charge='$charge'/' $sharedir/thermo_template >>  $tsdirll/IRC/minr_${name}.mop
else
   sed 's@min@'$tsdirll'/IRC/'${name}'_forward_last@;s@carga@'$charge'@' $sharedir/opt > $tsdirll/IRC/${name}_forward_last_opt.dat
   sed 's@min@'$tsdirll'/IRC/'${name}'_reverse_last@;s@carga@'$charge'@' $sharedir/opt > $tsdirll/IRC/${name}_reverse_last_opt.dat
   sed 's@temp_amk@'$temperature'@;s@opt@'$tsdirll'/IRC/'${name}'_forward_last_opt@;s@freq@'$tsdirll'/IRC/minf_'${name}'@;s@carga@'$charge'@' $sharedir/opt_thermo > $tsdirll/IRC/minf_${name}.dat
   sed 's@temp_amk@'$temperature'@;s@opt@'$tsdirll'/IRC/'${name}'_reverse_last_opt@;s@freq@'$tsdirll'/IRC/minr_'${name}'@;s@carga@'$charge'@' $sharedir/opt_thermo > $tsdirll/IRC/minr_${name}.dat
fi

