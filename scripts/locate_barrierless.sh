#!/bin/bash

source utils.sh
#On exit remove tmp files
tmp_files=(fort.* tmp_pf tmp_nf tmp_geom tmp_formula tmp_tag tmp_min tmp* batch* mopac.* bfgs.log barrless_tag.log)
trap 'err_report $LINENO' ERR
trap cleanup EXIT INT
exe=$(basename $0)
cwd=$PWD
#tag is LL for low-level
tag=LL

if [ -f amk.dat ];then
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
#reading input
read_input
###
inter=0
export inter

##Build PRODs again in case of multiple runs of this script
cp ${molecule}_ref.xyz ${molecule}.xyz
rm -rf tsdir${tag}_${molecule}/TSs/ts.db
rm -rf tsdir${tag}_${molecule}/PRODs
sqlite3 tsdir${tag}_${molecule}/MINs/data.db "delete from data where name like '%minf%'"
sqlite3 tsdir${tag}_${molecule}/MINs/data.db "delete from data where name like '%minr%'"
sqlite3 tsdir${tag}_${molecule}/MINs/min.db "delete from min where name like '%minf%'"
sqlite3 tsdir${tag}_${molecule}/MINs/min.db "delete from min where name like '%minr%'"
if [ $# -eq 0 ]; then
   rxn_network.sh
else
   rxn_network.sh $1
fi
kmc.sh
natom=$(sqlite3 tsdir${tag}_${molecule}/MINs/min.db "select natom from min where id=1")
echo Number of atoms: $natom
###

##Remove barrless dissociations from prod in case of previous calcs and make PRlist_tags file
sqlite3 tsdir${tag}_${molecule}/PRODs/prod.db "delete from prod where name like '%min_diss%'"
sed -i '/min_diss/d' tsdir${tag}_${molecule}/PRODs/PRlist
rm -rf tsdir${tag}_${molecule}/PRODs/PRlist_tags.log
###

for name in $(sqlite3 tsdir${tag}_${molecule}/PRODs/prod.db "select name from prod")
do
   named=$(echo $name | sed 's/_min/ min/' | awk '{print $2}')
   sqlite3 tsdir${tag}_${molecule}/PRODs/prod.db "select energy,formula from prod where name='$name'" | awk '{for (i=1;i<=NF;i++) printf "%s",$i;printf "\n"}' | sed 's@|@ @g' >tmp_pf
   paste tmp_pf tsdir${tag}_${molecule}/PRODs/${named}_tag  >> tsdir${tag}_${molecule}/PRODs/PRlist_tags.log
done
if [ -f tsdir${tag}_${molecule}/PRODs/PRlist_tags.log ]; then
   cp tsdir${tag}_${molecule}/PRODs/PRlist_tags.log tsdir${tag}_${molecule}/PRODs/PRlist_tags_barr.log
fi

##
if [ -f tsdir${tag}_${molecule}/MINs/min.db ]; then
   e0=$(sqlite3 tsdir${tag}_${molecule}/MINs/min.db "select energy from min where name='min0_0'")
else
   e0=$(awk '/FINAL HEAT OF FORMATION =/{e0=$6};END{print e0}' ${molecule}_freq.out )
fi
nbl=0
echo " TS #    DE(kcal/mol)    -------Path info--------" > tsdir${tag}_${molecule}/KMC/RXN_barrless
###Locate the minima
mdiss.sh $tag
if [ -f tsdir${tag}_${molecule}/min_diss.inp ]; then
   for i in $(awk '{print $1}' tsdir${tag}_${molecule}/min_diss.inp )
   do
      echo ""
      echo Finding barrierless paths from MIN $i
      sqlite3 tsdir${tag}_${molecule}/MINs/SORTED/mins.db "select natom,geom from mins where id='$i'" | sed 's@|@\n\n@g'  > ${molecule}.xyz
      #EMN only one fragment
      form="$(cat ${molecule}.xyz | FormulaPROD.sh )"
      nfrag=$(awk '{print $1}' tmp_nf)
      if [ $nfrag -gt 1 ]; then 
         echo Fragmented minimum
         continue 
      fi
      #EMN --> provisional
      nchan=$(Heuristics.py 0 1)
      re='^[0-9]+$'
      if ! [[ $nchan =~ $re ]] ; then 
         echo " Error: No neighbors for " $nchan
         exit 1
      fi
###EMN
      if [ ! -f tsdir${tag}_${molecule}/ts_bonds.inp ]; then
         echo Heuristics.py failed to build barrless_bonds file
         echo Skiping this MIN...
         continue
      fi
      echo "Found $nchan possible channels"
###EMN
      doparallel "runbarless.sh {1} $molecule $cwd $e0" "$(seq 1 $nchan)"
      #echo "threshold $emaxts kcal/mol"
      for chan in $(seq $nchan)
      do
         l1=$(awk 'NR=='$chan'{print $2+1}' tsdir${tag}_${molecule}/ts_bonds.inp)
         l2=$(awk 'NR=='$chan'{print $3+1}' tsdir${tag}_${molecule}/ts_bonds.inp)
         echo "Channel ${chan}: breakage of bond ${l1}-${l2}"
         if [ $(awk 'BEGIN{a=0};/Abort/{a=1};END{print a}' batch${chan}/amk.log ) -eq 1 ]; then 
            grep -B1 Abort batch${chan}/amk.log | awk 'NR==1'
            continue 
         fi
         if [ -f batch${chan}/prod.xyz ]; then
            cat batch${chan}/prod.xyz | awk '{if(NR==2) {print ""} else print $1,$2,$3,$4}' > tmp_geom 
            formula0="$(cat tmp_geom | FormulaPROD.sh )"
            formula=$(echo "$formula0" | sed 's@ + @+@g')
            nfrag=$(awk '{print $1}' tmp_nf)
            if [ $nfrag -gt 2 ]; then continue ; fi
            if [ $nfrag -eq 1 ]; then continue ; fi
            echo "$formula" > tmp_formula
            tag_prod.py tmp_geom | sed 's@-0.000@0.000@g' > tmp_tag
            tagpr="$(cat tmp_tag)" 
            paste tmp_formula tmp_tag > barrless_tag.log

            if [ -f tsdir${tag}_${molecule}/PRODs/PRlist_tags_barr.log ]; then
               rm -rf tmp_min
               for k in $(awk '{print NR}' tsdir${tag}_${molecule}/PRODs/PRlist_tags_barr.log)
               do
                  awk 'BEGIN{label=0};NR>2{if($10=="PROD" && $11=='$k') label=$8};END{print label}' tsdir${tag}_${molecule}/KMC/RXNet_long.cg >> tmp_min
               done
               paste tmp_min tsdir${tag}_${molecule}/PRODs/PRlist_tags_barr.log | awk '{if($1>0) {$2="";print $0}}' >> barrless_tag.log
               new=$(awk 'BEGIN{new=1}
                    NR==1{formula=$1;for(i=2;i<=NF;i++) {++t;tag[t]=$i} }
                    NR>1{t=0;diff=0;for(i=3;i<=NF;i++) {++t;diff+=($i-tag[t])^2};if($2==formula && diff==0 && $1=='$i') new=0}
                    END{print new}' barrless_tag.log)
            else
               new=1
            fi
#check energy also compared to threshold 
            pe=$(awk '/Product energy rel/{print $(NF-1)}' batch${chan}/amk.log )     
            pea=$(awk '/Product energy abs/{print $(NF-1)}' batch${chan}/amk.log )     
#add barrierless channel in file RXN_barrless
            if [ $new -eq 1 ] &&  (( $(echo "$pe < $emaxts" |bc -l) )); then 
#Check with NEB that there is not saddle point (it might have gone unnoticed
#If a saddle is found--> the route is discarded and the TS is included in tslist and also in tslist_from_barrless
#This new TS is not updated in FINAL_LL_molecule, but it will be taken into account at HL
               cd batch${chan} && neb_barrless.py > neb_barrless.log 
               cd $cwd  
               if [ -f batch${chan}/ts.log ]; then
                  if [ $(awk 'BEGIN{f=0};/TS optimized and added/{f=1};END{print f}' batch${chan}/ts.log) -eq 1 ]; then
                     echo "A saddle point has been found in this path" 
                     echo "This saddle point was found connecting MIN $i with $formula0" 
                     tail -1 tsdir${tag}_${molecule}/tslist >> tsdir${tag}_${molecule}/tslist_from_barrless
                     continue 
                  fi 
               fi
               echo "***** BARRIERLESS RXN. ENERGY OF FRAGMENTS: $pe *****"
               nbl=$((nbl+1))
#xyz in min_diss file
               geom="$(cat tmp_geom | awk 'NR>2{print $0}')"
               id=$(sqlite3 tsdir${tag}_${molecule}/PRODs/prod.db "select max(id) from prod")
               id=$((id+1)) 
               zpe=0
               g=0
               freq=""
               name=PR${id}_min_diss_${i}_${chan}
               sqlite3 tsdir${tag}_${molecule}/PRODs/prod.db "insert into prod (natom,name,energy,zpe,g,geom,freq,formula) values ($natom,'$name',$pea,$zpe,$g,'$geom','$freq','$formula0');"
               echo "PROD ${id} min_diss_${i}_${chan}.rxyz" >> tsdir${tag}_${molecule}/PRODs/PRlist 
               echo $pea $formula "$tagpr"  >> tsdir${tag}_${molecule}/PRODs/PRlist_tags.log
               echo "$nbl $pe MIN $i <-->  PROD ${id}" >> tsdir${tag}_${molecule}/KMC/RXN_barrless
            else
               echo "There is a path to these fragments via a saddle point"
            fi
         else
            echo Product could not be optimized
         fi
      done
      rm -rf tmp*
   done
   npr=0
   for pr in $(awk '{print $2}' tsdir${tag}_${molecule}/PRODs/PRlist_tags.log)
   do
      npr=$((npr+1)) 
      form="$(echo $pr | sed 's@+@ + @g')"
      echo "PROD $npr "$form"" >> tsdir${tag}_${molecule}/KMC/RXN_barrless
   done
else
   echo No minima have been found from which barrierless paths are found 
fi
