#!/bin/bash
source utils.sh

if [ -f amk.dat ];then
   echo "amk.dat is in the current dir"
   inputfile=amk.dat
else
   echo "amk input file is missing. You sure you are in the right folder?"
   exit
fi
exe="simplifyRXN.sh"
cwd=$PWD

#reading input
read_input
###

# ptgr is the percent of the total number of processes to be considered a relevant path
if [ $1 -eq 0 ]; then
   tsdir=${tsdirll}
   database=tss
else
   tsdir=${tsdirhl}
   database=tsshl
fi
lastmin=$(awk '{lm=$2};END{print lm}' $tsdir/MINs/SORTED/MINlist_sorted )
#
post=$( awk '{if ($1=="Temperature") print "T";if($1=="Energy") print "E" }' $inputfile )
value=$(awk '{if($1=="Energy") print $2};{if($1=="Temperature") print $2}' $inputfile)
if [ ! -f $tsdir/KMC/kmc$post$value.out ] || [ ! -f $tsdir/KMC/processinformation ]; then
   echo "You should run rxn_network2.sh first"
   exit
fi
suma=$(awk 'BEGIN{nn=1e20};/counts per process/{nn=NR};{if(NR>nn) suma+=$2};END{print suma}' $tsdir/KMC/kmc$post$value.out )
if [ $suma -eq 0 ]; then
   echo "Not even one process. Please, increase the simulation time"
   exit	
fi
awk 'BEGIN{nn=1e20};/counts per process/{nn=NR};{if(NR>nn)print $0}' $tsdir/KMC/kmc$post$value.out >tmp0
cat $tsdir/KMC/processinformation >>tmp0
sort -k 2nr tmp0 >tmp

echo "Threshold to get rid of paths (%)" $ptgr

awk '{if(NF==2) {++npr; pr[npr]=$1; npc[npr]=$2} }
{if(NF==6) ts[$2]=$4}
END{for(i=1;i<=npr;i++) tot+=npc[i]
for(i=1;i<=npr;i++) {
  p=npc[i]/tot*100
  if(p>'$ptgr') print ts[pr[i]]
  }
}' tmp | awk '{p=1;n[NR]=$1
for(i=1;i<NR;i++) {if($1==n[i]) p=0}
if(p==1) print n[NR]
}' > tmp_grothzts

cat $tsdir/KMC/RXNet_long.cg_groupedprods tmp_grothzts | awk 'NR<=2{print $0} 
{if($1=="TS") {ts=$2;line[ts]=$0}}
{if(NF==1) {++npath
    if(npath<=100) print line[$1]
    }
}' > tmp2 
#Once relevant file has been limited to the most important 100 rxns, make sure those 100 rxns are connected:
minn0=$(awk '/min0/{print $2}' ${tsdir}/MINs/SORTED/MINlist_sorted)
minn=$(awk 'BEGIN{minn='$minn0'};/ '$minn0' /{minn=$1};END{print minn}' ${tsdir}/working/conf_isomer.out)
linked_paths.py tmp2 $minn 1e10  > $tsdir/KMC/RXNet.relevant


