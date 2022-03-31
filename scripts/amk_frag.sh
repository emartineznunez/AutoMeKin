#!/bin/bash
source utils.sh
sharedir=${AMK}/share
elements2=${sharedir}/elements2
#On exit remove tmp files
tmp_files=(tmp_modeanalysis.inp formula tmp_frag1.xyz tmp_frag2.xyz tmp_frag3.xyz tmp_Frag1 tmp_Frag2 tmp_Frag3 tmp* fort.*)
trap 'err_report2 $LINENO $gauss_line' ERR
trap cleanup EXIT INT

##functions
##Get the formula in M3C format (order of atomic numbers)
function formula_m3c {
   formula=$(awk 'NR==FNR{++t;n[t]=$0};NR>FNR{++s;a[s]=$1;sub(/[0-9]/,"",$1);b[s]=$1};END{for(i=1;i<=t;i++) {for(j=1;j<=s;j++) if(n[i]==b[j]) printf "%s",a[j]}}' ${sharedir}/elements formula)
}

function create_rxyz_prod {
   prod=$(awk '{if($2=="'$prod'")print $NF }' tsdirHL_${molecu}/PRODs/CALC/working/fraglist)
   natprod=$(get_geom_g09.sh tsdirHL_${molecu}/PRODs/CALC/${prod}.log | awk 'END{print NR}')
   echo $natprod > ${m3c}/${prod_name[$i]}
   get_energy_g09_$HLcalc.sh tsdirHL_${molecu}/PRODs/CALC/${prod}.log $noHLcalc | awk '{print "Energy =",$1}' >> ${m3c}/${prod_name[$i]}
   get_geom_g09.sh tsdirHL_${molecu}/PRODs/CALC/${prod}.log  >> ${m3c}/${prod_name[$i]}
   freq="$(awk '/Frequencies/{++j;for(i=3;i<=NF;i++){k=3*j+i-5;freq[k]=$i}};END{for(i=1;i<=k;i++) print freq[i]}' tsdirHL_${molecu}/PRODs/CALC/${prod}.log )"
   nfreq=$(echo "$freq" | awk 'END{print NR}')
   if [ -z "$freq" ]; then nfreq=0 ; fi
   printf "\nFREQUENCIES %s\n" $nfreq >> ${m3c}/${prod_name[$i]}
   echo "$freq" >> ${m3c}/${prod_name[$i]}
   printf "\nSYMMETRY C1\n" >> ${m3c}/${prod_name[$i]}
   printf "ELECTRONIC STATE ??\n" >> ${m3c}/${prod_name[$i]}
}
function create_rxyz_min1 {
   echo $natomi > ${m3c}/$reac_name
   cd FINAL_HL_${molecu}
   select.sh energy min $reacn | awk '{print "Energy =",$1}' >> ${m3c}/$reac_name
   select.sh geom min $reacn  >> ${m3c}/$reac_name
   nfreq=$(select.sh freq min $reacn | wc -l)
   printf "\nFREQUENCIES %s\n" $nfreq >> ${m3c}/$reac_name
   mino=$(awk '{if($2=='$reacn') print $3}' ../tsdirHL_${molecu}/MINs/SORTED/MINlist_sorted | sed 's/rxyz/log/g;s/_/ /' | awk '{print $2}') 
   freq="$(awk '/Frequencies/{++j;for(i=3;i<=NF;i++){k=3*j+i-5;freq[k]=$i}};END{for(i=1;i<=k;i++) print freq[i]}' ../tsdirHL_${molecu}/IRC/$mino )"
   echo "$freq" >> ${m3c}/$reac_name
   printf "\nSYMMETRY C1\n" >> ${m3c}/$reac_name
   printf "ELECTRONIC STATE ??\n" >> ${m3c}/$reac_name
   cd ..
}
function create_rxyz_min2 {
   echo $natomi > ${m3c}/${prod_name[1]}
   cd FINAL_HL_${molecu}
   select.sh energy min $prodn | awk '{print "Energy =",$1}' >> ${m3c}/${prod_name[1]}
   select.sh geom min $prodn  >> ${m3c}/${prod_name[1]}
   nfreq=$(select.sh freq min $prodn | wc -l)
   printf "\nFREQUENCIES %s\n" $nfreq >> ${m3c}/${prod_name[1]}
   mino=$(awk '{if($2=='$prodn') print $3}' ../tsdirHL_${molecu}/MINs/SORTED/MINlist_sorted | sed 's/rxyz/log/g;s/_/ /' | awk '{print $2}')
   freq="$(awk '/Frequencies/{++j;for(i=3;i<=NF;i++){k=3*j+i-5;freq[k]=$i}};END{for(i=1;i<=k;i++) print freq[i]}' ../tsdirHL_${molecu}/IRC/$mino )"
   echo "$freq" >> ${m3c}/${prod_name[1]}
   printf "\nSYMMETRY C1\n" >> ${m3c}/${prod_name[1]}
   printf "ELECTRONIC STATE ??\n" >> ${m3c}/${prod_name[1]}
   cd ..
}

function freqs_ts {
   filema=tmp_modeanalysis.inp
   tsdir=tsdirHL_${molecu}
   tsb=$(basename ${tsdir}/$tso .log)
   pname="PR"$(awk '{if ($3~"'$tsb'") {print $2"_"$3;exit}}' ${tsdir}/PRODs/PRlist_frag | sed 's/.rxyz//')
   sqlite3 ${tsdir}/PRODs/prodhl.db "select natom,geom from prodhl where name='$pname'" | sed 's@|@\n\n@g' | FormulaPROD.sh > /dev/null
   echo file_saddle ${tsdir}/$tso > $filema
   for i in $(seq $nprod)
   do
      prodname=$(awk '{if ($3~"'$tsb'") print $0}' ${tsdir}/PRODs/PRlist_frag | sed 's/+//g' | awk '{n=3+'$i';print $n}')
      awk '/'$prodname'/{print "file_product'$i' '${tsdir}'/PRODs/CALC/"$NF".log";exit}' ${tsdir}/PRODs/CALC/working/fraglist >> $filema
      mass[$i]=$(awk 'BEGIN{mass=0};NR==FNR{m[$1]=$2};NR>FNR{if(NF>1) mass+=m[$1]};END{print mass}' $elements2 tmp_frag${i}.xyz)
   done
   echo ""  >> $filema
   for i in $(seq $nprod)
   do
      echo startnum_product$i  >> $filema
      cat tmp_Frag$i | awk '{print NR,$1}' >> $filema
      echo endnum_product$i  >> $filema
      echo ""  >> $filema
   done
   trans="$(modeanalysis.py $filema | awk '/TRA-ROT IN PRODS/{for(i=1;i<=10^6;i++){getline; if(NF>0 && $1>0) print $1; if(NF==0) exit}}')"
   redmassg=$(awk '/Red. masses/{print $4;exit}' ${tsdir}/$tso)
   redmass=$(echo "scale=4; ${mass[1]}*${mass[2]}/(${mass[1]}+${mass[2]})" | bc -l)
   for i in $(echo ${freq[@]})
   do
      diff_0=10^6
      for j in $(echo ${trans[@]})
      do
         diff_1=$(echo "scale=2; sqrt(($i - $j)^2)" | bc)
         if (( $(echo "$diff_1 < $diff_0" | bc -l) )); then
            diff_0=$diff_1
            match=$j
         fi
      done
      if (( $(echo "$diff_0 < 6" | bc -l)  )); then
         printf "%12s\t asympt=rot\n" "$i" >> $rxyzname
         trans=( "${trans[@]/$match}" )
      elif (( $(echo "$i < 0" | bc -l) )); then
         printf "%12s\t asympt=rxn;rMass=%4s;rMassg=%4s\n" "$i" "$redmass" "$redmassg" >> $rxyzname
      else
         printf "%12s\n" "$i" >> $rxyzname
      fi
   done
   rm -rf tmp*
}

function create_rxyz_ts {
   echo $natomi > $rxyzname
   cd FINAL_HL_${molecu}
   select.sh energy ts $tsn | awk '{print "Energy =",$1}' >> $rxyzname
   select.sh geom ts $tsn  >> $rxyzname
   nfreq=$(select.sh freq ts $tsn | wc -l)
   tso=$(awk '{if($2=='$tsn') print $3}' ../tsdirHL_${molecu}/TSs/SORTED/TSlist_sorted | sed 's/rxyz/log/g')
   printf "\nFREQUENCIES %s\n" $nfreq >> $rxyzname
   freq="$(awk '/Frequencies/{++j;for(i=3;i<=NF;i++){k=3*j+i-5;freq[k]=$i}};END{for(i=1;i<=k;i++) print freq[i]}' ../tsdirHL_${molecu}/$tso )"
   if [ $nprod -gt 1 ]; then
      cd ..
      freqs_ts
      cd FINAL_HL_${molecu}
   else
      for i in $(echo ${freq[@]})
      do
         if (( $(echo "$i < 0" | bc -l) )); then
            redmassg=$(awk '/Red. masses/{print $4;exit}' ../tsdirHL_${molecu}/$tso)
            printf "%12s\t asympt=rxn;rMassg=%4s\n" "$i" "$redmassg" >> $rxyzname
         else
            printf "%12s\n" "$i" >> $rxyzname
         fi
      done
   fi
   printf "\nSYMMETRY C1\n" >> $rxyzname
   printf "ELECTRONIC STATE ??\n" >> $rxyzname
   printf "\nREACTIVES 1\n" >> $rxyzname
   echo $reac_name >> $rxyzname
   printf "\nPRODUCTS %s\n" $nprod >> $rxyzname
   for k in $(seq $nprod)
   do
      echo ${prod_name[$k]} >> $rxyzname
   done
   cd ..
}
function get_min1_name {
   cd FINAL_HL_${molecu}
   er=$(select.sh energy min $reacn | awk '{printf "%20.10f\n",sqrt($1*$1)}')
   cd ..
   rep=0
   xreacn=1
   for i in $(ls ${m3c}/${reac0}-*.rxyz 2> /dev/null)
   do
      nreac=$(echo $i | sed 's@-@ @g;s@.rxyz@@g' | awk '{print $2+1}')
      if [ $nreac -lt 1000 ]; then
         ei=$(awk '/Energy/{printf "%20.10f\n",sqrt($3*$3)}' $i)
         if (( $(echo "scale=6; sqrt(("$ei"-"$er")*("$ei"-"$er"))*627.51 < "$diff""  | bc -l) )); then
            reac_name=$(basename $i)
            rep=1
            break
         fi
         if [ $nreac -gt $xreacn ]; then xreacn=$nreac ; fi
      fi
   done
   if [ $rep -eq 0 ];then  reac_name=${reac0}"-"${xreacn}.rxyz; fi
}
function get_min2_name {
   cd FINAL_HL_${molecu}
   er=$(select.sh energy min $prodn | awk '{printf "%20.10f\n",sqrt($1*$1)}')
   cd ..
   rep=0
   xprodn=1
   for i in $(ls ${m3c}/${reac0}-*.rxyz 2> /dev/null)
   do
      nreac=$(echo $i | sed 's@-@ @g;s@.rxyz@@g' | awk '{print $2+1}')
      if [ $nreac -lt 1000 ]; then
         ei=$(awk '/Energy/{printf "%20.10f\n",sqrt($3*$3)}' $i)
         if (( $(echo "scale=6; sqrt(("$ei"-"$er")*("$ei"-"$er"))*627.51 < "$diff""  | bc -l) )); then
            prod_name[1]=$(basename $i)
            rep=1
            break
         fi
         if [ $nreac -gt $xprodn ]; then xprodn=$nreac ; fi
      fi
   done
   if [ $rep -eq 0 ];then prod_name[1]=${reac0}"-"${xprodn}.rxyz; fi
}

function get_prod_name {
   prod="$(awk '{if($2=="'$prod'")print $NF }' tsdirHL_${molecu}/PRODs/CALC/working/fraglist)"
   er=$(get_energy_g09_$HLcalc.sh tsdirHL_${molecu}/PRODs/CALC/${prod}.log $noHLcalc | awk '{printf "%20.10f\n",sqrt($1*$1)}')
   rep=0
   xprodn=1
   for j in $(ls ${m3c}/${prod0[$i]}-*.rxyz 2> /dev/null)
   do
      ei=$(awk '/Energy/{printf "%20.10f\n",sqrt($3*$3)}' $j)
      if (( $(echo "scale=6; sqrt(("$ei"-"$er")*("$ei"-"$er"))*627.51 < "$diff""  | bc -l) )); then
         prod_name[$i]=$(basename $j)
         rep=1
         break
      fi
      prodn=$(echo $j | sed 's@-@ @g;s@.rxyz@@g' | awk '{print $2+1}')
      if [ $prodn -gt $xprodn ]; then xprodn=$prodn ; fi
   done
   if [ $rep -eq 0 ];then  prod_name[$i]=${prod0[$i]}"-"${xprodn}.rxyz; fi
}

function create_rxyz {
   n=1000
   for tsn in $(awk 'NR>2{print $1}' $rxnetfi)
   do
      ((n=n+1))
      reacn=$(awk '{if($1=='$tsn') print $4}' $rxnetfi)
      nprod=$(sed 's/+/ /g' $rxnetfi | awk '{if($1=='$tsn') print NF-6}')
      echo ts $tsn
      rxyzname=${rxyzname0}-${n}.rxyz
##Check for redundant names or for like structures with different names
      reac0=$(basename ${rxyzname0})
###react_name might be different from reac, which is used to draw the data
###reac is the real name
###check for redundant structures
      get_min1_name
#create rxyz for reactive 1
      create_rxyz_min1
#
      for i in $(seq $nprod)
      do
         if [ $nprod -eq 1 ]; then
            prod0[1]=$(basename ${rxyzname0})
            prodn=$(awk '{if($1=='$tsn') print $NF}' $rxnetfi)
            get_min2_name
            create_rxyz_min2
         else
            prn=$(sed 's/PR//g;s/\://g' $rxnetfi | awk '{if($1=='$tsn') print $6}')
            sed 's/+//g' tsdirHL_${molecu}/PRODs/PRlist_frag | awk '{if($2=='$prn') {n=3+'$i';print $n}}' | sed 's/\.q/ /g' | awk '{print $1}' | sed 's/[^0-9]/\n&/g'  > formula
            formula_m3c
            ext=$(sed 's/+//g' tsdirHL_${molecu}/PRODs/PRlist_frag | awk '{if($2=='$prn') {n=3+'$i';print $n}}' | sed 's/\.q/ /g' | awk '{print $2}')
            ext0=$(sed 's/+//g' tsdirHL_${molecu}/PRODs/PRlist_frag | awk '{if($2=='$prn') {n=3+'$i';print $n}}' | sed 's/\.q/ /g;s/-/ /g' | awk '{print $2}')
            prod0[$i]=${formula}.q${ext0}
            prod=$(sed 's/+//g' tsdirHL_${molecu}/PRODs/PRlist_frag | awk '{if($2=='$prn') {n=3+'$i';print $n}}')
            get_prod_name
            create_rxyz_prod
         fi
###prod_name might be different from prod, which is used to draw the data
#prod_name might be redundant or it might need to be that of like structures
#create rxyz for prod i
      done

#create rxyz for ts 
      create_rxyz_ts
   done
}

function set_variables {
   if [ ! -f $inp ]; then
      echo $inp file not found
      exit 1
   fi
   molecu=$(awk '{if($1=="molecule") print $2}' $inp)
   if [ -f ${molecu}.xyz ]; then
      natomi=$(awk 'NR==1{print $1}' ${molecu}.xyz)
   fi
   charge=$(awk 'BEGIN{ch=0};{if($1=="charge") ch=$2};END{print ch}' $inp | sed 's/+//g')
   multip=$(awk 'BEGIN{mu=1};{if($1=="mult") mu=$2};END{print mu}' $inp | sed 's/+//g')
   xyzfile=${molecu}.xyz
   rxnetfi=FINAL_HL_${molecu}/RXNet.rel
   if [ ! -f $rxnetfi ]; then
      echo $rxnetfi file not found
      exit 1
   fi
   FormulaPROD.sh ${xyzfile} | sed 's/[^0-9]/\n&/g' > formula
   formula_m3c
   rxyzname0=${m3c}/${formula}.q${charge}.m${multip}
}

#Read inputfile
cwd=$PWD
sharedir=${AMK}/share
exe=$(basename $0)
if [ $# -eq 0 ]; then usages "One argument is required" ; fi
inputfile=$1
if [ ! -f $inputfile ]; then
   echo Are you in the right directory?
   exit 1
fi
###Reading stuff from inputfile
read_input
llcheck=$(awk 'BEGIN{p=0};{if($1=="LowLevel")p=1};END{print p}' $inputfile)
if [ $llcheck -eq 0 ]; then
   echo Please use LowLevel keyword in the inputfile
   exit 1
fi
if [ "$program_opt" = "qcore" ]; then
   echo "Qcore is not supported with "
   echo "     this workflow          "
   echo "Please use mopac as LowLevel"
   exit 1
fi
min_size=$(awk 'BEGIN{ms=4};{if($1=="minsize") ms=$2};END{print ms}' $inputfile)
nsys=$(awk 'BEGIN{s=0};{if($1=="systems") s=$2};END{print s}' $inputfile)
m3c=${cwd}/M3Cinp
rm -rf ${m3c} && mkdir $m3c
diff=0.01
ntasks=50
niter=30
rtasksll=50
rtaskshl=24
##Start the workflow
if [ ! -d FINAL_LL_${molecule} ]; then
   printf "\n=========================================\n"
   printf "   Running Low-Level calcs for:   %s\n" $molecule
   printf "=========================================\n"
   time llcalcs.sh $inputfile $ntasks $niter $rtasksll > llcalcs.log 
else
   printf "\n=========================================\n"
   printf "   Low-Level calcs completed for: %s\n" $molecule
   printf "=========================================\n"
fi
if [ ! -d FINAL_HL_${molecule} ]; then
   printf "\n=========================================\n"
   printf "   Running High-Level calcs for: %s\n" $molecule
   printf "=========================================\n"
   time hlcalcs.sh $inputfile $rtaskshl > hlcalcs.log 
else
   printf "\n=========================================\n"
   printf "   High-Level calcs completed for: %s\n" $molecule
   printf "=========================================\n"
fi

#M3Cinp
inp=$inputfile
set_variables
create_rxyz

##Now the fragments
rxnet=FINAL_HL_${molecule}/RXNet.rel
echo Further fragmentations of the following fragments: > Table_frag 
if [ -f $rxnet ]; then
   n=0 
   m=0
   for i in $(awk '{if($6~/PR/) print $6}' $rxnet | sed 's/PR//g;s/://g')
   do
      skip=0
      for j in $(echo ${pr[@]})
      do
          if [ $i -eq $j ]; then skip=1; fi
      done
      if [ $skip -eq 1 ]; then continue; fi
      ((n=n+1)) 
      pr[n]=$i
      for k in $(awk '{if($2=='$i') for(i=4;i<=NF;i++) print $i}' tsdirHL_${molecule}/PRODs/PRlist_frag | sed 's/+//g;s/-/ /g' | awk '{print $1}')
      do
          natoms=$(awk '/Charge/{for(i=1;i<=1e6;i++) {getline;if(NF==4)++n;if(NF==0) {print n;exit}}}' tsdirHL_${molecule}/PRODs/CALC/${k}-*.log)
          if [ $natoms -ge $min_size ]; then
             skip2=0
             for l in $(echo ${fr[@]})
             do
                 if [ "$k" =  "$l" ]; then skip2=1; fi
             done
             if [ $skip2 -eq 1 ]; then continue; fi
             ((m=m+1))
             fr[m]=$k
             kraw=$(echo $k | sed 's/\./ /g' | awk '{print $1}')
             mfra=$(echo $k | sed 's/\.m/ /g' | awk '{print $NF}')
             frag_name=$(awk '{if($6=="PR"'$i'":") {for(k=7;k<=NF;k++) if($k~/'$kraw'/) {print $k;exit}}}' $rxnet)
             echo $frag_name $mfra $k >> Table_frag
          fi
      done
   done  
else
   echo ERROR
   echo $rxnet is not avaiable
   exit 1
fi
##Eventually update Table_frag from the inputfile
for i in $(seq $nsys)
do
    sys=$(awk '{if($1=="systems"){for(i=1;i<='$i';i++) {getline;if(i=='$i') print $1}}}' $inputfile)
    msys=$(awk '{if($1=="systems"){for(i=1;i<='$i';i++) {getline;if(i=='$i') print $2}}}' $inputfile)
    existing=$(awk 'BEGIN{e=0};{if($1=="'$sys'") e=1};END{print e}' Table_frag)
    skip=$(awk 'BEGIN{s=0};{if($1=="'$sys'" && $2=='$msys') s=1};END{print s}' Table_frag)
    if [ $skip -eq 1 ]; then continue; fi
    file=$(awk 'BEGIN{f=0};/'$sys'/{f=$3};END{print f}' Table_frag)
    if [ $existing -eq 1 ]; then
       echo $sys $msys $file >> Table_frag
    elif [ $existing -eq 0 ]; then
       if [ ! -f ${sys}.xyz ]; then
          echo ERROR
          echo Please provide an XYZ file for $sys
          exit 1
       fi
       echo $sys $msys ${sys}.xyz >> Table_frag
    fi 
done
##Run calcs for frags
for ifrag in $(awk 'NR>1{print NR}' Table_frag)
do 
    s=$(awk 'NR=='$ifrag'{print $1}' Table_frag)
    m=$(awk 'NR=='$ifrag'{print $2}' Table_frag)
    f=$(awk 'NR=='$ifrag'{print $3}' Table_frag)
    ms=$(echo "scale=1; ($m-1)/2" | bc )
    if [ "$s" != "$(echo $s | sed 's/+/ /g')" ]; then
       c=$(echo $s | sed 's/+/ /g' | awk 'BEGIN{c=0};{c+=$2;if(c==0) c=1;print c}' )
    elif [ "$s" != "$(echo $s | sed 's/-/ /g')" ]; then
       c=$(echo $s | sed 's/-/ /g' | awk 'BEGIN{c=0};{c-=$2;if(c==0) c=-1;print c}' )
    fi
    dir=${s}_${m}
    if [ ! -d ${dir} ]; then mkdir $dir ; fi
    cd ${dir} 
#    echo Constructing directory: $dir 
    if [ ! -d FINAL_LL_frag ]; then
       if [ "$f" = "${s}".xyz ];then
          cp ${cwd}/$f frag.xyz
       else
          get_geom_g09.sh ${cwd}/tsdirHL_${molecule}/PRODs/CALC/${f}-*.log | awk '{l[NR]=$0;++n};END{print n,"\n";for(i=1;i<=n;i++) print l[i]}' > frag.xyz
       fi
       awk '$1!="etraj"{
       if($1=="molecule") 
           print $1,"frag"
       else if($1=="LowLevel") { 
           if('$m'>=3) 
              print $1,$2,$3,"uhf ms="'$ms' 
           else
              print $1,$2,$3}
       else if($1=="mult") 
           print $1,'$m'
       else if($1=="charge") 
           print $1,'$c'
       else 
           print $0}' ${cwd}/$inputfile | sed '/Fragmentation/,$d' > frag.dat
       printf "\n=========================================\n"
       printf "   Running Low-Level calcs for: %s %s\n" $s $m
       printf "=========================================\n"
       time llcalcs.sh frag.dat $ntasks $niter $rtasksll > llcalcs.log 
    else
       printf "\n=========================================\n"
       printf "   Low-Level calcs completed for: %s %s\n" $s $m
       printf "=========================================\n"

    fi
    if [ ! -d FINAL_HL_frag ]; then
       printf "\n=========================================\n"
       printf "   Running High-Level calcs for: %s %s\n" $s $m
       printf "=========================================\n"
       time hlcalcs.sh frag.dat $rtaskshl > hlcalcs.log 
    else
       printf "\n=========================================\n"
       printf "   High-Level calcs completed for: %s %s\n" $s $m
       printf "=========================================\n"
    fi
#M3Cinp
    inp=frag.dat
    set_variables
    create_rxyz
    cd ${cwd}
done

