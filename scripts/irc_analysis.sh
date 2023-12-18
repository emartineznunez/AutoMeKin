#!/bin/bash
#
source utils.sh

cwd=$PWD
inputfile=amk.dat
exe=$(basename $0)

###reading input file
read_input
###

#remove tmp files
tmp_files=(fort.* deg.out deg_form.out deg* mingeom ScalMat sprint.out tmp* sprint.out $tsdirll/IRC/*.arc $tsdirll/IRC/*.mop $tsdirll/TSs/*.mop)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
###
if [ ! -d "$tsdirll/PRODs" ]; then
   echo "PRODs does not exist. It will be created"
   mkdir $tsdirll/PRODs
else
   echo "PRODs already exists."
fi
##Create table for ts rxyz files
sqlite3 ${tsdirll}/TSs/ts.db "create table if not exists ts (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,sigma INTEGER);"
##
##create prod and data table
sqlite3 ${tsdirll}/PRODs/prod.db "create table if not exists prod (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT, formula TEXT);"
##
# analysis
for name in $(awk '{print $3}' $tslistll)
do
  echo "Analyzing $name"

  if [ -f ${tsdirll}/ts_mopac_failed ]; then
    skip=$(awk 'BEGIN{skip=0};/'$name'/{skip=1};END{print skip}' ${tsdirll}/ts_mopac_failed)
    if [ $skip == 1 ]; then
       echo "TS $name has ben previously discarded-->(skip because mopac cannot optimize it)"
       continue
    fi
  fi

  if [ $(sqlite3 ${tsdirll}/TSs/ts.db "select exists(select name from ts where name='$name')") -eq 1 ]; then continue ; fi

#First the tss
  if [ "$program_opt" = "g09" ] || [ "$program_opt" = "g16" ]; then
     freq="$(get_freq_mopac.sh $tsdirll/${name}_mop.out)"
  elif [ "$program_opt" = "mopac" ]; then
     freq="$(get_freq_mopac.sh $tsdirll/${name}.out)"
  elif [ "$program_opt" = "qcore" ]; then
     freq="$(awk '/Freq/{flag=1;next}/Lowest/{flag=0}flag' $tsdirll/${name}.out)"
  fi

  if [ "$program_opt" != "qcore" ]; then
     geom="$(get_geom_thermo_mopac.sh $tsdirll/TSs/${name}_thermo.out)"
     e=$(awk 'BEGIN{e=0};/HEAT OF FORMATION =/{e=$5};END{print e}' $tsdirll/TSs/${name}_thermo.out )
     zpe=$(awk 'BEGIN{zpe=0};/          ZERO POINT ENERGY/{zpe=$4};END{print zpe}' $tsdirll/TSs/${name}_thermo.out )
     sigma=$(awk '/SYMMETRY NUMBER/{print $NF;exit}' $tsdirll/TSs/${name}_thermo.out)
     g_corr=$(awk 'BEGIN{zpe=0;h=0;s=0;t='$temperature'}
        /          ZERO POINT ENERGY/{zpe=$4}
        /CALCULATED THERMODYNAMIC PROPERTIES/{ok=1}
     {if(ok==1 && $1 == '$temperature') {
     getline;getline;getline;getline;
     h=$3/1000;s=$5/1000;print zpe+h-t*s;exit}
     }' $tsdirll/TSs/${name}_thermo.out )
  else
     geom="$(awk '/Final structure/{flag=1; next} EOF{flag=0} flag' $tsdirll/${name}.out)"
     e=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/TSs/${name}_thermo.out )
     zpe=$(awk '/ZPE/{zpe=$2};END{print zpe*627.51}' $tsdirll/TSs/${name}_thermo.out )
     sigma=1
     g_corr=$(awk '/Gibbs/{gibbs=$NF};END{print gibbs*627.51}' $tsdirll/TSs/${name}_thermo.out )
  fi
##insert into ts.db
  sqlite3 ${tsdirll}/TSs/ts.db "insert into ts (natom,name,energy,zpe,g,geom,freq,sigma) values ($natom,'$name',$e,$zpe,$g_corr,'$geom','$freq',$sigma);"
##insert into ts.db

#Now the minima
  namef=minf_${name}

  if [ "$program_opt" != "qcore" ]; then
     geomf="$(get_geom_mopac.sh $tsdirll/IRC/${namef}.out | awk 'NR>2{print $0}')"
     freqf="$(get_freq_mopac.sh $tsdirll/IRC/${namef}.out)"
     ef=$(awk 'BEGIN{e=0};/HEAT OF FORMATION =/{e=$5};END{print e}' $tsdirll/IRC/${namef}.out )
     zpef=$(awk 'BEGIN{zpe=0};/          ZERO POINT ENERGY/{zpe=$4};END{print zpe}' $tsdirll/IRC/${namef}.out )
     sigmaf=$(awk '/SYMMETRY NUMBER/{print $NF;exit}' $tsdirll/IRC/${namef}.out)
     g_corrf=$(awk 'BEGIN{zpe=0;h=0;s=0;t='$temperature'}
        /          ZERO POINT ENERGY/{zpe=$4}
        /CALCULATED THERMODYNAMIC PROPERTIES/{ok=1}
     {if(ok==1 && $1 == '$temperature') {
     getline;getline;getline;getline;
     h=$3/1000;s=$5/1000;print zpe+h-t*s;exit}
     }' $tsdirll/IRC/${namef}.out )
  else
     geomf="$(awk '/Final structure/{flag=1; next} /QCORE/{flag=0} flag' $tsdirll/IRC/${namef}.out)"
     freqf="$(awk '/Freq/{flag=1;next}/Lowest/{flag=0}flag' $tsdirll/IRC/${namef}.out)"
     ef=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/IRC/${namef}.out )
     zpef=$(awk '/ZPE/{zpe=$2};END{print zpe*627.51}' $tsdirll/IRC/${namef}.out )
     sigmaf=1
     g_corrf=$(awk '/Gibbs/{gibbs=$NF};END{print gibbs*627.51}' $tsdirll/IRC/${namef}.out )
  fi
#The minima might have failed in the opt process. In that case empty the freq column 
  if [ -z "$freqf" ]; then
     echo "Problems with this minimum: $namef-->thermo calc failed"
     zpef=0
     g_corrf=0
     freqf=""
     sigmaf=1
     if [ "$program_opt" != "qcore" ]; then
        ircn0=$(echo $namef | sed 's@min@@;s@_@ @') 
        ircnf=$(echo $ircn0 | awk '{print $2"_irc"$1".xyz"}')
        ef=$(awk '/HEAT OF FORMATION/{heat=$(NF-1)};END{print heat}' $tsdirll/IRC/$ircnf)
        geomf="$(awk '/HEAT OF FORMATION/{natom=0};{if(NF==4) {++natom;line[natom]=$0} };END{i=1;while(i<=natom){print line[i];i++}}' $tsdirll/IRC/$ircnf)"
     else
        ets=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/${name}.out )
        deltaf=$(awk 'BEGIN{act=0};/DVV/{if($NF=="-1") act=1};{if(act==1 && NF==6) delta=$2};{if(act==1 && NF==0) {print delta;exit}};{if(act==1 && $2=="QCORE") {print delta;exit}}' $tsdirll/IRC/${name}_ircf.out)
        ef=$(echo "$ets + $deltaf" | bc -l)
        geomf="$(awk 'NR>2' $tsdirll/IRC/${name}_forward_last.xyz)" 
     fi
  fi
##min or prod##
  echo $natom > mingeom
  echo "" >> mingeom  
  echo "$geomf" >> mingeom
  createMat.py mingeom 3 $nA
  echo "1" $natom | cat - ConnMat |  sprint2.exe >sprint.out
  paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
  deg_form.sh > deg_form.out
  echo $ef > ${tsdirll}/MINs/${namef}_data
  format.sh $namef ${tsdirll}/MINs ${nfrag_th}
  datas="$(cat ${tsdirll}/MINs/${namef}_data)"
  sqlite3 ${tsdirll}/MINs/data.db "insert into data (name,datas) values ('$namef','$datas');"
  ndis=$(awk '{ndis=$1};END{print ndis}' ${tsdirll}/MINs/${namef}_data )
##insert data into prod.db or min.db
  if [[ ("$ndis" -gt "1") ]] && [ "$namef" != "min0_0" ]; then
     npro=$(sqlite3 ${tsdirll}/PRODs/prod.db "select max(id) from prod" | awk '{print $1+1}')
     namepr=PR${npro}_${namef}
     sqlite3 ${tsdirll}/PRODs/prod.db "insert into prod (natom,name,energy,zpe,g,geom,freq) values ($natom,'$namepr',$ef,$zpef,$g_corrf,'$geomf','$freqf');"
  else
     sqlite3 ${tsdirll}/MINs/min.db "insert into min (natom,name,energy,zpe,g,geom,freq,sigma) values ($natom,'$namef',$ef,$zpef,$g_corrf,'$geomf','$freqf',$sigmaf);"
  fi
##min or prod##

  namer=minr_${name}

  if [ "$program_opt" != "qcore" ]; then
     geomr="$(get_geom_mopac.sh $tsdirll/IRC/${namer}.out | awk 'NR>2{print $0}')"
     freqr="$(get_freq_mopac.sh $tsdirll/IRC/${namer}.out)"
     er=$(awk 'BEGIN{e=0};/HEAT OF FORMATION =/{e=$5};END{print e}' $tsdirll/IRC/${namer}.out )
     zper=$(awk 'BEGIN{zpe=0};/          ZERO POINT ENERGY/{zpe=$4};END{print zpe}' $tsdirll/IRC/${namer}.out )
     sigmar=$(awk '/SYMMETRY NUMBER/{print $NF;exit}' $tsdirll/IRC/${namer}.out)
     g_corrr=$(awk 'BEGIN{zpe=0;h=0;s=0;t='$temperature'}
        /          ZERO POINT ENERGY/{zpe=$4}
        /CALCULATED THERMODYNAMIC PROPERTIES/{ok=1}
     {if(ok==1 && $1 == '$temperature') {
     getline;getline;getline;getline;
     h=$3/1000;s=$5/1000;print zpe+h-t*s;exit}
     }' $tsdirll/IRC/${namer}.out )
  else
     geomr="$(awk '/Final structure/{flag=1; next} /QCORE/{flag=0} flag' $tsdirll/IRC/${namer}.out)"
     freqr="$(awk '/Freq/{flag=1;next}/Lowest/{flag=0}flag' $tsdirll/IRC/${namer}.out)"
     er=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/IRC/${namer}.out )
     zper=$(awk '/ZPE/{zpe=$2};END{print zpe*627.51}' $tsdirll/IRC/${namer}.out )
     sigmar=1
     g_corrr=$(awk '/Gibbs/{gibbs=$NF};END{print gibbs*627.51}' $tsdirll/IRC/${namer}.out )
  fi
#The minima might have failed in the opt process. In that case empty the freq column 
  if [ -z "$freqr" ]; then
     echo "Problems with this minimum: $namer-->thermo calc failed"
     er=0
     zper=0
     g_corrr=0
     freqr=""
     sigmar=1
     if [ "$program_opt" != "qcore" ]; then
        ircn0=$(echo $namer | sed 's@min@@;s@_@ @')
        ircnr=$(echo $ircn0 | awk '{print $2"_irc"$1".xyz"}')
        er=$(awk '/HEAT OF FORMATION/{heat=$(NF-1)};END{print heat}' $tsdirll/IRC/$ircnr)
        geomr="$(awk '/HEAT OF FORMATION/{natom=0};{if(NF==4) {++natom;line[natom]=$0} };END{i=1;while(i<=natom){print line[i];i++}}' $tsdirll/IRC/$ircnr)"
     else
        ets=$(awk '/Energy=/{e0=$2};END{printf "%10.2f\n",e0*627.51}' $tsdirll/${name}.out )
        deltar=$(awk 'BEGIN{act=0};/DVV/{if($NF=="1") act=1};{if(act==1 && NF==6) delta=$2};{if(act==1 && NF==0) {print delta;exit}};{if(act==1 && $2=="QCORE") {print delta;exit}}' $tsdirll/IRC/${name}_ircr.out)
        er=$(echo "$ets + $deltar" | bc -l)
        geomr="$(awk 'NR>2' $tsdirll/IRC/${name}_reverse_last.xyz)" 
     fi
  fi
##min or prod##
  echo $natom > mingeom
  echo "" >> mingeom  
  echo "$geomr" >> mingeom
  createMat.py mingeom 3 $nA
  echo "1" $natom | cat - ConnMat |  sprint2.exe >sprint.out
  paste <(awk 'NF==4{print $1}' mingeom) <(deg.sh) >deg.out
  deg_form.sh > deg_form.out
  echo $er > ${tsdirll}/MINs/${namer}_data
  format.sh $namer ${tsdirll}/MINs ${nfrag_th}
  datas="$(cat ${tsdirll}/MINs/${namer}_data)"
  sqlite3 ${tsdirll}/MINs/data.db "insert into data (name,datas) values ('$namer','$datas');"
  ndis=$(awk '{ndis=$1};END{print ndis}' ${tsdirll}/MINs/${namer}_data )
##insert data into prod.db or min.db
  if [[ ("$ndis" -gt "1") ]] && [ "$namer" != "min0_0" ]; then
     npro=$(sqlite3 ${tsdirll}/PRODs/prod.db "select max(id) from prod" | awk '{print $1+1}')
     namepr=PR${npro}_${namer}
     sqlite3 ${tsdirll}/PRODs/prod.db "insert into prod (natom,name,energy,zpe,g,geom,freq) values ($natom,'$namepr',$er,$zper,$g_corrr,'$geomr','$freqr');"
  else
     sqlite3 ${tsdirll}/MINs/min.db "insert into min (natom,name,energy,zpe,g,geom,freq,sigma) values ($natom,'$namer',$er,$zper,$g_corrr,'$geomr','$freqr',$sigmar);"
  fi
##min or prod##
done
