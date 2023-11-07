#!/bin/bash
#default sbatch FT2 resources
#SBATCH --time=08:00:00
#SBATCH -n 4
#SBATCH --output=PRODs-%j.log
#_remove_this_in_ft_SBATCH --partition=cola-corta,thinnodes
#SBATCH --ntasks-per-node=2
#SBATCH -c 12
#
# SBATCH -p shared --qos=shared
# SBATCH --ntasks-per-node=2
# SBATCH -c 10

exe="PRODs.sh"
sharedir=${AMK}/share
elements=${sharedir}/elements
source utils.sh
#remove tmp files
tmp_files=(tmp_geom tmp_nf tmp* ffchmu)
trap cleanup EXIT INT
#current working dir
cwd=$PWD

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi

#####
read_input
##Initialize here the total number of frags
tnf=0
##Creating dir to make ab initio calcs
dir=$tsdirhl/PRODs/CALC
##total charge charge_t
charge_t=$charge
##Creating working dir to compare frags
working=$tsdirhl/PRODs/CALC/working
if [ ! -d "$dir" ]; then mkdir $dir ; fi
rm -rf $working && mkdir $working
echo "Screening" > $working/fraglist_screened
sqlite3 $dir/inputs.db "drop table if exists gaussian; create table gaussian (id INTEGER PRIMARY KEY,name TEXT, input TEXT);"

number=0
m=0
echo "PR list with frags" > $tsdirhl/PRODs/PRlist_frag
for name in $(sqlite3 ${tsdirhl}/PRODs/prodhl.db "select name from prodhl")
do
   ((number=number+1))
   if [ $(echo "$name" | awk 'BEGIN{p=0};/diss/{p=1};END{print p}') -eq 1 ]; then
      logdir=${tsdirhl}/IRC/DISS
   else
      logdir=${tsdirhl}/IRC
   fi
   line[$number]=$(awk '{if($2=="'$number'") print $0}' ${tsdirhl}/PRODs/PRlist)
   name0=$(echo $name | sed 's@_min@ min@g' | awk '{print $2}')
   formula="$(sqlite3 ${tsdirhl}/PRODs/prodhl.db "select natom,geom from prodhl where name='$name'" | sed 's@|@\n\n@g' | FormulaPROD.sh)"
   nfrag=$(awk '{print $1}' tmp_nf)
   echo "Number: $number Name: $name # of frags: $nfrag"
   echo line number "${line[$number]}"
   rm -f ffchmu
   echo names: $name $name0 $nfrag
   echo logdir: $logdir
   charge_calc=1
   for j in $(seq 1 $nfrag)
   do
      if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
         if [ $charge_calc -eq 1 ]; then
            charge=$(awk '{if(NR == FNR) {n[NR]=$1;++naf}}
            /Fitting point charges/{q=0;getline;getline;getline
            for(i=1;i<='$natom';i++){getline; for(j=1;j<=naf;j++){if($1==n[j]) q+=$3} }  }
            END{printf "%.0f\n",q}'  tmp_Frag$j ${logdir}/${name0}.log | sed 's/-0/0/')
            if (( $(echo "sqrt(($charge)^2) > sqrt(($charge_t)^2)" |bc -l) )) && [ $j -eq 1 ]; then
               echo Setting charge_i = total charge 
               charge_calc=0
               charge=$charge_t 
            fi
         else
            charge=0
         fi
      elif [ "$program_hl" = "qcore" ]; then
         charge=$(awk '{if(NR == FNR) {n[NR]=$1;++naf}}
         /Charges/{q=0
         for(i=1;i<='$natom';i++){getline; for(j=1;j<=naf;j++){if(i==n[j]) q+=$1} }  }
         END{printf "%.0f\n",q}'  tmp_Frag$j ${logdir}/${name0}.log | sed 's/-0/0/')
      fi
      echo charge: $charge

      noue=$(awk '{if(NR == FNR) n[$1]=NR}; {if(NF==4) noe+=n[$1]};END{print (noe-'$charge')%2}'  $elements tmp_frag$j.xyz)
      
      if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
         mult=$(awk 'BEGIN{ne=0;net[0]=0;net[1]=0;net[2]=0};{if(NR == FNR) {n[NR]=$1;++naf}}
         /N A T U R A L   A T O M I C   O R B I T A L/{nocc=0}
         /Summary of Natural Population Analysis:/{++nocc;getline;getline;getline;getline;getline;
         for(i=1;i<='$natom';i++) { getline; for(j=1;j<=naf;j++) {if($2==n[j]) net[nocc] += $NF } } }
         END{
         if (net[2]==0 && net[3]==0)
            print '$noue'+1
         else
            {
            diff=net[2]-net[3];noue=int(sqrt(diff*diff)+0.5);print noue+1
            }
          }' tmp_Frag$j ${logdir}/${name0}.log )
      elif [ "$program_hl" = "qcore" ]; then
         mult=1
      fi
      echo mult: $mult 
      name="$(awk '{if(NR==2) print $1}' tmp_frag$j.log)"
###
      chargen=$(echo $charge | sed 's/-/m/')
      sqlnamep=${name}.q${chargen}.m${mult}
      nisql="$(sqlite3 $dir/inputs.db "select name from gaussian where name like '%$sqlnamep%'")"
      ni="$(echo "$nisql" | awk 'BEGIN{FS="-"};{name=$1;n=$2};END{print n+1}')"

      nn=${name}.q${chargen}.m${mult}-$ni
      echo $nn >> ffchmu
      ((tnf=tnf+1))
      awk '{if(NF==4) print $0}' tmp_frag$j.xyz >tmp_geom
      compare_frags.sh tmp_geom frag${tnf}_$nn $working
      nl=$(awk 'END{print NF}' $working/fraglist)
      ((m=m+1))
      calc=1
      if [ -f ${dir}/${nn}.log ]; then
         if [ $(awk 'BEGIN{c=0};/Job /{c=1};/ZPE/{c=1};END{print c}' ${dir}/${nn}.log) -eq 1 ]; then calc=0 ; fi
      fi
##calc only if the frag is not repeated and/or the calc is not completed
      if [ $nl -eq 2 ] && [ $calc -eq 1 ]; then
         nnc=${name}_q${chargen}_m${mult}_$ni
         chkfile=$nnc
         if [ "$program_hl" = "g09" ] || [ "$program_hl" = "g16" ]; then
            calc=min
         elif [ "$program_hl" = "qcore" ]; then
            calc=prod
         fi
         level=hl
         geo="$(awk '{if(NF==4) print $0};END{print ""}' tmp_frag$j.xyz)"
         if [ "$program_hl" = "g16" ]; then
            g09_input
         else
            ${program_hl}_input
         fi
      else
         inp_hl="$(echo salir)"
      fi
      echo -e "insert into gaussian values (NULL,'$nn','$inp_hl');\n.quit" | sqlite3 ${dir}/inputs.db
   done
####
#Make PRlist_frag file
   dumm=$(awk '{f[NR]=$1}
   END{
   i=1
   while(i<=NR){
     if(i<NR) printf "%s + ",f[i]
     if(i==NR) printf "%s",f[i]
     i++
     }
   print ""
   }' ffchmu)
   echo "${line[$number]}" "$dumm" >> $tsdirhl/PRODs/PRlist_frag
####
done
#submit the calcs
echo Performing a total of $m opt calculations
if [ $m -gt 0 ]; then
   doparallel "runTS.sh {1} $dir $program_hl" "$(seq $m)"
fi


