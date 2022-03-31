#!/bin/bash

source utils.sh
#remove tmp files
tmp_files=(ee* freq* gcorr* geom* zpe* tmp_geom tmp_rxyz tmp*)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT

exe=$(basename $0)
cwd=$PWD
inputfile=amk.dat

##
read_input
##

if [ ! -f ${tsdirhl}/PRODs/PRlist_frag ]; then
   echo ${tsdirhl}/PRODs/PRlist_frag does not exist
   echo Exiting makerxyz...
   exit 1 
fi

rm -rf frag_warnings
working=$tsdirhl/PRODs/CALC/working
sqlite3 ${tsdirhl}/PRODs/CALC/prodfhl.db "drop table if exists prodfhl; create table prodfhl (id INTEGER PRIMARY KEY,natom INTEGER, name TEXT,energy REAL,zpe REAL,g REAL,geom TEXT,freq TEXT,formula TEXT );"
ext=0
sign=(0 1 -1 2 -2 3 -3)
for line in $(awk 'NR>1{print NR}' ${tsdirhl}/PRODs/PRlist_frag)
do
    ((ext=ext+1))
    name="PR"$(awk 'NR=='$line'{print $2"_"$3}' ${tsdirhl}/PRODs/PRlist_frag)
    echo "Doing calcs for prod # $ext"
    namedb=$(basename $name .rxyz)
    rm -rf ee$ext freq$ext zpe$ext gcorr$ext geom$ext geom0$ext 
    nfrag=$(awk 'NR=='$line'{for(i=4;i<=NF;i++) if($i!="+")++nf};END{print nf}' ${tsdirhl}/PRODs/PRlist_frag)
    for j in $(seq $nfrag)
    do
       frag=$(awk 'NR=='$line'{for(i=4;i<=NF;i++) if($i!="+") {++nf;fr[nf]=$i}};END{print fr['$j']}' ${tsdirhl}/PRODs/PRlist_frag)
       file0=${tsdirhl}/PRODs/CALC/${frag}.log
#If it is repeated, look for the original file
       if [ ! -f $file0 ]; then
          file0a=$(basename $file0 .log)
          file0b=$(cat $working/fraglist | awk '{if($2=="'$file0a'") {print $3;exit}}' ) 
          file=${tsdirhl}/PRODs/CALC/${file0b}.log
       else
          file=$file0
       fi
###Check if the fragment has been optimized
       if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
          calc=$(awk 'BEGIN{e=1};/Normal termi/{e=0};/Error termi/{e=1};END{print e}' $file)
       elif [ "$program_hl" = "qcore" ];then
          calc=$(awk 'BEGIN{e=0};/Error/{e=1};END{print e}' $file)
       fi
###If error pick the smallest label isomer without error
       if [ $calc -eq 1 ]; then
          na=$(basename $file .log | awk 'BEGIN{FS="-"};{print $1}')
          nn0=$(basename $file .log | awk 'BEGIN{FS="-"};{print $2}')
          mt=10000
          for i in $(ls ${tsdirhl}/PRODs/CALC/$na*.log)
          do
             if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
                calc=$(awk 'BEGIN{e=1};/Normal termi/{e=0};/Error termi/{e=1};END{print e}' $i)
             elif [ "$program_hl" = "qcore" ];then
                calc=$(awk 'BEGIN{e=0};/Error/{e=1};END{print e}' $i)
             fi
             nn=$(basename $i .log | awk 'BEGIN{FS="-"};{print $2}')
             if [ $calc -eq 0 ]; then
                if [ $nn -lt $mt ]; then mt=$nn; fi
             fi
          done
          if [ $mt -eq 10000 ]; then mt=$nn0; fi
          echo Warning: $file is not optimized  >> frag_warnings
          file=${tsdirhl}/PRODs/CALC/${na}-${mt}.log
          echo Using $file instead >> frag_warnings
          echo "" >> frag_warnings
       fi
###
       if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ] ; then
          etemp=$(get_energy_g09_$HLcalc.sh $file $noHLcalc)
          zpetemp=$(get_ZPE_g09.sh $file)
          zpeok=$(get_ZPE_g09.sh $file | wc -l)
          get_energy_g09_$HLcalc.sh $file $noHLcalc >> ee$ext 
          get_geom_g09.sh $file > tmp_geom
          com.sh > geom0$ext
          awk '{print $1,$2+5*'${sign[$j]}',$3,$4}' geom0$ext >> geom$ext
          get_ZPE_g09.sh $file >> zpe$ext 
          get_freq_g09.sh $file >> freq$ext
          sigma=$(awk 'BEGIN{IGNORECASE=1};/SYMMETRY NUMBER/{print $NF;exit}' $file | sed 's@\.@@' )
       elif [ "$program_hl" = "qcore" ]; then
          etemp=$(awk 'NR==1{print $2}' $file)
          zpetemp=$(awk '/ZPE/{printf "%12.2f",$2*627.51}' $file)
          zpeok=$(awk 'BEGIN{ok=0};/ZPE/{if($2>0) ok=1};END{print ok}' $file)
          echo $etemp >> ee$ext 
          nameg=$(basename $file .log | sed 's@\.@_@g;s@-@_@g')
          if [ -f ${tsdirhl}/PRODs/CALC/${nameg}_opt.xyz ];then
             awk 'NR>2{print $0}' ${tsdirhl}/PRODs/CALC/${nameg}_opt.xyz > tmp_geom
          else
             touch tmp_geom
          fi
          com.sh > geom0$ext
          awk '{print $1,$2+5*'${sign[$j]}',$3,$4}' geom0$ext >> geom$ext
          echo $zpetemp >> zpe$ext 
          if (( $(echo "$zpetemp > 0.1" |bc -l) )); then
             awk '/Freq/{for(i=1;i<=1000;i++) {getline;if(NF>1) exit;print $1}}' $file >> freq$ext
          fi
          sigma=1
       fi
##create temp file tmp_rxyz from sqlite tables
       cat geom0$ext | wc -l  >tmp_rxyz 
       echo E= $etemp zpe= $zpetemp g_corr= 0 sigma= $sigma >>tmp_rxyz
       cat geom0$ext >> tmp_rxyz
       if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ];then
          get_freq_g09.sh $file | awk '{print sqrt($1*$1)}'  >> tmp_rxyz
       elif [ "$program_hl" = "qcore" ];then
          zpetemp=$(awk '/ZPE/{printf "%12.2f",$2*627.51}' $file)
          if (( $(echo "$zpetemp > 0.1" |bc -l) )); then
             awk '/Freq/{for(i=1;i<=1000;i++) {getline;if(NF>1) exit;print sqrt($1*$1)}}' $file >> tmp_rxyz
          fi
       fi
###Calculate g using saulo's thermochem.py 
#If it does not optimize -- > continue
#case 1. Energy is not obtained
       if [ -z $etemp ]; then 
          echo Warning: $file is not optimized  >> frag_warnings
          echo Warning: $file is not optimized  
          echo "" >> frag_warnings
          etemp=0 
          zpetemp=0
          echo "0" >> gcorr$ext
          continue
       fi
#case 2. energy is obtained but zpe is not obtained
       if [ $zpeok -eq 0 ]; then 
          echo Warning: $file is not optimized  >> frag_warnings
          echo Warning: $file is not optimized  
          echo "" >> frag_warnings
          zpetemp=0
          echo "0" >> gcorr$ext
          continue
       fi
       mult="$(awk '/Multiplicity/{print $NF}' $file)"
       thermochem.py tmp_rxyz $temperature hl $mult | awk '/Thermal correction to Gib/{getline;getline;print $3}' >> gcorr$ext
    done
    e=$(awk '{e+=$1};END{printf "%14.9f\n",e}' ee$ext)
    gcorr=$(awk '{e+=$1};END{printf "%14.9f\n",e}' gcorr$ext)
    zpe=$(awk '{e+=$1};END{printf "%8.2f\n",e}' zpe$ext)
    natom=$(awk '{if(NF==4) ++natom};END{print natom}' geom$ext)
    geom=$(cat geom$ext)
    freq=$(cat freq$ext)
    formula="$(sqlite3 $tsdirhl/PRODs/prodhl.db "select formula from prodhl where name='$namedb'")"
###insert into prodfhl
    sqlite3 ${tsdirhl}/PRODs/CALC/prodfhl.db "insert into prodfhl (natom,name,energy,zpe,g,geom,freq,formula) values ($natom,'$namedb',$e,$zpe,$gcorr,'$geom','$freq','$formula');"
    rm -rf ee$ext freq$ext zpe$ext gcorr$ext geom$ext geom0$ext 
done

##Just in case freq files are not deleted
rm -rf freq*
echo "End of calcs"
